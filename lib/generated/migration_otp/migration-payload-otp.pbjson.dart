// This is a generated file - do not edit.
//
// Generated from migration-payload-otp.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use migrationPayloadDescriptor instead')
const MigrationPayload$json = {
  '1': 'MigrationPayload',
  '2': [
    {
      '1': 'otp_parameters',
      '3': 1,
      '4': 3,
      '5': 11,
      '6': '.MigrationPayload.OtpParameters',
      '10': 'otpParameters'
    },
    {'1': 'version', '3': 2, '4': 1, '5': 5, '10': 'version'},
    {'1': 'batch_size', '3': 3, '4': 1, '5': 5, '10': 'batchSize'},
    {'1': 'batch_index', '3': 4, '4': 1, '5': 5, '10': 'batchIndex'},
    {'1': 'batch_id', '3': 5, '4': 1, '5': 5, '10': 'batchId'},
  ],
  '3': [MigrationPayload_OtpParameters$json],
  '4': [
    MigrationPayload_Algorithm$json,
    MigrationPayload_DigitCount$json,
    MigrationPayload_OtpType$json
  ],
};

@$core.Deprecated('Use migrationPayloadDescriptor instead')
const MigrationPayload_OtpParameters$json = {
  '1': 'OtpParameters',
  '2': [
    {'1': 'secret', '3': 1, '4': 1, '5': 12, '10': 'secret'},
    {'1': 'name', '3': 2, '4': 1, '5': 9, '10': 'name'},
    {'1': 'issuer', '3': 3, '4': 1, '5': 9, '10': 'issuer'},
    {
      '1': 'algorithm',
      '3': 4,
      '4': 1,
      '5': 14,
      '6': '.MigrationPayload.Algorithm',
      '10': 'algorithm'
    },
    {
      '1': 'digits',
      '3': 5,
      '4': 1,
      '5': 14,
      '6': '.MigrationPayload.DigitCount',
      '10': 'digits'
    },
    {
      '1': 'type',
      '3': 6,
      '4': 1,
      '5': 14,
      '6': '.MigrationPayload.OtpType',
      '10': 'type'
    },
    {'1': 'counter', '3': 7, '4': 1, '5': 3, '10': 'counter'},
  ],
};

@$core.Deprecated('Use migrationPayloadDescriptor instead')
const MigrationPayload_Algorithm$json = {
  '1': 'Algorithm',
  '2': [
    {'1': 'ALGORITHM_UNSPECIFIED', '2': 0},
    {'1': 'ALGORITHM_SHA1', '2': 1},
    {'1': 'ALGORITHM_SHA256', '2': 2},
    {'1': 'ALGORITHM_SHA512', '2': 3},
    {'1': 'ALGORITHM_MD5', '2': 4},
  ],
};

@$core.Deprecated('Use migrationPayloadDescriptor instead')
const MigrationPayload_DigitCount$json = {
  '1': 'DigitCount',
  '2': [
    {'1': 'DIGIT_COUNT_UNSPECIFIED', '2': 0},
    {'1': 'DIGIT_COUNT_SIX', '2': 1},
    {'1': 'DIGIT_COUNT_EIGHT', '2': 2},
  ],
};

@$core.Deprecated('Use migrationPayloadDescriptor instead')
const MigrationPayload_OtpType$json = {
  '1': 'OtpType',
  '2': [
    {'1': 'OTP_TYPE_UNSPECIFIED', '2': 0},
    {'1': 'OTP_TYPE_HOTP', '2': 1},
    {'1': 'OTP_TYPE_TOTP', '2': 2},
  ],
};

/// Descriptor for `MigrationPayload`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List migrationPayloadDescriptor = $convert.base64Decode(
    'ChBNaWdyYXRpb25QYXlsb2FkEkYKDm90cF9wYXJhbWV0ZXJzGAEgAygLMh8uTWlncmF0aW9uUG'
    'F5bG9hZC5PdHBQYXJhbWV0ZXJzUg1vdHBQYXJhbWV0ZXJzEhgKB3ZlcnNpb24YAiABKAVSB3Zl'
    'cnNpb24SHQoKYmF0Y2hfc2l6ZRgDIAEoBVIJYmF0Y2hTaXplEh8KC2JhdGNoX2luZGV4GAQgAS'
    'gFUgpiYXRjaEluZGV4EhkKCGJhdGNoX2lkGAUgASgFUgdiYXRjaElkGo0CCg1PdHBQYXJhbWV0'
    'ZXJzEhYKBnNlY3JldBgBIAEoDFIGc2VjcmV0EhIKBG5hbWUYAiABKAlSBG5hbWUSFgoGaXNzdW'
    'VyGAMgASgJUgZpc3N1ZXISOQoJYWxnb3JpdGhtGAQgASgOMhsuTWlncmF0aW9uUGF5bG9hZC5B'
    'bGdvcml0aG1SCWFsZ29yaXRobRI0CgZkaWdpdHMYBSABKA4yHC5NaWdyYXRpb25QYXlsb2FkLk'
    'RpZ2l0Q291bnRSBmRpZ2l0cxItCgR0eXBlGAYgASgOMhkuTWlncmF0aW9uUGF5bG9hZC5PdHBU'
    'eXBlUgR0eXBlEhgKB2NvdW50ZXIYByABKANSB2NvdW50ZXIieQoJQWxnb3JpdGhtEhkKFUFMR0'
    '9SSVRITV9VTlNQRUNJRklFRBAAEhIKDkFMR09SSVRITV9TSEExEAESFAoQQUxHT1JJVEhNX1NI'
    'QTI1NhACEhQKEEFMR09SSVRITV9TSEE1MTIQAxIRCg1BTEdPUklUSE1fTUQ1EAQiVQoKRGlnaX'
    'RDb3VudBIbChdESUdJVF9DT1VOVF9VTlNQRUNJRklFRBAAEhMKD0RJR0lUX0NPVU5UX1NJWBAB'
    'EhUKEURJR0lUX0NPVU5UX0VJR0hUEAIiSQoHT3RwVHlwZRIYChRPVFBfVFlQRV9VTlNQRUNJRk'
    'lFRBAAEhEKDU9UUF9UWVBFX0hPVFAQARIRCg1PVFBfVFlQRV9UT1RQEAI=');
