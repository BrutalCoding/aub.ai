import 'dart:async';
import 'dart:convert' show utf8;
import 'dart:ffi' as ffi;
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';

import 'package:aub_ai/prompt_template.dart';
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
  final llama_model_params lparams = llamaCpp.llama_model_default_params();
  final llama_context_params cparams = llamaCpp.llama_context_default_params();

  debugPrint("[AubAi] AI model file path loading from: $filePathToModel");

  // Check if the file exists
  final File file = File(filePathToModel);
  if (!file.existsSync()) {
    throw Exception('File does not exist: $filePathToModel');
  }

  final Pointer<Char> modelPath = filePathToModel.toNativeUtf8().cast<Char>();

  final Pointer<llama_model> model = llamaCpp.llama_load_model_from_file(
    modelPath,
    lparams,
  );

  // If promptTemplate is ChatML, we replace the prompt with the user's input.
  String promptToProcess = promptTemplate.promptTemplate;
  if (promptTemplate.runtimeType == PromptTemplate.chatML().runtimeType) {
    promptToProcess = promptToProcess
        .replaceAll('{prompt}', promptTemplate.prompt)
        .replaceAll(
          '{systemMessage}',
          promptTemplate.systemMessage,
        );
  }

  final Pointer<Char> prompt = promptToProcess.toNativeUtf8() as Pointer<Char>;

  final Pointer<llama_context> ctx =
      llamaCpp.llama_new_context_with_model(model, cparams);
  debugPrint('[AubAi] llama_new_context_with_model(model, cparams)');

  // Set seed to 0 to disable randomization
  llamaCpp.llama_set_rng_seed(ctx, 50);

  // Here we're creating a list of length 4 and putting the items of tmp in it.
  final List<int> tmp = [0, 1, 2, 3];
  final Pointer<Int32> tmpPointer = allocateIntArray(tmp); //correct
  debugPrint('[AubAi] allocateIntArray(tmp)');
  llamaCpp.llama_eval(ctx, tmpPointer, tmp.length, 0);

  debugPrint('[AubAi] llama_add_bos_token(model) (1/2)');
  llamaCpp.llama_add_eos_token(model);
  debugPrint('[AubAi] llama_add_eos_token(model) (2/2)');

  int nPast = 0;

  Pointer<Int32> embdInp = calloc<llama_token>(promptToProcess.length + 1);
  final int nMaxTokens = promptToProcess.length + 1;

  debugPrint('[AubAi] llama_tokenize');

  final nOfTok = llamaCpp.llama_tokenize(
    model,
    prompt,
    promptToProcess.length,
    embdInp,
    nMaxTokens,
    true,
    true,
  );

  embdInp = truncateMemory(embdInp, nOfTok, nOfTok);
  final nCtx = llamaCpp.llama_n_ctx(ctx);

  int nPredict = promptTemplate.contextSize;
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

  // Keep track of the whole convo and end once
  // the end of string token has been detected.
  String aiCompleteOutput = "";
  bool aiStartEosDetected = false;
  bool aiStopEosDetected = false;

  while (remainingTokens > 0) {
    if (embd.isNotEmpty) {
      final embdPointer = allocateIntArray(embd);

      llamaCpp.llama_eval(ctx, embdPointer, embd.length, nPast);

      calloc.free(embdPointer); // Freeing the pointer after using it
    }

    nPast += embd.length;
    embd.clear();

    if (nOfTok <= inputConsumed) {
      final logits = llamaCpp.llama_get_logits(ctx);
      final nVocab = llamaCpp.llama_n_vocab(model);
      final arr = calloc<llama_token_data>(nVocab);

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
        ctx,
        candidatesP,
        allocatedArray,
        lastNRepeat,
        repeatPenalty,
        frequencyPenalty,
        presencePenalty,
      );

      llamaCpp.llama_sample_top_k(ctx, candidatesP, 40, 1);
      llamaCpp.llama_sample_top_p(ctx, candidatesP, 0.8, 1);
      llamaCpp.llama_sample_temperature(ctx, candidatesP, 0.4);
      final id = llamaCpp.llama_sample_token(ctx, candidatesP);

      lastNTokensData = [...lastNTokensData.sublist(1), id];

      embd.add(id);
      inputNoecho = false;
      remainingTokens -= 1;
    } else {
      while (nOfTok > inputConsumed) {
        embd.add(embdInp[inputConsumed]);

        lastNTokensData.removeAt(0);
        lastNTokensData.add(embdInp[inputConsumed]);
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

        final n = llamaCpp.llama_token_to_piece(
          model,
          id,
          buffer,
          size,
        );

        final ByteBuffer byteBuffer =
            buffer.cast<Uint8>().asTypedList(n).buffer;
        final Uint8List list = byteBuffer.asUint8List();

        try {
          final decodedToken = utf8.decode(
            list,
            allowMalformed: false,
          );
          aiCompleteOutput += decodedToken;

          // Send the last token of the response back to the main isolate.
          yield decodedToken;
        } catch (_) {
          debugPrint("[AubAi]: Error decoding token: $id");
        }

        if (n <= size) {
          final truncated = calloc<ffi.Char>(n);
          final length = getStringLength(buffer);
          for (int i = 0; i < n && i < length + 1; i++) {
            truncated[i] = buffer[i];
          }
          calloc.free(buffer);

          // Detect if AI has mentioned the start tag.
          const String startTag = "<|im_start|>assistant";
          const String endTag = "<|im_end|>";
          aiStartEosDetected = aiCompleteOutput.contains(startTag);

          if (aiStartEosDetected == true && aiStopEosDetected == false) {
            final String aiOutput = aiCompleteOutput.split(startTag).last;
            aiStopEosDetected = aiOutput.contains(endTag);
          }
        }
      }
    }

    // Conditions to break out of the loop and end the conversation.
    if (embd.isNotEmpty && embd.last == llamaCpp.llama_token_eos(model)) {
      break;
    } else if (aiStopEosDetected) {
      aiCompleteOutput = '';
      debugPrint("[AubAi]: End of AI response detected.");
      break;
    }
  }

  // Freeing the pointers after using them
  llamaCpp.llama_free(ctx);

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

  // Darwin (macOS and iOS)
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('lib$libName.dylib');
  }

  // Android and Linux
  if (Platform.isAndroid || Platform.isLinux) {
    final soLoaded = DynamicLibrary.open('lib$libName.so');
    return soLoaded;
  }

  // Windows
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
get aubAiBindings => _bindings;

/// This class is the input that will be processed by the AI model.
/// Basically the prompt that the user wants to generate a response from.
/// See [_PromptBatchOutput] for the output of the AI model.
class _PromptBatchInput {
  final int id;
  final String filePathToModel;
  final PromptTemplate promptTemplate;
  // final dynamic onTokenGenerated;

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
