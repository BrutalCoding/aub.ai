// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PromptTemplateImpl _$$PromptTemplateImplFromJson(Map<String, dynamic> json) =>
    _$PromptTemplateImpl(
      label: json['label'] as String,
      systemMessage: json['systemMessage'] as String? ?? '',
      promptTemplate: json['promptTemplate'] as String,
      prompt: json['prompt'] as String,
      output: json['output'] as String? ?? '',
      contextSize: json['contextSize'] as int? ?? 2048,
      verifiedSignatures: (json['verifiedSignatures'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
    );

Map<String, dynamic> _$$PromptTemplateImplToJson(
        _$PromptTemplateImpl instance) =>
    <String, dynamic>{
      'label': instance.label,
      'systemMessage': instance.systemMessage,
      'promptTemplate': instance.promptTemplate,
      'prompt': instance.prompt,
      'output': instance.output,
      'contextSize': instance.contextSize,
      'verifiedSignatures': instance.verifiedSignatures,
    };
