import 'package:freezed_annotation/freezed_annotation.dart';

part 'prompt_template.freezed.dart';
part 'prompt_template.g.dart';

@freezed
class PromptTemplate with _$PromptTemplate {
  const factory PromptTemplate({
    /// [promptTemplate] is the template to use for inference such as ChatML.
    required String template,

    /// [label] is the label to use for the template. This can be used to
    /// identify the template in the UI such as a dropdown menu.
    String? label,

    /// [maxTokens] is the maximum number of tokens to generate.
    int? contextSize,

    /// [randomSeedNumber] is the random seed number to use for inference.
    /// If null, aub_ai will tell llama.cpp to use a random seed number.
    int? randomSeedNumber,

    /// [cpuThreadsToUse] is the number of CPU threads to use for inference.
    /// If null, aub_ai will tell llama.cpp to use all available CPU threads.
    int? cpuThreadsToUse,

    /// [eosToken] is the token to use for the end of the prompt.
    /// Many models differ in what token they use for the end of the prompt.
    /// For example, ChatML uses "<|im_end|>" (without quotes).
    String? eosToken,

    /// [temperature] is the temperature to use for inference.
    /// This is a float value between 0.0 and 1.0.
    /// Higher values mean more randomness, thus more creativity.
    /// Lower values mean less randomness, thus more accuracy.
    double? temperature,
  }) = _PromptTemplate;

  factory PromptTemplate.fromJson(Map<String, dynamic> json) =>
      _$PromptTemplateFromJson(json);

  // ChatML format factory constructor.
  // This is the ChatML template:
  // "<|im_start|>system\n{system_message}<|im_end|>\n<|im_start|>user\n{prompt}<|im_end|>\n<|im_start|>assistant"
  factory PromptTemplate.chatML() {
    return const PromptTemplate(
      label: 'ChatML',
      template: "<|im_start|>system\n{systemMessage}<|im_end|>\n"
          "<|im_start|>user\n{prompt}<|im_end|>\n"
          "<|im_start|>assistant",
      eosToken: "<|im_end|>",
    );
  }
}
