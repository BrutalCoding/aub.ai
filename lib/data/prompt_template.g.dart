// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'prompt_template.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$PromptTemplateImpl _$$PromptTemplateImplFromJson(Map<String, dynamic> json) =>
    _$PromptTemplateImpl(
      template: json['template'] as String,
      label: json['label'] as String?,
      contextSize: json['contextSize'] as int?,
      randomSeedNumber: json['randomSeedNumber'] as int?,
      cpuThreadsToUse: json['cpuThreadsToUse'] as int?,
      eosToken: json['eosToken'] as String?,
      temperature: (json['temperature'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$PromptTemplateImplToJson(
        _$PromptTemplateImpl instance) =>
    <String, dynamic>{
      'template': instance.template,
      'label': instance.label,
      'contextSize': instance.contextSize,
      'randomSeedNumber': instance.randomSeedNumber,
      'cpuThreadsToUse': instance.cpuThreadsToUse,
      'eosToken': instance.eosToken,
      'temperature': instance.temperature,
    };
