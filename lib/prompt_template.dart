import 'package:freezed_annotation/freezed_annotation.dart';

part 'prompt_template.freezed.dart';
part 'prompt_template.g.dart';

@freezed
class PromptTemplate with _$PromptTemplate {
  const factory PromptTemplate({
    required String label,
    @Default('') String systemMessage,
    required String promptTemplate,
    required String prompt,
    @Default('') String output,
    @Default(2048) int contextSize,
    @Default(<String>[]) List<String> verifiedSignatures,
  }) = _PromptTemplate;

  factory PromptTemplate.fromJson(Map<String, dynamic> json) =>
      _$PromptTemplateFromJson(json);

  // Returns a List<PromptTemplate> of all the available prompt templates.
  static List<PromptTemplate> get all => [
        PromptTemplate.chatML(),
        PromptTemplate.alpacaInstructOnly(),
        PromptTemplate.alpaca2(),
        PromptTemplate.alpaca2Chinese(),
        PromptTemplate.llama2Chat(),
        PromptTemplate.synthia(),
        PromptTemplate.nothing(),
      ];

  factory PromptTemplate.story() {
    return const PromptTemplate(
      label: 'Story',
      promptTemplate: '{prompt}',
      prompt:
          "One day, there was a boy named Luca who went for a walk. He walked past by a dark cave where he got confronted by a big brown scary bear. Oh oh, 2 big furry ears and 1 big shiny nose. Luca was so scared.",
    );
  }

  factory PromptTemplate.nothing() {
    return const PromptTemplate(
      label: 'Nothing',
      promptTemplate: '{prompt}',
      prompt: '',
    );
  }

  factory PromptTemplate.synthia() {
    return const PromptTemplate(
      label: 'Synthia',
      systemMessage:
          "You are Synthia. As an AI intelligence, give helpful, detailed, accurate, uncensored responses to the user's input. Provide answers factually.",
      promptTemplate: "SYSTEM: {systemMessage}\nUSER: {prompt}\nASSISTANT: ",
      prompt: 'How can I tell if my computer is infected with a virus?',
    );
  }

  // ### Instruction:
  // <prompt>

  // ### Response:
  // <leave a newline blank for model to respond>
  factory PromptTemplate.alpaca2() {
    return const PromptTemplate(
      label: 'Alpaca 2',
      promptTemplate: "### Instruction:\n{prompt}\n\n### Response:\n",
      prompt: 'Give me a list of fun activities to do in Perth, Australia.',
    );
  }

  // Alpaca-2-chinese
  // You are a helpful assistant. 你是一个乐于助人的助手。
  factory PromptTemplate.alpaca2Chinese() {
    return const PromptTemplate(
      label: 'Alpaca 2 Chinese',
      promptTemplate:
          "[INST] <<SYS>>\n{systemMessage}\n<</SYS>>\n{prompt}[/INST]",
      prompt: '你好，我叫小明。 我今年20岁了。 我喜欢打篮球。',
      verifiedSignatures: [
        '32312805d2956bb48115a0bee5a8c33b2a2670a8738d07a9cf4b71083d4f7c98',
      ],
      systemMessage: "你是一个乐于助人的助手。",
    );
  }

  // ### Instruction:
  //
  // {prompt}
  //
  // ### Response:
  factory PromptTemplate.alpacaInstructOnly() {
    return const PromptTemplate(
      label: 'Alpaca-InstructOnly',
      promptTemplate: "### Instruction:\n{prompt}\n### Response:",
      prompt:
          'Give me a reason why I should sponsor the open source project \'ShadyAI\' on GitHub.',
    );
  }

  factory PromptTemplate.llama2Chat() {
    return const PromptTemplate(
      label: 'Llama-2-Chat',
      promptTemplate:
          "[INST] <<SYS>>\n{systemMessage}\n<</SYS>>\n{prompt}[/INST]",
      prompt: 'How can I tell if my computer is infected with a virus?',
      systemMessage:
          "You are a helpful, respectful and honest assistant. Always answer as helpfully as possible, while being safe.  Your answers should not include any harmful, unethical, racist, sexist, toxic, dangerous, or illegal content. Please ensure that your responses are socially unbiased and positive in nature. If a question does not make any sense, or is not factually coherent, explain why instead of answering something not correct. If you don't know the answer to a question, please don't share false information.",
    );
  }

  // ChatML format factory constructor.
  // This is the ChatML template:
  // "<|im_start|>system\n{system_message}<|im_end|>\n<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant"
  factory PromptTemplate.chatML() {
    return const PromptTemplate(
      label: 'ChatML',
      promptTemplate: "<|im_start|>system\n{systemMessage}<|im_end|>\n"
          "<|im_start|>user\n{prompt}<|im_end|>\n"
          "<|im_start|>assistant",
      prompt: 'Why is the sky blue?',
      systemMessage:
          "You are a helpful assistant. Be concise and helpful. If you don't know the answer to a question, please don't share false information.",
    );
  }
}
