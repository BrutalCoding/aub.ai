import 'dart:io';

import 'package:aub_ai/aub_ai.dart';
import 'package:aub_ai/prompt_template.dart';
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

  /// This text is used to show the response from the AI in the UI.
  String responseFromAi = '';
  TalkAsyncState talkAsyncState = TalkAsyncState.idle;

  File? file;

  // Define ChatML as the default prompt template
  PromptTemplate promptTemplate = PromptTemplate.chatML().copyWith(
    contextSize: 2048,
  );

  /// Each PromptTemplate comes with a default prompt.
  /// While this prompt is not required, it can be used to get started.
  /// Good practice is to show the user the default prompt to give them an idea.
  late final String _promptTemplateDefaultPrompt;

  @override
  void initState() {
    super.initState();
    _promptTemplateDefaultPrompt = promptTemplate.prompt;
  }

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
                          responseFromAi = '';
                          promptTemplate = promptTemplate.copyWith(
                            prompt: '',
                          );
                          talkAsyncState = TalkAsyncState.idle;
                        },
                      );
                    }
                  : null,
              icon: const Icon(Icons.clear),
              tooltip: 'Reset',
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
                    Column(
                      children: [
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
                                  onSubmitted: (_) => _sendPromptToAi(),
                                  enabled: file != null &&
                                      talkAsyncState == TalkAsyncState.idle,
                                  decoration: InputDecoration(
                                    border: const OutlineInputBorder(),
                                    labelText:
                                        'Example: "$_promptTemplateDefaultPrompt"',
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
                                          onPressed: file != null &&
                                                  talkAsyncState ==
                                                      TalkAsyncState.idle
                                              ? () => _sendPromptToAi()
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
                                    responseFromAi.isNotEmpty) ...[
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: TextField(
                                      controller: TextEditingController(
                                        text: responseFromAi,
                                      ),
                                      maxLines: 20,
                                      readOnly: true,
                                      decoration: const InputDecoration(
                                        border: OutlineInputBorder(),
                                      ),
                                    ),
                                  ),
                                ],
                                if (talkAsyncState == TalkAsyncState.thinking &&
                                    responseFromAi.isEmpty)
                                  Center(
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      mainAxisSize: MainAxisSize.max,
                                      children: [
                                        // Prompt that was sent to the AI
                                        Text(
                                          '"${promptTemplate.prompt}"',
                                          textAlign: TextAlign.center,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        const Text(
                                          "Thinking...",
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(height: 32),
                                        const CircularProgressIndicator
                                            .adaptive(),
                                      ],
                                    ),
                                  ),
                              ],
                            )),
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

  void _sendPromptToAi() async {
    if (file == null || textControllerUserPrompt.text.isEmpty) {
      return;
    }

    // Set the prompt to the text in the text field
    promptTemplate = PromptTemplate.chatML().copyWith(
      prompt: textControllerUserPrompt.text.trim(),
    );

    // Clear the response from the AI
    setState(() {
      talkAsyncState = TalkAsyncState.thinking;
      // Clear the text field
      textControllerUserPrompt.clear();
    });

    // Debug print the prompt
    debugPrint('Prompt: ${promptTemplate.prompt}');

    await talkAsync(
      filePathToModel: file!.path,
      promptTemplate: promptTemplate,
      onTokenGenerated: (String token) {
        if (talkAsyncState == TalkAsyncState.thinking) {
          // Change the state to talking when the first token is generated
          setState(() {
            talkAsyncState = TalkAsyncState.talking;
            responseFromAi = '';
          });
        }

        // Add the token to the response from the AI
        setState(() {
          responseFromAi += token;
        });
      },
    );

    // Change the state back to idle when the AI is done talking
    setState(() {
      talkAsyncState = TalkAsyncState.idle;
    });
  }
}
