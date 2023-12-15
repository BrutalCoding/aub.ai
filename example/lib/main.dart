import 'dart:io';

import 'package:aub_ai/aub_ai.dart';
import 'package:aub_ai/data/prompt_template.dart';
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

  /// This file is used to store the path to the model file.
  File? file;

  /// Define ChatML as the default prompt template
  PromptTemplate promptTemplate = PromptTemplate.chatML();

  // This is the example system message that is used in the ChatML template.
  final String _chatMLTemplateSysExample =
      "You are a helpful assistant. Be concise and helpful. If you don't know the answer to a question, please don't share false information.";

  @override
  Widget build(BuildContext context) {
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
              onPressed: talkAsyncState == TalkAsyncState.idle && file != null
                  ? () {
                      setState(
                        () {
                          file = null;
                          textControllerUserPrompt.clear();
                          textControllerFullConversation.clear();
                          talkAsyncState = TalkAsyncState.idle;
                        },
                      );
                    }
                  : null,
              icon: const Icon(Icons.restore_sharp),
              tooltip: 'Start over',
            ),
          ],
        ),
        body: SafeArea(
          child: Center(
            child: Container(
              constraints: const BoxConstraints(
                maxWidth: 960,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    const CircleAvatar(
                      minRadius: 64,
                      maxRadius: 128,
                      backgroundImage: AssetImage(
                        'assets/appicon_avatar.png',
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Daniel Breedeveld',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ask me anything!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (file == null)
                      // Ask user to select a file
                      Column(
                        children: [
                          const Padding(
                            padding: EdgeInsets.all(8.0),
                            child: Text(
                              'In order to start, please select a model file from your device',
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
                            'This file is what contains the knowledge of the AI',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          // Button to select a file
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: ElevatedButton(
                              onPressed: () async {
                                FilePickerResult? result =
                                    await FilePicker.platform.pickFiles();

                                if (result == null) {
                                  return;
                                }

                                final tmpFile = File(result.files.single.path!);
                                setState(() {
                                  file = tmpFile;
                                });
                              },
                              child: const Text('Pick a file'),
                            ),
                          ),
                        ],
                      ),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Center(
                                child: Column(
                              children: [
                                // Show output from AI in a TextField
                                if (talkAsyncState == TalkAsyncState.talking ||
                                    textControllerFullConversation
                                        .text.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller:
                                          textControllerFullConversation,
                                      maxLines: 10,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                                if (talkAsyncState == TalkAsyncState.thinking &&
                                    textControllerFullConversation.text.isEmpty)
                                  const Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        // Prompt that was sent to the AI
                                        Text(
                                          "Thinking...",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        SizedBox(height: 32),
                                        CircularProgressIndicator.adaptive(),
                                      ],
                                    ),
                                  ),
                              ],
                            )),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Expanded(
                                    child: TextField(
                                      controller: textControllerUserPrompt,
                                      textCapitalization:
                                          TextCapitalization.sentences,
                                      onSubmitted: (_) => _sendPromptToAi(
                                        textControllerUserPrompt.text,
                                      ),
                                      enabled: file != null &&
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
                                            waitDuration:
                                                const Duration(seconds: 1),
                                            message: talkAsyncState ==
                                                        TalkAsyncState
                                                            .thinking ||
                                                    talkAsyncState ==
                                                        TalkAsyncState.talking
                                                ? 'The AI is busy, please wait...'
                                                : 'Send this prompt to the AI in order to get a response',
                                            child: ElevatedButton.icon(
                                              style: ElevatedButton.styleFrom(
                                                shape:
                                                    const RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.all(
                                                    Radius.circular(8),
                                                  ),
                                                ),
                                                minimumSize: const Size(0, 64),
                                              ),
                                              onPressed: file != null &&
                                                      talkAsyncState ==
                                                          TalkAsyncState.idle
                                                  ? () => _sendPromptToAi(
                                                        textControllerUserPrompt
                                                            .text,
                                                      )
                                                  : null,
                                              icon: const Icon(Icons.send),
                                              label: const Text('Send'),
                                            ),
                                          ),

                                          // Show a progress indicator when the AI is thinking
                                          if (talkAsyncState ==
                                                  TalkAsyncState.thinking ||
                                              talkAsyncState ==
                                                  TalkAsyncState.talking)
                                            const Positioned.fill(
                                              child: Align(
                                                alignment:
                                                    Alignment.bottomCenter,
                                                child: Padding(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal: 4,
                                                  ),
                                                  child:
                                                      LinearProgressIndicator(
                                                    borderRadius:
                                                        BorderRadius.all(
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
                  ],
                ),
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
    if (file == null || userPrompt.isEmpty) {
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
        contextSize: 4096,
        randomSeedNumber: 42,
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
    String tmpGeneratedToken = '';
    await talkAsync(
      filePathToModel: file!.path,
      promptTemplate: tmpPromptTemplate,
      onTokenGenerated: (String token) {
        tmpGeneratedToken += token;
        if (tmpGeneratedToken.length >
            textControllerFullConversation.text.length) {
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

    // Change the state back to idle when the AI is done talking
    setState(() {
      textControllerUserPrompt.clear();
      talkAsyncState = TalkAsyncState.idle;
    });
  }
}
