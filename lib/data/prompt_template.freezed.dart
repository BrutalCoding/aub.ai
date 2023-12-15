// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'prompt_template.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#custom-getters-and-methods');

PromptTemplate _$PromptTemplateFromJson(Map<String, dynamic> json) {
  return _PromptTemplate.fromJson(json);
}

/// @nodoc
mixin _$PromptTemplate {
  /// [promptTemplate] is the template to use for inference such as ChatML.
  String get template => throw _privateConstructorUsedError;

  /// [label] is the label to use for the template. This can be used to
  /// identify the template in the UI such as a dropdown menu.
  String? get label => throw _privateConstructorUsedError;

  /// [maxTokens] is the maximum number of tokens to generate.
  int? get contextSize => throw _privateConstructorUsedError;

  /// [randomSeedNumber] is the random seed number to use for inference.
  /// If null, aub_ai will tell llama.cpp to use a random seed number.
  int? get randomSeedNumber => throw _privateConstructorUsedError;

  /// [cpuThreadsToUse] is the number of CPU threads to use for inference.
  /// If null, aub_ai will tell llama.cpp to use all available CPU threads.
  int? get cpuThreadsToUse => throw _privateConstructorUsedError;

  /// [eosToken] is the token to use for the end of the prompt.
  /// Many models differ in what token they use for the end of the prompt.
  /// For example, ChatML uses "<|im_end|>" (without quotes).
  String? get eosToken => throw _privateConstructorUsedError;

  /// [temperature] is the temperature to use for inference.
  /// This is a float value between 0.0 and 1.0.
  /// Higher values mean more randomness, thus more creativity.
  /// Lower values mean less randomness, thus more accuracy.
  double? get temperature => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $PromptTemplateCopyWith<PromptTemplate> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $PromptTemplateCopyWith<$Res> {
  factory $PromptTemplateCopyWith(
          PromptTemplate value, $Res Function(PromptTemplate) then) =
      _$PromptTemplateCopyWithImpl<$Res, PromptTemplate>;
  @useResult
  $Res call(
      {String template,
      String? label,
      int? contextSize,
      int? randomSeedNumber,
      int? cpuThreadsToUse,
      String? eosToken,
      double? temperature});
}

/// @nodoc
class _$PromptTemplateCopyWithImpl<$Res, $Val extends PromptTemplate>
    implements $PromptTemplateCopyWith<$Res> {
  _$PromptTemplateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? template = null,
    Object? label = freezed,
    Object? contextSize = freezed,
    Object? randomSeedNumber = freezed,
    Object? cpuThreadsToUse = freezed,
    Object? eosToken = freezed,
    Object? temperature = freezed,
  }) {
    return _then(_value.copyWith(
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      contextSize: freezed == contextSize
          ? _value.contextSize
          : contextSize // ignore: cast_nullable_to_non_nullable
              as int?,
      randomSeedNumber: freezed == randomSeedNumber
          ? _value.randomSeedNumber
          : randomSeedNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      cpuThreadsToUse: freezed == cpuThreadsToUse
          ? _value.cpuThreadsToUse
          : cpuThreadsToUse // ignore: cast_nullable_to_non_nullable
              as int?,
      eosToken: freezed == eosToken
          ? _value.eosToken
          : eosToken // ignore: cast_nullable_to_non_nullable
              as String?,
      temperature: freezed == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$PromptTemplateImplCopyWith<$Res>
    implements $PromptTemplateCopyWith<$Res> {
  factory _$$PromptTemplateImplCopyWith(_$PromptTemplateImpl value,
          $Res Function(_$PromptTemplateImpl) then) =
      __$$PromptTemplateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String template,
      String? label,
      int? contextSize,
      int? randomSeedNumber,
      int? cpuThreadsToUse,
      String? eosToken,
      double? temperature});
}

/// @nodoc
class __$$PromptTemplateImplCopyWithImpl<$Res>
    extends _$PromptTemplateCopyWithImpl<$Res, _$PromptTemplateImpl>
    implements _$$PromptTemplateImplCopyWith<$Res> {
  __$$PromptTemplateImplCopyWithImpl(
      _$PromptTemplateImpl _value, $Res Function(_$PromptTemplateImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? template = null,
    Object? label = freezed,
    Object? contextSize = freezed,
    Object? randomSeedNumber = freezed,
    Object? cpuThreadsToUse = freezed,
    Object? eosToken = freezed,
    Object? temperature = freezed,
  }) {
    return _then(_$PromptTemplateImpl(
      template: null == template
          ? _value.template
          : template // ignore: cast_nullable_to_non_nullable
              as String,
      label: freezed == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
      contextSize: freezed == contextSize
          ? _value.contextSize
          : contextSize // ignore: cast_nullable_to_non_nullable
              as int?,
      randomSeedNumber: freezed == randomSeedNumber
          ? _value.randomSeedNumber
          : randomSeedNumber // ignore: cast_nullable_to_non_nullable
              as int?,
      cpuThreadsToUse: freezed == cpuThreadsToUse
          ? _value.cpuThreadsToUse
          : cpuThreadsToUse // ignore: cast_nullable_to_non_nullable
              as int?,
      eosToken: freezed == eosToken
          ? _value.eosToken
          : eosToken // ignore: cast_nullable_to_non_nullable
              as String?,
      temperature: freezed == temperature
          ? _value.temperature
          : temperature // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$PromptTemplateImpl implements _PromptTemplate {
  const _$PromptTemplateImpl(
      {required this.template,
      this.label,
      this.contextSize,
      this.randomSeedNumber,
      this.cpuThreadsToUse,
      this.eosToken,
      this.temperature});

  factory _$PromptTemplateImpl.fromJson(Map<String, dynamic> json) =>
      _$$PromptTemplateImplFromJson(json);

  /// [promptTemplate] is the template to use for inference such as ChatML.
  @override
  final String template;

  /// [label] is the label to use for the template. This can be used to
  /// identify the template in the UI such as a dropdown menu.
  @override
  final String? label;

  /// [maxTokens] is the maximum number of tokens to generate.
  @override
  final int? contextSize;

  /// [randomSeedNumber] is the random seed number to use for inference.
  /// If null, aub_ai will tell llama.cpp to use a random seed number.
  @override
  final int? randomSeedNumber;

  /// [cpuThreadsToUse] is the number of CPU threads to use for inference.
  /// If null, aub_ai will tell llama.cpp to use all available CPU threads.
  @override
  final int? cpuThreadsToUse;

  /// [eosToken] is the token to use for the end of the prompt.
  /// Many models differ in what token they use for the end of the prompt.
  /// For example, ChatML uses "<|im_end|>" (without quotes).
  @override
  final String? eosToken;

  /// [temperature] is the temperature to use for inference.
  /// This is a float value between 0.0 and 1.0.
  /// Higher values mean more randomness, thus more creativity.
  /// Lower values mean less randomness, thus more accuracy.
  @override
  final double? temperature;

  @override
  String toString() {
    return 'PromptTemplate(template: $template, label: $label, contextSize: $contextSize, randomSeedNumber: $randomSeedNumber, cpuThreadsToUse: $cpuThreadsToUse, eosToken: $eosToken, temperature: $temperature)';
  }

  @override
  bool operator ==(dynamic other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$PromptTemplateImpl &&
            (identical(other.template, template) ||
                other.template == template) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.contextSize, contextSize) ||
                other.contextSize == contextSize) &&
            (identical(other.randomSeedNumber, randomSeedNumber) ||
                other.randomSeedNumber == randomSeedNumber) &&
            (identical(other.cpuThreadsToUse, cpuThreadsToUse) ||
                other.cpuThreadsToUse == cpuThreadsToUse) &&
            (identical(other.eosToken, eosToken) ||
                other.eosToken == eosToken) &&
            (identical(other.temperature, temperature) ||
                other.temperature == temperature));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, template, label, contextSize,
      randomSeedNumber, cpuThreadsToUse, eosToken, temperature);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$PromptTemplateImplCopyWith<_$PromptTemplateImpl> get copyWith =>
      __$$PromptTemplateImplCopyWithImpl<_$PromptTemplateImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$PromptTemplateImplToJson(
      this,
    );
  }
}

abstract class _PromptTemplate implements PromptTemplate {
  const factory _PromptTemplate(
      {required final String template,
      final String? label,
      final int? contextSize,
      final int? randomSeedNumber,
      final int? cpuThreadsToUse,
      final String? eosToken,
      final double? temperature}) = _$PromptTemplateImpl;

  factory _PromptTemplate.fromJson(Map<String, dynamic> json) =
      _$PromptTemplateImpl.fromJson;

  @override

  /// [promptTemplate] is the template to use for inference such as ChatML.
  String get template;
  @override

  /// [label] is the label to use for the template. This can be used to
  /// identify the template in the UI such as a dropdown menu.
  String? get label;
  @override

  /// [maxTokens] is the maximum number of tokens to generate.
  int? get contextSize;
  @override

  /// [randomSeedNumber] is the random seed number to use for inference.
  /// If null, aub_ai will tell llama.cpp to use a random seed number.
  int? get randomSeedNumber;
  @override

  /// [cpuThreadsToUse] is the number of CPU threads to use for inference.
  /// If null, aub_ai will tell llama.cpp to use all available CPU threads.
  int? get cpuThreadsToUse;
  @override

  /// [eosToken] is the token to use for the end of the prompt.
  /// Many models differ in what token they use for the end of the prompt.
  /// For example, ChatML uses "<|im_end|>" (without quotes).
  String? get eosToken;
  @override

  /// [temperature] is the temperature to use for inference.
  /// This is a float value between 0.0 and 1.0.
  /// Higher values mean more randomness, thus more creativity.
  /// Lower values mean less randomness, thus more accuracy.
  double? get temperature;
  @override
  @JsonKey(ignore: true)
  _$$PromptTemplateImplCopyWith<_$PromptTemplateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
