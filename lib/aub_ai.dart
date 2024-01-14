import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

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

ffi.Pointer<ffi.Int8> allocateCharArray(int length) {
  return calloc<ffi.Int8>(length);
}

ffi.Pointer<llama_token> allocateCIntList(int length) {
  return calloc<llama_token>(length);
}

int getStringLength(Pointer<Char> buffer) {
  int length = 0;
  while (buffer.elementAt(length).value != 0) {
    length++;
  }
  return length;
}

ffi.Pointer<ffi.Int32> truncateMemory(
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

ffi.Pointer<ffi.Int32> allocateIntArray(List<int> list) {
  final pointer = calloc<ffi.Int32>(list.length);

  for (int i = 0; i < list.length; i++) {
    pointer[i] = list[i];
  }
  return pointer;
}

Pointer<llama_context>? llamaCtxPtr;

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

  final Pointer<Char> modelPath = filePathToModel.toNativeUtf8().cast<Char>();
  final llama_model_params llamaModelParams =
      llamaCpp.llama_model_default_params();
  final Pointer<llama_model> llamaModel = llamaCpp.llama_load_model_from_file(
    modelPath,
    llamaModelParams,
  );

  final String promptTemplateToProcess = promptTemplate.template;
  debugPrint("[AUB.AI] promptTemplateToProcess: $promptTemplateToProcess");

  // LLaMa context parameters. These are configurable parameters that can be
  // used to control the behaviour of the AI model.
  final llama_context_params llamaCtxDefaultParams =
      llamaCpp.llama_context_default_params();
  final Pointer<llama_context_params> llamaCtxParamsPtr =
      calloc<llama_context_params>();
  llamaCtxParamsPtr.ref = llamaCtxDefaultParams;

  // Override the default parameters with the parameters from the prompt template.
  llamaCtxParamsPtr.ref.n_ctx =
      promptTemplate.contextSize ?? llamaCtxDefaultParams.n_ctx;
  llamaCtxParamsPtr.ref.seed =
      promptTemplate.randomSeedNumber ?? llamaCtxDefaultParams.seed;
  llamaCtxParamsPtr.ref.n_threads_batch =
      promptTemplate.cpuThreadsToUse ?? Platform.numberOfProcessors;

  // Dart gives us the number of total threads which is what we want.
  // For example, on a Apple MBP with M1 Pro, this will return 10 cores that
  // will be utilized by llama.cpp. At the time of writing, the default value
  // of n_threads that llama.cpp defaults to is 4.
  llamaCtxParamsPtr.ref.n_threads =
      promptTemplate.cpuThreadsToUse ?? Platform.numberOfProcessors;

  debugPrint(
      "[AUB.AI] Updated n_ctx from: ${llamaCtxDefaultParams.n_ctx} (default) -> ${llamaCtxParamsPtr.ref.n_ctx} (new)");
  debugPrint(
      "[AUB.AI] Updated seed from: ${llamaCtxDefaultParams.seed} (default) -> ${llamaCtxParamsPtr.ref.seed} (new)");
  debugPrint(
      "[AUB.AI] Updated n_threads from: ${llamaCtxDefaultParams.n_threads} (default) -> ${llamaCtxParamsPtr.ref.n_threads} (new)");

  llamaCtxPtr ??=
      llamaCpp.llama_new_context_with_model(llamaModel, llamaCtxParamsPtr.ref);
  debugPrint('[AUB.AI] llama_new_context_with_model(...)');

  // Here we're creating a list of length 4 and putting the items of tmp in it.
  final List<int> tmp = [0, 1, 2, 3];
  final Pointer<Int32> tmpPointer = allocateIntArray(tmp); //correct

  llamaCpp.llama_eval(llamaCtxPtr!, tmpPointer, tmp.length, 0);
  llamaCpp.llama_add_eos_token(llamaModel);

  int nPast = 0;

  Pointer<Int32> tokens =
      calloc<llama_token>(promptTemplateToProcess.length + 1);

  final int nMaxTokens = promptTemplateToProcess.length + 1;
  final Pointer<Char> prompt =
      promptTemplateToProcess.toNativeUtf8() as Pointer<Char>;

  debugPrint('[AUB.AI] llama_tokenize');
  final int nOfTok = llamaCpp.llama_tokenize(
    llamaModel,
    prompt,
    promptTemplateToProcess.length,
    tokens,
    nMaxTokens,
    true,
    true,
  );

  tokens = truncateMemory(tokens, nOfTok, nOfTok);
  final nCtx = llamaCpp.llama_n_ctx(llamaCtxPtr!);

  int nPredict = llamaCtxParamsPtr.ref.n_ctx;
  nPredict = min(nPredict, nCtx - nOfTok);

  int inputConsumed = 0;
  bool inputNoecho = false;
  int remainingTokens = nPredict;

  // The list of tokens to be fed to the model
  final embd = <int>[];
  const lastNSize = 64;
  List<int> lastNTokensData = List.generate(lastNSize, (index) => 0);

  // The batch size, i.e. the number of tokens to be fed to the model at once
  const nBatch = 32;
  const lastNRepeat = 64;
  const repeatPenalty = 1.0;
  const frequencyPenalty = 0.0;
  const presencePenalty = 0.0;

  // This is used to end the conversation when a new end of string token is
  // generated by the AI model.
  final String? eosToken = promptTemplate.eosToken;

  // Count the amount of end of string tokens in the prompt.
  int eosCount = 0;
  if (eosToken != null) {
    eosCount = promptTemplateToProcess.split(eosToken).length - 1;
    debugPrint(
      '[AUB.AI] Amount of EOS tokens in prompt: $eosCount. EOS token: $eosToken.',
    );
  }

  // The conversation that is generated by the AI model.
  // This is the existing prompt (conversation) + the response generated by the AI model.
  String conversation = '';

  // This is used to end the conversation when a new end of string token is
  // generated by the AI model.
  bool isConversationEnded = false;

  while (remainingTokens > 0 && !isConversationEnded) {
    // Check if the AI model has generated a new end of string token.
    // If so, we end the conversation.
    if (eosToken != null) {
      final int amountOfEosTokensInConversation =
          conversation.split(eosToken).length - 1;
      if (amountOfEosTokensInConversation > eosCount) {
        // The AI model has generated a new end of string token, so we
        // end the conversation.
        isConversationEnded = true;
        debugPrint(
          '[AUB.AI] AI model has generated a new end of string token, so we end the conversation.',
        );
      }
    }

    if (embd.isNotEmpty) {
      final Pointer<Int32> embdPointer = allocateIntArray(embd);
      llamaCpp.llama_eval(llamaCtxPtr!, embdPointer, embd.length, nPast);
      calloc.free(embdPointer); // Freeing the pointer after using it
    }

    nPast += embd.length;
    embd.clear();

    if (nOfTok <= inputConsumed) {
      final Pointer<Float> logits = llamaCpp.llama_get_logits(llamaCtxPtr!);
      final int nVocab = llamaCpp.llama_n_vocab(llamaModel);
      final Pointer<llama_token_data> arr = calloc<llama_token_data>(nVocab);

      for (int tokenId = 0; tokenId < nVocab; tokenId++) {
        arr[tokenId].id = tokenId;
        arr[tokenId].logit = logits[tokenId];
        arr[tokenId].p = 0.0;
      }

      final candidatesP = calloc<llama_token_data_array>();
      candidatesP.ref.data = arr;
      candidatesP.ref.size = nVocab;
      candidatesP.ref.sorted = false;

      final allocatedArray = allocateIntArray(lastNTokensData);
      llamaCpp.llama_sample_repetition_penalties(
        llamaCtxPtr!,
        candidatesP,
        allocatedArray,
        lastNRepeat,
        repeatPenalty,
        frequencyPenalty,
        presencePenalty,
      );

      llamaCpp.llama_sample_top_k(llamaCtxPtr!, candidatesP, 40, 1);
      llamaCpp.llama_sample_top_p(llamaCtxPtr!, candidatesP, 0.8, 1);
      llamaCpp.llama_sample_temperature(
        llamaCtxPtr!,
        candidatesP,
        promptTemplate.temperature ?? 0.4,
      );
      final int id = llamaCpp.llama_sample_token(llamaCtxPtr!, candidatesP);

      lastNTokensData = [...lastNTokensData.sublist(1), id];

      embd.add(id);
      inputNoecho = false;
      remainingTokens -= 1;
    } else {
      while (nOfTok > inputConsumed) {
        embd.add(tokens[inputConsumed]);

        lastNTokensData.removeAt(0);
        lastNTokensData.add(tokens[inputConsumed]);
        inputConsumed++;
        if (embd.length >= nBatch) {
          break;
        }
      }
    }

    if (!inputNoecho) {
      for (final id in embd) {
        const int size = 32;
        final Pointer<Char> buffer = calloc<Char>(size);

        final int n = llamaCpp.llama_token_to_piece(
          llamaModel,
          id,
          buffer,
          size,
        );

        final ByteBuffer byteBuffer =
            buffer.cast<Uint8>().asTypedList(n).buffer;
        final Uint8List list = byteBuffer.asUint8List();

        try {
          final String decodedToken = utf8.decode(
            list,
            allowMalformed: false,
          );

          // Keep track of the conversation that is generated by the AI model.
          conversation += decodedToken;

          // Send the last token of the response back to the main isolate.
          yield decodedToken;
        } catch (_) {
          debugPrint("[AUB.AI]: Error decoding token: $id");
        }

        if (n <= size) {
          final truncated = calloc<ffi.Char>(n);
          final length = getStringLength(buffer);
          for (int i = 0; i < n && i < length + 1; i++) {
            truncated[i] = buffer[i];
          }
          calloc.free(buffer);
        }
      }
    }

    // Conditions to break out of the loop and end the conversation.
    if (embd.isNotEmpty && embd.last == llamaCpp.llama_token_eos(llamaModel)) {
      break;
    }
  }

  // Freeing the pointers after using them
  // llamaCpp.llama_free(llamaCtxPtr);

  // AI has finished generating the response, so we return this
  // special string to indicate that to the completer.
  yield _eosBrutalCodingHasSpoken;
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
