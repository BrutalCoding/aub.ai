import 'dart:io';

import 'package:aub_ai/aub_ai.dart';
import 'package:aub_ai/data/prompt_template.dart';
import 'package:aub_ai/services/tts_service.dart';
import 'package:chat_bubbles/chat_bubbles.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

enum TalkAsyncState {
  idle,
  thinking,
  talking,
}

class _MyAppState extends State<MyApp> {
  /// This text controller is used combined with the PromptTemplate to send
  /// the prompt to the AI.
  final TextEditingController textControllerUserPrompt =
      TextEditingController();
  final TextEditingController textControllerFullConversation =
      TextEditingController();

  /// This text is used to show the response from the AI in the UI.
  TalkAsyncState talkAsyncState = TalkAsyncState.idle;

  /// This file is used to store the path to the gguf model file (.gguf) (serves LLM)
  File? fileTextModel;

  /// Define ChatML as the default prompt template
  PromptTemplate promptTemplate = PromptTemplate.chatML();

  // This is the example system message that is used in the ChatML template.
  final String _chatMLTemplateSysExample =
      "You are a helpful assistant. Be concise and helpful. If you don't know the answer to a question, please don't share false information.";
  @override
  void initState() {
    super.initState();
    TtsService.initTts();
  }

  @override
  Widget build(BuildContext context) {
    List<String> convoParts = textControllerFullConversation.text
        .split('<|im_start|>')
        .where(
          (element) => element.isNotEmpty,
        )
        .toList();
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        useMaterial3: true,
      ),
      home: Scaffold(
        appBar: AppBar(
          actions: [
            IconButton(
              onPressed:
                  talkAsyncState == TalkAsyncState.idle && fileTextModel != null
                      ? () {
                          setState(
                            () {
                              fileTextModel = null;
                              textControllerUserPrompt.clear();
                              textControllerFullConversation.clear();
                              talkAsyncState = TalkAsyncState.idle;
                            },
                          );
                        }
                      : null,
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Reset the conversation, pick a new model file',
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 960,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  const Column(
                    children: [
                      CircleAvatar(
                        minRadius: 32,
                        maxRadius: 64,
                        backgroundImage: AssetImage(
                          'assets/appicon_avatar.png',
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Daniel Breedeveld',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Ask me anything!',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Expanded(
                    flex: 2,
                    child: convoParts.length > 1
                        ? ListView.builder(
                            keyboardDismissBehavior:
                                ScrollViewKeyboardDismissBehavior.onDrag,
                            shrinkWrap: true,
                            padding: const EdgeInsets.all(8),
                            itemCount: convoParts.length,
                            itemBuilder: (context, index) {
                              final String text = convoParts
                                  .elementAt(index)
                                  .replaceAll('<|im_end|>', '')
                                  .trim();

                              return Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: BubbleSpecialThree(
                                  text: text,
                                  color: text.startsWith('user')
                                      ? const Color(0xFF1B97F3)
                                      : const Color(0xFFE8E8EE),
                                  tail: true,
                                  textStyle: TextStyle(
                                    color: text.startsWith('user')
                                        ? Colors.white
                                        : Colors.black,
                                    fontSize: 14,
                                  ),
                                  isSender: text.startsWith('user'),
                                ),
                              );
                            },
                          )
                        : Center(
                            child: fileTextModel != null
                                ? const Text(
                                    'Start a conversation by sending a prompt to the AI',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w100,
                                    ),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.all(8.0),
                                        child: Text(
                                          'Please provide a GGUF file to start a conversation.',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      // Description of what this file is about.
                                      // This is the file that contains the knowledge of the AI.
                                      // Text widget:
                                      const Text(
                                        'This app is tailored for GGUF models in the ChatML format.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                      // Button to select a GGUF file
                                      Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Opacity(
                                          opacity:
                                              fileTextModel == null ? 1 : 0.5,
                                          child: ElevatedButton(
                                            onLongPress: () {
                                              // Clear fileTextModel
                                              setState(() {
                                                fileTextModel = null;
                                              });
                                            },
                                            onPressed: fileTextModel == null
                                                ? () async {
                                                    FilePickerResult? result =
                                                        await FilePicker
                                                            .platform
                                                            .pickFiles();

                                                    if (result == null) {
                                                      return;
                                                    }

                                                    final tmpFile = File(result
                                                        .files.single.path!);
                                                    setState(() {
                                                      fileTextModel = tmpFile;
                                                    });
                                                  }
                                                : null,
                                            child: const Text(
                                              'Pick text model (.gguf)',
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  )),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: textControllerUserPrompt,
                            textCapitalization: TextCapitalization.sentences,
                            onSubmitted: (_) => _sendPromptToAi(
                              textControllerUserPrompt.text,
                            ),
                            enabled: fileTextModel != null &&
                                talkAsyncState == TalkAsyncState.idle,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),

                              // Display a hint text when the conversation has not started yet.
                              hintText: 'Write something...',
                            ),
                          ),
                        ),
                        Flexible(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Stack(
                              children: [
                                Tooltip(
                                  // When the AI is busy, the tooltip will
                                  // show the reason why the button is disabled
                                  waitDuration: const Duration(seconds: 1),
                                  message: talkAsyncState ==
                                              TalkAsyncState.thinking ||
                                          talkAsyncState ==
                                              TalkAsyncState.talking
                                      ? 'The AI is busy, please wait...'
                                      : 'Send this prompt to the AI in order to get a response',
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(
                                          Radius.circular(8),
                                        ),
                                      ),
                                      minimumSize: const Size(0, 64),
                                    ),
                                    onPressed: fileTextModel != null &&
                                            talkAsyncState ==
                                                TalkAsyncState.idle
                                        ? () => _sendPromptToAi(
                                              textControllerUserPrompt.text,
                                            )
                                        : null,
                                    icon: const Icon(Icons.send),
                                    label: const Text('Send'),
                                  ),
                                ),

                                // Show a progress indicator when the AI is thinking
                                if (talkAsyncState == TalkAsyncState.thinking ||
                                    talkAsyncState == TalkAsyncState.talking)
                                  const Positioned.fill(
                                    child: Align(
                                      alignment: Alignment.bottomCenter,
                                      child: Padding(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: 4,
                                        ),
                                        child: LinearProgressIndicator(
                                          borderRadius: BorderRadius.all(
                                            Radius.circular(16),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// This function sends the prompt to the AI. It is called when the user
  /// presses the send button or when the user presses enter on the keyboard.
  Future<void> _sendPromptToAi(String userPrompt) async {
    if (fileTextModel == null || userPrompt.isEmpty) {
      return;
    }

    // Create a temporary prompt template because we're going to modify it
    // based on whether it's an ongoing conversation or not.
    PromptTemplate? tmpPromptTemplate;
    final bool isOngoingConvo = textControllerFullConversation.text
        .replaceAll(userPrompt, '')
        .isNotEmpty;

    if (isOngoingConvo) {
      // If it's an ongoing conversation, we need to keep the previous
      // conversation in the prompt template and append the user prompt
      // to the end of the prompt template in it's expected format (ChatML in this case).
      tmpPromptTemplate = PromptTemplate(
        label: 'ChatML',
        template:
            "${textControllerFullConversation.text}<|im_start|>user\n${textControllerUserPrompt.text}<|im_end|>\n<|im_start|>assistant",
        eosToken: "<|im_end|>",
      );
    } else {
      // If it's not an ongoing conversation, we can use the default prompt template.
      // We need to replace the {systemMessage} and {prompt} placeholders, these
      // values can be found by looking at the ChatML template source code.
      tmpPromptTemplate = promptTemplate.copyWith(
        template: promptTemplate.template
            .replaceAll(
              '{systemMessage}',
              _chatMLTemplateSysExample,
            )
            .replaceAll(
              '{prompt}',
              userPrompt,
            ),
      );
    }

    // Start the AI
    setState(() {
      talkAsyncState = TalkAsyncState.thinking;
    });

    // A temporary variable to store the generated tokens.
    String tmpGeneratedTokensAll = '';
    String tmpGeneratedTokensLastResponse = '';

    await talkAsync(
      filePathToModel: fileTextModel!.path,
      promptTemplate: tmpPromptTemplate,
      onTokenGenerated: (String token) {
        tmpGeneratedTokensAll += token;
        if (tmpGeneratedTokensAll.length >
            textControllerFullConversation.text.length) {
          tmpGeneratedTokensLastResponse += token;
          if (talkAsyncState != TalkAsyncState.talking) {
            setState(() {
              talkAsyncState = TalkAsyncState.talking;
            });
          }

          setState(() {
            textControllerFullConversation.text += token;
          });
        }
      },
    );

    textControllerUserPrompt.clear();
    textControllerFullConversation.text =
        textControllerFullConversation.text.trimLeft();

    // To play the last response, we need to remove both the start and end tags
    // from the last response before to play it using the TTS service.
    final String lastChatMessageByAssistant = tmpGeneratedTokensLastResponse
        .split('<|im_start|>assistant')
        .last
        .replaceAll(
          '<|im_end|>',
          '',
        );

    // Play the last response using the TTS service
    aubTextToSpeech(text: lastChatMessageByAssistant);

    // Change the state back to idle when the AI is done talking
    setState(() {
      talkAsyncState = TalkAsyncState.idle;
    });
  }
}
