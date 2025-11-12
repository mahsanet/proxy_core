// This is a generated file - do not edit.
//
// Generated from proto/ProxyCoreService.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:core' as $core;

import 'package:fixnum/fixnum.dart' as $fixnum;
import 'package:protobuf/protobuf.dart' as $pb;

export 'package:protobuf/protobuf.dart' show GeneratedMessageGenericExtensions;

class StartCoreRequest extends $pb.GeneratedMessage {
  factory StartCoreRequest({
    $core.String? coreName,
    $core.String? dir,
    $core.String? config,
    $core.int? memory,
    $core.bool? isString,
    $core.bool? isVpnMode,
    $core.int? tunFD,
    $core.int? proxyPort,
  }) {
    final result = create();
    if (coreName != null) result.coreName = coreName;
    if (dir != null) result.dir = dir;
    if (config != null) result.config = config;
    if (memory != null) result.memory = memory;
    if (isString != null) result.isString = isString;
    if (isVpnMode != null) result.isVpnMode = isVpnMode;
    if (tunFD != null) result.tunFD = tunFD;
    if (proxyPort != null) result.proxyPort = proxyPort;
    return result;
  }

  StartCoreRequest._();

  factory StartCoreRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory StartCoreRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'StartCoreRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'coreName', protoName: 'coreName')
    ..aOS(2, _omitFieldNames ? '' : 'dir')
    ..aOS(3, _omitFieldNames ? '' : 'config')
    ..a<$core.int>(4, _omitFieldNames ? '' : 'memory', $pb.PbFieldType.O3)
    ..aOB(5, _omitFieldNames ? '' : 'isString', protoName: 'isString')
    ..aOB(6, _omitFieldNames ? '' : 'isVpnMode', protoName: 'isVpnMode')
    ..a<$core.int>(7, _omitFieldNames ? '' : 'tunFD', $pb.PbFieldType.OU3, protoName: 'tunFD')
    ..a<$core.int>(8, _omitFieldNames ? '' : 'proxyPort', $pb.PbFieldType.O3, protoName: 'proxyPort')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartCoreRequest clone() => StartCoreRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  StartCoreRequest copyWith(void Function(StartCoreRequest) updates) => super.copyWith((message) => updates(message as StartCoreRequest)) as StartCoreRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static StartCoreRequest create() => StartCoreRequest._();
  @$core.override
  StartCoreRequest createEmptyInstance() => create();
  static $pb.PbList<StartCoreRequest> createRepeated() => $pb.PbList<StartCoreRequest>();
  @$core.pragma('dart2js:noInline')
  static StartCoreRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<StartCoreRequest>(create);
  static StartCoreRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get coreName => $_getSZ(0);
  @$pb.TagNumber(1)
  set coreName($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasCoreName() => $_has(0);
  @$pb.TagNumber(1)
  void clearCoreName() => $_clearField(1);

  @$pb.TagNumber(2)
  $core.String get dir => $_getSZ(1);
  @$pb.TagNumber(2)
  set dir($core.String value) => $_setString(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDir() => $_has(1);
  @$pb.TagNumber(2)
  void clearDir() => $_clearField(2);

  @$pb.TagNumber(3)
  $core.String get config => $_getSZ(2);
  @$pb.TagNumber(3)
  set config($core.String value) => $_setString(2, value);
  @$pb.TagNumber(3)
  $core.bool hasConfig() => $_has(2);
  @$pb.TagNumber(3)
  void clearConfig() => $_clearField(3);

  @$pb.TagNumber(4)
  $core.int get memory => $_getIZ(3);
  @$pb.TagNumber(4)
  set memory($core.int value) => $_setSignedInt32(3, value);
  @$pb.TagNumber(4)
  $core.bool hasMemory() => $_has(3);
  @$pb.TagNumber(4)
  void clearMemory() => $_clearField(4);

  @$pb.TagNumber(5)
  $core.bool get isString => $_getBF(4);
  @$pb.TagNumber(5)
  set isString($core.bool value) => $_setBool(4, value);
  @$pb.TagNumber(5)
  $core.bool hasIsString() => $_has(4);
  @$pb.TagNumber(5)
  void clearIsString() => $_clearField(5);

  @$pb.TagNumber(6)
  $core.bool get isVpnMode => $_getBF(5);
  @$pb.TagNumber(6)
  set isVpnMode($core.bool value) => $_setBool(5, value);
  @$pb.TagNumber(6)
  $core.bool hasIsVpnMode() => $_has(5);
  @$pb.TagNumber(6)
  void clearIsVpnMode() => $_clearField(6);

  @$pb.TagNumber(7)
  $core.int get tunFD => $_getIZ(6);
  @$pb.TagNumber(7)
  set tunFD($core.int value) => $_setUnsignedInt32(6, value);
  @$pb.TagNumber(7)
  $core.bool hasTunFD() => $_has(6);
  @$pb.TagNumber(7)
  void clearTunFD() => $_clearField(7);

  @$pb.TagNumber(8)
  $core.int get proxyPort => $_getIZ(7);
  @$pb.TagNumber(8)
  set proxyPort($core.int value) => $_setSignedInt32(7, value);
  @$pb.TagNumber(8)
  $core.bool hasProxyPort() => $_has(7);
  @$pb.TagNumber(8)
  void clearProxyPort() => $_clearField(8);
}

class MeasurePingRequest extends $pb.GeneratedMessage {
  factory MeasurePingRequest({
    $core.Iterable<$core.String>? url,
  }) {
    final result = create();
    if (url != null) result.url.addAll(url);
    return result;
  }

  MeasurePingRequest._();

  factory MeasurePingRequest.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory MeasurePingRequest.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MeasurePingRequest', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..pPS(1, _omitFieldNames ? '' : 'url')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MeasurePingRequest clone() => MeasurePingRequest()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MeasurePingRequest copyWith(void Function(MeasurePingRequest) updates) => super.copyWith((message) => updates(message as MeasurePingRequest)) as MeasurePingRequest;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MeasurePingRequest create() => MeasurePingRequest._();
  @$core.override
  MeasurePingRequest createEmptyInstance() => create();
  static $pb.PbList<MeasurePingRequest> createRepeated() => $pb.PbList<MeasurePingRequest>();
  @$core.pragma('dart2js:noInline')
  static MeasurePingRequest getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MeasurePingRequest>(create);
  static MeasurePingRequest? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<$core.String> get url => $_getList(0);
}

class BooleanResponse extends $pb.GeneratedMessage {
  factory BooleanResponse({
    $core.bool? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  BooleanResponse._();

  factory BooleanResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory BooleanResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'BooleanResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..aOB(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BooleanResponse clone() => BooleanResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  BooleanResponse copyWith(void Function(BooleanResponse) updates) => super.copyWith((message) => updates(message as BooleanResponse)) as BooleanResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static BooleanResponse create() => BooleanResponse._();
  @$core.override
  BooleanResponse createEmptyInstance() => create();
  static $pb.PbList<BooleanResponse> createRepeated() => $pb.PbList<BooleanResponse>();
  @$core.pragma('dart2js:noInline')
  static BooleanResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<BooleanResponse>(create);
  static BooleanResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.bool get message => $_getBF(0);
  @$pb.TagNumber(1)
  set message($core.bool value) => $_setBool(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

class VersionResponse extends $pb.GeneratedMessage {
  factory VersionResponse({
    $core.String? message,
  }) {
    final result = create();
    if (message != null) result.message = message;
    return result;
  }

  VersionResponse._();

  factory VersionResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory VersionResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'VersionResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'message')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse clone() => VersionResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  VersionResponse copyWith(void Function(VersionResponse) updates) => super.copyWith((message) => updates(message as VersionResponse)) as VersionResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static VersionResponse create() => VersionResponse._();
  @$core.override
  VersionResponse createEmptyInstance() => create();
  static $pb.PbList<VersionResponse> createRepeated() => $pb.PbList<VersionResponse>();
  @$core.pragma('dart2js:noInline')
  static VersionResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<VersionResponse>(create);
  static VersionResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get message => $_getSZ(0);
  @$pb.TagNumber(1)
  set message($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasMessage() => $_has(0);
  @$pb.TagNumber(1)
  void clearMessage() => $_clearField(1);
}

class LogResponse extends $pb.GeneratedMessage {
  factory LogResponse({
    $core.String? logs,
  }) {
    final result = create();
    if (logs != null) result.logs = logs;
    return result;
  }

  LogResponse._();

  factory LogResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory LogResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'LogResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'logs')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogResponse clone() => LogResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  LogResponse copyWith(void Function(LogResponse) updates) => super.copyWith((message) => updates(message as LogResponse)) as LogResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static LogResponse create() => LogResponse._();
  @$core.override
  LogResponse createEmptyInstance() => create();
  static $pb.PbList<LogResponse> createRepeated() => $pb.PbList<LogResponse>();
  @$core.pragma('dart2js:noInline')
  static LogResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<LogResponse>(create);
  static LogResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get logs => $_getSZ(0);
  @$pb.TagNumber(1)
  set logs($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasLogs() => $_has(0);
  @$pb.TagNumber(1)
  void clearLogs() => $_clearField(1);
}

class MeasurePingResponse extends $pb.GeneratedMessage {
  factory MeasurePingResponse({
    $core.Iterable<PingResult>? results,
  }) {
    final result = create();
    if (results != null) result.results.addAll(results);
    return result;
  }

  MeasurePingResponse._();

  factory MeasurePingResponse.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory MeasurePingResponse.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'MeasurePingResponse', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..pc<PingResult>(1, _omitFieldNames ? '' : 'results', $pb.PbFieldType.PM, subBuilder: PingResult.create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MeasurePingResponse clone() => MeasurePingResponse()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  MeasurePingResponse copyWith(void Function(MeasurePingResponse) updates) => super.copyWith((message) => updates(message as MeasurePingResponse)) as MeasurePingResponse;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static MeasurePingResponse create() => MeasurePingResponse._();
  @$core.override
  MeasurePingResponse createEmptyInstance() => create();
  static $pb.PbList<MeasurePingResponse> createRepeated() => $pb.PbList<MeasurePingResponse>();
  @$core.pragma('dart2js:noInline')
  static MeasurePingResponse getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<MeasurePingResponse>(create);
  static MeasurePingResponse? _defaultInstance;

  @$pb.TagNumber(1)
  $pb.PbList<PingResult> get results => $_getList(0);
}

class PingResult extends $pb.GeneratedMessage {
  factory PingResult({
    $core.String? url,
    $fixnum.Int64? delay,
  }) {
    final result = create();
    if (url != null) result.url = url;
    if (delay != null) result.delay = delay;
    return result;
  }

  PingResult._();

  factory PingResult.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory PingResult.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'PingResult', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..aOS(1, _omitFieldNames ? '' : 'url')
    ..aInt64(2, _omitFieldNames ? '' : 'delay')
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingResult clone() => PingResult()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  PingResult copyWith(void Function(PingResult) updates) => super.copyWith((message) => updates(message as PingResult)) as PingResult;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static PingResult create() => PingResult._();
  @$core.override
  PingResult createEmptyInstance() => create();
  static $pb.PbList<PingResult> createRepeated() => $pb.PbList<PingResult>();
  @$core.pragma('dart2js:noInline')
  static PingResult getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<PingResult>(create);
  static PingResult? _defaultInstance;

  @$pb.TagNumber(1)
  $core.String get url => $_getSZ(0);
  @$pb.TagNumber(1)
  set url($core.String value) => $_setString(0, value);
  @$pb.TagNumber(1)
  $core.bool hasUrl() => $_has(0);
  @$pb.TagNumber(1)
  void clearUrl() => $_clearField(1);

  @$pb.TagNumber(2)
  $fixnum.Int64 get delay => $_getI64(1);
  @$pb.TagNumber(2)
  set delay($fixnum.Int64 value) => $_setInt64(1, value);
  @$pb.TagNumber(2)
  $core.bool hasDelay() => $_has(1);
  @$pb.TagNumber(2)
  void clearDelay() => $_clearField(2);
}

class Empty extends $pb.GeneratedMessage {
  factory Empty() => create();

  Empty._();

  factory Empty.fromBuffer($core.List<$core.int> data, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromBuffer(data, registry);
  factory Empty.fromJson($core.String json, [$pb.ExtensionRegistry registry = $pb.ExtensionRegistry.EMPTY]) => create()..mergeFromJson(json, registry);

  static final $pb.BuilderInfo _i = $pb.BuilderInfo(_omitMessageNames ? '' : 'Empty', package: const $pb.PackageName(_omitMessageNames ? '' : 'ProxyCore'), createEmptyInstance: create)
    ..hasRequiredFields = false
  ;

  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty clone() => Empty()..mergeFromMessage(this);
  @$core.Deprecated('See https://github.com/google/protobuf.dart/issues/998.')
  Empty copyWith(void Function(Empty) updates) => super.copyWith((message) => updates(message as Empty)) as Empty;

  @$core.override
  $pb.BuilderInfo get info_ => _i;

  @$core.pragma('dart2js:noInline')
  static Empty create() => Empty._();
  @$core.override
  Empty createEmptyInstance() => create();
  static $pb.PbList<Empty> createRepeated() => $pb.PbList<Empty>();
  @$core.pragma('dart2js:noInline')
  static Empty getDefault() => _defaultInstance ??= $pb.GeneratedMessage.$_defaultFor<Empty>(create);
  static Empty? _defaultInstance;
}


const $core.bool _omitFieldNames = $core.bool.fromEnvironment('protobuf.omit_field_names');
const $core.bool _omitMessageNames = $core.bool.fromEnvironment('protobuf.omit_message_names');
