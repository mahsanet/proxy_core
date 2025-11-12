// This is a generated file - do not edit.
//
// Generated from proto/ProxyCoreService.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names, unused_import

import 'dart:convert' as $convert;
import 'dart:core' as $core;
import 'dart:typed_data' as $typed_data;

@$core.Deprecated('Use startCoreRequestDescriptor instead')
const StartCoreRequest$json = {
  '1': 'StartCoreRequest',
  '2': [
    {'1': 'coreName', '3': 1, '4': 1, '5': 9, '10': 'coreName'},
    {'1': 'dir', '3': 2, '4': 1, '5': 9, '10': 'dir'},
    {'1': 'config', '3': 3, '4': 1, '5': 9, '10': 'config'},
    {'1': 'memory', '3': 4, '4': 1, '5': 5, '10': 'memory'},
    {'1': 'isString', '3': 5, '4': 1, '5': 8, '10': 'isString'},
    {'1': 'isVpnMode', '3': 6, '4': 1, '5': 8, '10': 'isVpnMode'},
    {'1': 'tunFD', '3': 7, '4': 1, '5': 13, '10': 'tunFD'},
    {'1': 'proxyPort', '3': 8, '4': 1, '5': 5, '10': 'proxyPort'},
  ],
};

/// Descriptor for `StartCoreRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List startCoreRequestDescriptor = $convert.base64Decode(
    'ChBTdGFydENvcmVSZXF1ZXN0EhoKCGNvcmVOYW1lGAEgASgJUghjb3JlTmFtZRIQCgNkaXIYAi'
    'ABKAlSA2RpchIWCgZjb25maWcYAyABKAlSBmNvbmZpZxIWCgZtZW1vcnkYBCABKAVSBm1lbW9y'
    'eRIaCghpc1N0cmluZxgFIAEoCFIIaXNTdHJpbmcSHAoJaXNWcG5Nb2RlGAYgASgIUglpc1Zwbk'
    '1vZGUSFAoFdHVuRkQYByABKA1SBXR1bkZEEhwKCXByb3h5UG9ydBgIIAEoBVIJcHJveHlQb3J0');

@$core.Deprecated('Use measurePingRequestDescriptor instead')
const MeasurePingRequest$json = {
  '1': 'MeasurePingRequest',
  '2': [
    {'1': 'url', '3': 1, '4': 3, '5': 9, '10': 'url'},
  ],
};

/// Descriptor for `MeasurePingRequest`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List measurePingRequestDescriptor = $convert.base64Decode(
    'ChJNZWFzdXJlUGluZ1JlcXVlc3QSEAoDdXJsGAEgAygJUgN1cmw=');

@$core.Deprecated('Use booleanResponseDescriptor instead')
const BooleanResponse$json = {
  '1': 'BooleanResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 8, '10': 'message'},
  ],
};

/// Descriptor for `BooleanResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List booleanResponseDescriptor = $convert.base64Decode(
    'Cg9Cb29sZWFuUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCFIHbWVzc2FnZQ==');

@$core.Deprecated('Use versionResponseDescriptor instead')
const VersionResponse$json = {
  '1': 'VersionResponse',
  '2': [
    {'1': 'message', '3': 1, '4': 1, '5': 9, '10': 'message'},
  ],
};

/// Descriptor for `VersionResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List versionResponseDescriptor = $convert.base64Decode(
    'Cg9WZXJzaW9uUmVzcG9uc2USGAoHbWVzc2FnZRgBIAEoCVIHbWVzc2FnZQ==');

@$core.Deprecated('Use logResponseDescriptor instead')
const LogResponse$json = {
  '1': 'LogResponse',
  '2': [
    {'1': 'logs', '3': 1, '4': 1, '5': 9, '10': 'logs'},
  ],
};

/// Descriptor for `LogResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List logResponseDescriptor = $convert.base64Decode(
    'CgtMb2dSZXNwb25zZRISCgRsb2dzGAEgASgJUgRsb2dz');

@$core.Deprecated('Use measurePingResponseDescriptor instead')
const MeasurePingResponse$json = {
  '1': 'MeasurePingResponse',
  '2': [
    {'1': 'results', '3': 1, '4': 3, '5': 11, '6': '.ProxyCore.PingResult', '10': 'results'},
  ],
};

/// Descriptor for `MeasurePingResponse`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List measurePingResponseDescriptor = $convert.base64Decode(
    'ChNNZWFzdXJlUGluZ1Jlc3BvbnNlEi8KB3Jlc3VsdHMYASADKAsyFS5Qcm94eUNvcmUuUGluZ1'
    'Jlc3VsdFIHcmVzdWx0cw==');

@$core.Deprecated('Use pingResultDescriptor instead')
const PingResult$json = {
  '1': 'PingResult',
  '2': [
    {'1': 'url', '3': 1, '4': 1, '5': 9, '10': 'url'},
    {'1': 'delay', '3': 2, '4': 1, '5': 3, '10': 'delay'},
  ],
};

/// Descriptor for `PingResult`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List pingResultDescriptor = $convert.base64Decode(
    'CgpQaW5nUmVzdWx0EhAKA3VybBgBIAEoCVIDdXJsEhQKBWRlbGF5GAIgASgDUgVkZWxheQ==');

@$core.Deprecated('Use emptyDescriptor instead')
const Empty$json = {
  '1': 'Empty',
};

/// Descriptor for `Empty`. Decode as a `google.protobuf.DescriptorProto`.
final $typed_data.Uint8List emptyDescriptor = $convert.base64Decode(
    'CgVFbXB0eQ==');

