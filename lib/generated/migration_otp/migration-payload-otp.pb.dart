// This is a generated file - do not edit.
//
// Generated from migration-payload-otp.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

import 'migration-payload-otp.pbenum.dart';

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

export 'migration-payload-otp.pbenum.dart';

class MigrationPayload_OtpParameters extends $pb.GeneratedMessage {
  factory MigrationPayload_OtpParameters({
    $core.List<$core.int>? secret,
    $core.String? name,
    $core.String? issuer,
    MigrationPayload_Algorithm? algorithm,
    MigrationPayload_DigitCount? digits,
    MigrationPayload_OtpType? type,
    $fixnum.Int64? counter,
  }) {
    final result = create();
    if (secret != null) result.secret = secret;
    if (name != null) result.name = name;
    if (issuer != null) result.issuer = issuer;
    if (algorithm != null) result.algorithm = algorithm;
    if (digits != null) result.digits = digits;
    if (type != null) result.type = type;
    if (counter != null) result.counter = counter;
    return result;
  }

  MigrationPayload_OtpParameters._();

  factory MigrationPayload_OtpParameters.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationPayload_OtpParameters.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationPayload.OtpParameters',
      createEmptyInstance: create)
    ..a<$core.List<$core.int>>(
        1, _omitFieldNames ? '' : 'secret', $pb.PbFieldType.OY)
    ..aOS(2, _omitFieldNames ? '' : 'name')
    ..aOS(3, _omitFieldNames ? '' : 'issuer')
    ..e<MigrationPayload_Algorithm>(
        4, _omitFieldNames ? '' : 'algorithm', $pb.PbFieldType.OE,
        defaultOrMaker: MigrationPayload_Algorithm.ALGORITHM_UNSPECIFIED,
        valueOf: MigrationPayload_Algorithm.valueOf,
        enumValues: MigrationPayload_Algorithm.values)
    ..e<MigrationPayload_DigitCount>(
        5, _omitFieldNames ? '' : 'digits', $pb.PbFieldType.OE,
        defaultOrMaker: MigrationPayload_DigitCount.DIGIT_COUNT_UNSPECIFIED,
        valueOf: MigrationPayload_DigitCount.valueOf,
        enumValues: MigrationPayload_DigitCount.values)
    ..e<MigrationPayload_OtpType>(
        6, _omitFieldNames ? '' : 'type', $pb.PbFieldType.OE,
        defaultOrMaker: MigrationPayload_OtpType.OTP_TYPE_UNSPECIFIED,
        valueOf: MigrationPayload_OtpType.valueOf,
        enumValues: MigrationPayload_OtpType.values)
    ..aInt64(7, _omitFieldNames ? '' : 'counter')
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationPayload_OtpParameters clone() =>
      MigrationPayload_OtpParameters()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationPayload_OtpParameters copyWith(
          void Function(MigrationPayload_OtpParameters) updates) =>
      super.copyWith(
              (message) => updates(message as MigrationPayload_OtpParameters))
          as MigrationPayload_OtpParameters;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationPayload_OtpParameters create() =>
      MigrationPayload_OtpParameters._();
  @$core.override
  MigrationPayload_OtpParameters createEmptyInstance() => create();
  static $pb.PbList<MigrationPayload_OtpParameters> createRepeated() =>
      $pb.PbList<MigrationPayload_OtpParameters>();
  @$core.pragma('dart2js:noInline')
  static MigrationPayload_OtpParameters getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationPayload_OtpParameters>(create);
  static MigrationPayload_OtpParameters? _defaultInstance;

  @$pb.TagNumber(1)
  $core.List<$core.int> get secret => $_getN(0);
  @$pb.TagNumber(1)
  set secret($core.List<$core.int> value) => $_setBytes(0, value);
  @$pb.TagNumber(1)
  $core.bool hasSecret() => $_has(0);
  @$pb.TagNumber(1)
  void clearSecret() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get name => $_getSZ(1);
  @$pb.TagNumber(2)
  set name($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasName() => $_has(1);
  @$pb.TagNumber(2)
  void clearName() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get issuer => $_getSZ(2);
  @$pb.TagNumber(3)
  set issuer($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasIssuer() => $_has(2);
  @$pb.TagNumber(3)
  void clearIssuer() => $_clearField(3);

  @$pb.TagNumber(4)
  MigrationPayload_Algorithm get algorithm => $_getN(3);
  @$pb.TagNumber(4)
  set algorithm(MigrationPayload_Algorithm value) => $_setField(4, value);
  @$pb.TagNumber(4)
  $core.bool hasAlgorithm() => $_has(3);
  @$pb.TagNumber(4)
  void clearAlgorithm() => $_clearField(4);

  @$pb.TagNumber(5)
  MigrationPayload_DigitCount get digits => $_getN(4);
  @$pb.TagNumber(5)
  set digits(MigrationPayload_DigitCount value) => $_setField(5, value);
  @$pb.TagNumber(5)
  $core.bool hasDigits() => $_has(4);
  @$pb.TagNumber(5)
  void clearDigits() => $_clearField(5);

  @$pb.TagNumber(6)
  MigrationPayload_OtpType get type => $_getN(5);
  @$pb.TagNumber(6)
  set type(MigrationPayload_OtpType value) => $_setField(6, value);
  @$pb.TagNumber(6)
  $core.bool hasType() => $_has(5);
  @$pb.TagNumber(6)
  void clearType() => $_clearField(6);

  @$pb.TagNumber(7)
  $fixnum.Int64 get counter => $_getI64(6);
  @$pb.TagNumber(7)
  set counter($fixnum.Int64 value) => $_setInt64(6, value);
  @$pb.TagNumber(7)
  $core.bool hasCounter() => $_has(6);
  @$pb.TagNumber(7)
  void clearCounter() => $_clearField(7);
}

class MigrationPayload extends $pb.GeneratedMessage {
  factory MigrationPayload({
    $core.Iterable<MigrationPayload_OtpParameters>? otpParameters,
    $core.int? version,
    $core.int? batchSize,
    $core.int? batchIndex,
    $core.int? batchId,
  }) {
    final result = create();
    if (otpParameters != null) result.otpParameters.addAll(otpParameters);
    if (version != null) result.version = version;
    if (batchSize != null) result.batchSize = batchSize;
    if (batchIndex != null) result.batchIndex = batchIndex;
    if (batchId != null) result.batchId = batchId;
    return result;
  }

  MigrationPayload._();

  factory MigrationPayload.fromBuffer($core.List<$core.int> data,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromBuffer(data, registry);
  factory MigrationPayload.fromJson($core.String json,
          [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) =>
      create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(
      _omitMessageNames ? '' : 'MigrationPayload',
      createEmptyInstance: create)
    ..pc<MigrationPayload_OtpParameters>(
        1, _omitFieldNames ? '' : 'otpParameters', $pb.PbFieldType.PM,
        subBuilder: MigrationPayload_OtpParameters.create)
    ..a<$core.int>(2, _omitFieldNames ? '' : 'version', $pb.PbFieldType.O3)
    ..a<$core.int>(3, _omitFieldNames ? '' : 'batchSize', $pb.PbFieldType.O3)
    ..a<$core.int>(4, _omitFieldNames ? '' : 'batchIndex', $pb.PbFieldType.O3)
    ..a<$core.int>(5, _omitFieldNames ? '' : 'batchId', $pb.PbFieldType.O3)
    ..hasRequiredFields = false;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationPayload clone() => MigrationPayload()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MigrationPayload copyWith(void Function(MigrationPayload) updates) =>
      super.copyWith((message) => updates(message as MigrationPayload))
          as MigrationPayload;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MigrationPayload create() => MigrationPayload._();
  @$core.override
  MigrationPayload createEmptyInstance() => create();
  static $pb.PbList<MigrationPayload> createRepeated() =>
      $pb.PbList<MigrationPayload>();
  @$core.pragma('dart2js:noInline')
  static MigrationPayload getDefault() => _defaultInstance ??=
      $pb.GeneratedMessage.$_defaultFor<MigrationPayload>(create);
  static MigrationPayload? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<MigrationPayload_OtpParameters> get otpParameters => $_getList(0);

  @$pb.TagNumber(2)
  $core.int get version => $_getIZ(1);
  @$pb.TagNumber(2)
  set version($core.int value) => $_setSignedInt32(1, value);
  @$pb.TagNumber(2)
  $core.bool hasVersion() => $_has(1);
  @$pb.TagNumber(2)
  void clearVersion() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.int get batchSize => $_getIZ(2);
  @$pb.TagNumber(3)
  set batchSize($core.int value) => $_setSignedInt32(2, value);
  @$pb.TagNumber(3)
  $core.bool hasBatchSize() => $_has(2);
  @$pb.TagNumber(3)
  void clearBatchSize() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get batchIndex => $_getIZ(3);
  @$pb.TagNumber(4)
  set batchIndex($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasBatchIndex() => $_has(3);
  @$pb.TagNumber(4)
  void clearBatchIndex() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.int get batchId => $_getIZ(4);
  @$pb.TagNumber(5)
  set batchId($core.int value) => $_setSignedInt32(4, value);
  @$pb.TagNumber(5)
  $core.bool hasBatchId() => $_has(4);
  @$pb.TagNumber(5)
  void clearBatchId() => $_clearField(5);
}

const $core.bool _omitFieldNames =
    $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames =
    $core.bool.fromEnvironment('protobuf.omit_message_names');
