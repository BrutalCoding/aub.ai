import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' hide log;

import 'package:aub_ai/data/prompt_template.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';

import 'aub_ai_bindings_generated.dart';

/// A special string to indicate that the AI model has finished generating the
/// response. EOS stands for End Of String.
const String _eosBrutalCodingHasSpoken = 'BRUTALCODING_HAS_SPOKEN';

/// A custom callback type that is used to send the last token of the response
/// back to the main isolate so that the user can see that the AI model is still
/// generating the response (e.g. typing in real-time).
typedef OnTokenGeneratedCallback = void Function(String token);

ffi.Pointer<llama_token> _allocateCIntList(int length) {
  return calloc<llama_token>(length);
}

int _getStringLength(Pointer<Char> buffer) {
  int length = 0;
  while (buffer.elementAt(length).value != 0) {
    length++;
  }
  return length;
}

void _batchAdd(
    llama_batch batch, int id, int pos, List<int> seqIds, bool logits) {
  batch.token[batch.n_tokens] = id;
  batch.pos[batch.n_tokens] = pos;
  batch.n_seq_id[batch.n_tokens] = seqIds.length;
  for (int i = 0; i < seqIds.length; i++) {
    batch.seq_id[batch.n_tokens][i] = seqIds[i];
  }
  batch.logits[batch.n_tokens] = logits ? 1 : 0;
  batch.n_tokens += 1;
}

ffi.Pointer<ffi.Int32> _truncateMemory(
  ffi.Pointer<ffi.Int32> original,
  int originalLength,
  int nOfTok,
) {
  // Step 1: Allocate a new block of memory of size n_of_tok
  final truncated = calloc<ffi.Int32>(nOfTok);

  // Step 2: Copy data from the original pointer to the new pointer
  for (int i = 0; i < nOfTok && i < nOfTok; i++) {
    truncated[i] = original[i];
  }

  calloc.free(original);

  return truncated;
}

ffi.Pointer<ffi.Int32> _allocateIntArray(List<int> list) {
  final pointer = calloc<ffi.Int32>(list.length);

  for (int i = 0; i < list.length; i++) {
    pointer[i] = list[i];
  }
  return pointer;
}

/// Invoke the AI model to generate a response from given [instruction].
/// Returns the response as a [String].
///
/// [filePathToModel] path to the LLaMa model file. Note: It can have any extension,
/// as long as it is a valid LLaMa model file converted in the GGUF format.
/// Example: 'assets/shady_ai.gguf' or 'assets/shady_ai.bin' could both be valid.
Stream<String> _generateResponse({
  required String filePathToModel,

  /// The prompt to generate a response from.
  /// Here is an example of a prompt:
  ///
  /// Below is an instruction that describes a task. Write a response that
  /// appropriately completes the request.\n\n### Instruction:\nWhat is the
  /// meaning of life?\n\n### Response:
  required PromptTemplate promptTemplate,
}) async* {
  final AubAiBindings llamaCpp = aubAiBindings;

  // Check if the file exists
  debugPrint("[AUB.AI] AI model file path loading from: $filePathToModel");
  final File file = File(filePathToModel);
  if (!file.existsSync()) {
    throw Exception('File does not exist: $filePathToModel');
  }

  llamaCpp.llama_backend_init();

  // TODO: Figure out what numa strategy number to use, see common.h from llama.cpp repo.
  // I don't know what it does, except for the fact that it's related to
  // memory allocation and improves performance.
  const int numa =
      0; // GGML_NUMA_STRATEGY_DISABLED (0), see common.h as previously mentioned.
  llamaCpp.llama_numa_init(numa);

  final llama_model_params llamaModelParams =
      llamaCpp.llama_model_default_params();

  final Pointer<Char> modelPath = filePathToModel.toNativeUtf8().cast<Char>();

  final Pointer<llama_model> llamaModel = llamaCpp.llama_load_model_from_file(
    modelPath,
    llamaModelParams,
  );
  log('[AUB.AI] Model loaded from file: $filePathToModel');

  final llama_context_params llamaCtxDefaultParams =
      llamaCpp.llama_context_default_params();

  final Pointer<llama_context_params> llamaCtxParamsPtr =
      calloc<llama_context_params>();

  llamaCtxParamsPtr.ref = llamaCtxDefaultParams;

  // Tokenize the prompt
  Pointer<Int32> tokens = _allocateCIntList(promptTemplate.template.length + 1);
  final Pointer<Char> text =
      promptTemplate.template.toNativeUtf8().cast<Char>();
  llamaCpp.llama_tokenize(
    llamaModel,
    text,
    promptTemplate.template.length,
    tokens,
    promptTemplate.template.length + 1,
    false,
    false,
  );

  final Pointer<llama_context> llamaCtxPtr =
      llamaCpp.llama_new_context_with_model(
    llamaModel,
    llamaCtxParamsPtr.ref,
  );
  final int nCtx = llamaCpp.llama_n_ctx(llamaCtxPtr);

  // In C++: const int n_kv_req = tokens_list.size() + (n_len - tokens_list.size());
  // In Dart: final int nKvReq = tokens.length + (nCtx - tokens.length);
  final int tokensLength = promptTemplate.template.length + 1;
  final int nKvReq = tokensLength + (nCtx - tokensLength);

  // If nKvReq is greater than nCtx, then we throw this error:
  // error: n_kv_req > n_ctx, the required KV cache size is not big enough either reduce n_len or increase n_ctx
  if (nKvReq > nCtx) {
    throw Exception(
      'n_kv_req > n_ctx, the required KV cache size is not big enough either reduce n_len or increase n_ctx',
    );
  }

  // Create a llama_batch with size 512
  // We use this object to submit token data for decoding
  llama_batch batch = llamaCpp.llama_batch_init(512, 0, 1);

  // Add tokens to the batch
  final List<int> tokenList = _tokenize(
    promptTemplate.template,
    false,
    llamaModel,
    llamaCpp,
  );

  batch.n_tokens = 0;

  for (int i = 0; i < tokenList.length; i++) {
    log('[AUB.AI] Adding token to batch: ${tokenList[i]}');
    _batchAdd(batch, tokenList[i], i, [0], false);
  }

  log('[AUB.AI] Doing something with batch.logits...');
  batch.logits[batch.n_tokens - 1] = 1;

  // Decode the tokens
  log('[AUB.AI] Decoding tokens...');
  final decodedTokens = llamaCpp.llama_decode(llamaCtxPtr, batch);
  if (decodedTokens != 0) {
    log('[AUB.AI] Error during llama_decode(...).');
    throw Exception(
      "Unable to decode token batch, error during llama_decode(...).",
    );
  }

  // Convert token to string
  // final decodedTokensIntoString = llamaCpp.llama_token_to_piece(model, token, buf, length)
  final int decodedTokensIntoString = llamaCpp.llama_token_to_piece(
    llamaModel,
    batch.token[0],
    calloc<ffi.Char>(512),
    512,
  );

  log('[AUB.AI] Decoded tokens into string: $decodedTokensIntoString');

  // Use _tokenToPiece to convert the token to a string
  for (int i = 0; i < batch.n_tokens; i++) {
    final int token = batch.token[i];
    final String tokenPiece = _tokenToPiece(
      token,
      llamaCpp,
      llamaModel,
    );

    log('[AUB.AI] Token piece: $tokenPiece');
    yield tokenPiece;
  }

  // Return the n_tokens which indicates the number of tokens in the batch
  final int nTokens = batch.n_tokens;
  log('[AUB.AI] Number of tokens in batch: $nTokens');

  yield _eosBrutalCodingHasSpoken;

  // We yield back the tokens one by one, after
  // for (int i = 0; i < nTokens; i++) {
  //   final int token = batch.token[i];
  //   log('[AUB.AI] Yielding token: $token');
  //   yield token.toString();
  // }
}

/// Converts a text string to a list of token IDs.
///
/// This function tokenizes the given string into a sequence of integers representing tokens.
/// An optional flag 'addBos' indicates whether to prepend a beginning-of-sentence token.
/// The function handles memory allocation and conversion between Dart strings and native character arrays.
List<int> _tokenize(
  String text,
  bool addBos,
  Pointer<llama_model> model,
  AubAiBindings llamaCpp,
) {
  Pointer<Char> cchar = text.toNativeUtf8().cast<Char>();

  int nUtf8CodeUnits = utf8.encode(text).length;
  int nTokens = nUtf8CodeUnits + (addBos ? 1 : 0) + 1;

  Pointer<llama_token> tokens =
      malloc.allocate<llama_token>(nTokens * sizeOf<llama_token>());

  try {
    int tokenCount = llamaCpp.llama_tokenize(
        model, cchar, nUtf8CodeUnits, tokens, nTokens, addBos, false);

    List<int> tokensList = [];
    for (int i = 0; i < tokenCount; i++) {
      tokensList.add(tokens[i]);
    }

    return tokensList;
  } finally {
    malloc.free(tokens);
    malloc.free(cchar);
  }
}

/// Converts a token ID to its corresponding string representation.
///
/// This utility function takes a token ID and returns the associated text piece.
/// It handles the conversion and memory management involved in this process.
/// This is typically used in decoding the output of the model.
///
/// Note of BrutalCoding:
///   Credits to https://github.com/netdur/llama_cpp_dart (and obviously llama.cpp's examples)
///   for getting me on track with this function.
///   While I try to write my own code, or at least understand it,
///   I had to use the code from this repository to save time and solve a problem.
String _tokenToPiece(
    int token, AubAiBindings llamaCpp, Pointer<llama_model> model) {
  int bufferSize = 64;
  Pointer<Char> result = malloc.allocate<Char>(bufferSize);
  try {
    int bytesWritten =
        llamaCpp.llama_token_to_piece(model, token, result, bufferSize);

    bytesWritten = min(bytesWritten, bufferSize - 1);

    final byteBuffer = result.cast<Uint8>().asTypedList(bytesWritten);

    return utf8.decode(byteBuffer, allowMalformed: true);
  } finally {
    malloc.free(result);
  }
}

OnTokenGeneratedCallback? _onTokenGenerated;

/// This function is used to generate a response from the AI model.
/// It returns a [Future] that completes when the AI model has finished
/// generating the response.
///
/// [filePathToModel] path to the AI model file. Note: It can have any extension,
/// as long as it is a valid model file converted in the GGUF format.
///
/// [promptTemplate] the prompt to generate a response from.
///
/// [onTokenGenerated] a callback that is called when the AI model has generated
/// a token. This is useful for showing the user that the AI model is still
/// generating the response (e.g. typing in real-time).
Future<void> talkAsync({
  required String filePathToModel,
  required PromptTemplate promptTemplate,
  required OnTokenGeneratedCallback onTokenGenerated,
}) async {
  // This is used to send requests to the helper isolate.
  // By using isolates, we can run the AI model in a separate thread and thus
  // prevent the main isolate from blocking while the AI model is running.
  // Otherwise, the UI would freeze while the AI model is running.
  _onTokenGenerated = onTokenGenerated;
  final SendPort helperIsolateSendPort = await _helperIsolateSendPort;
  final int requestId = _nextPromptBatchRequestId++;
  final _PromptBatchInput request = _PromptBatchInput(
    requestId,
    filePathToModel,
    promptTemplate,
  );
  final Completer<void> completer = Completer<void>();

  // Completer that is a stream. We listen to the stream to get the last token
  // of the response.
  _promptBatchRequests[requestId] = completer;
  helperIsolateSendPort.send(request);
  return completer.future;
}

/// The dynamic library in which the symbols for [AubAiBindings] can be found.
final DynamicLibrary _dylib = () {
  /// [libName] is basically the base name of the compiled file name that
  /// contains the native functions. The file name is platform dependent.
  const String libName = 'llama';

  // macOS (x86_64, ARM64)
  if (Platform.isMacOS) {
    return DynamicLibrary.open('lib$libName.dylib');
  }

  // iOS (ARM64)
  if (Platform.isIOS) {
    return DynamicLibrary.process();
  }

  // Android (ARM64) and Linux (x86_64)
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('lib$libName.so');
  }

  // Windows (x86_64)
  if (Platform.isWindows) {
    return DynamicLibrary.open('$libName.dll');
  }

  // Unsupported platform
  throw UnsupportedError('Sorry, your platform/OS is not supported. '
      'You are running: ${Platform.operatingSystem}');
}();

/// The bindings to the native functions in [_dylib].
final AubAiBindings _bindings = AubAiBindings(_dylib);

// Expose _bindings publicly:
AubAiBindings get aubAiBindings => _bindings;

/// This class is the input that will be processed by the AI model.
/// Basically the prompt that the user wants to generate a response from.
/// See [_PromptBatchOutput] for the output of the AI model.
class _PromptBatchInput {
  final int id;
  final String filePathToModel;
  final PromptTemplate promptTemplate;

  const _PromptBatchInput(
    this.id,
    this.filePathToModel,
    this.promptTemplate,
  );
}

/// The output of the AI model based on the [_PromptBatchInput].
class _PromptBatchOutput {
  final int promptBatchId;
  final String token;

  const _PromptBatchOutput(
    this.promptBatchId,
    this.token,
  );
}

/// Counter to identify [_PromptBatchInput]s and [_PromptBatchOutput]s.
int _nextPromptBatchRequestId = 0;

/// Mapping from [_PromptBatchInput] `id`s to the completers corresponding to the correct future of the pending request.
final Map<int, Completer<void>> _promptBatchRequests = <int, Completer<void>>{};

/// The SendPort belonging to the helper isolate.
Future<SendPort> _helperIsolateSendPort = () async {
  // The helper isolate is going to send us back a SendPort, which we want to
  // wait for.
  final Completer<SendPort> completer = Completer<SendPort>();

  // Receive port on the main isolate to receive messages from the helper.
  // We receive two types of messages:
  // 1. A port to send messages on.
  // 2. Responses to requests we sent.
  final ReceivePort receivePort = ReceivePort()
    ..listen((dynamic data) {
      if (data is SendPort) {
        // The helper isolate sent us the port on which we can sent it requests.
        completer.complete(data);
        return;
      }
      if (data is _PromptBatchOutput) {
        // The helper isolate sent us a response to a request we sent.
        final Completer<void> completer =
            _promptBatchRequests[data.promptBatchId]!;

        // If the reply ends with the special string, then the AI model has
        // finished generating the response.
        if (data.token.endsWith(_eosBrutalCodingHasSpoken)) {
          debugPrint('AI has finished generating the response.');
          _promptBatchRequests.remove(data.promptBatchId);
          completer.complete();
          return;
        }

        // Otherwise, the AI model is still generating the response, so we
        // send the last token of the response back to the main isolate so that
        // the user can see that the AI model is still generating the response.
        if (_onTokenGenerated == null) {
          throw Exception('onTokenGeneratedGlobal is null');
        }

        // Send the last token of the response back to the main isolate.
        _onTokenGenerated!(data.token);

        return;
      }

      throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
    });

  // Start the helper isolate.
  await Isolate.spawn((SendPort sendPort) {
    final ReceivePort helperReceivePort = ReceivePort()
      ..listen((dynamic data) {
        // Send the last token of the response back to the main isolate so that
        // the user can see that the AI model is still generating the response.
        if (data is _PromptBatchInput) {
          _generateResponse(
            filePathToModel: data.filePathToModel,
            promptTemplate: data.promptTemplate,
          ).listen((String lastToken) {
            // Because we're using streams, we can't send the last token of the
            // response back to the main isolate directly. Instead, we send it
            // back in a _PromptBatchOutput object.
            final _PromptBatchOutput replyByAssistant = _PromptBatchOutput(
              data.id,
              lastToken,
            );

            // Send the _PromptBatchOutput back to the main isolate.
            sendPort.send(replyByAssistant);
          });

          return;
        }

        // We should never get here.
        throw UnsupportedError('Unsupported message type: ${data.runtimeType}');
      });

    // Send the port to the main isolate on which we can receive requests.
    sendPort.send(helperReceivePort.sendPort);
  }, receivePort.sendPort);

  // Wait until the helper isolate has sent us back the SendPort on which we
  // can start sending requests.
  return completer.future;
}();
