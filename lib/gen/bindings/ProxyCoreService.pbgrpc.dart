// This is a generated file - do not edit.
//
// Generated from proto/ProxyCoreService.proto.

// @dart = 3.3

// ignore_for_file: annotate_overrides, camel_case_types, comment_references
// ignore_for_file: constant_identifier_names
// ignore_for_file: curly_braces_in_flow_control_structures
// ignore_for_file: deprecated_member_use_from_same_package, library_prefixes
// ignore_for_file: non_constant_identifier_names

import 'dart:async' as $async;
import 'dart:core' as $core;

import 'package:grpc/service_api.dart' as $grpc;
import 'package:protobuf/protobuf.dart' as $pb;

import 'ProxyCoreService.pb.dart' as $0;

export 'ProxyCoreService.pb.dart';

/// Main gRPC service for controlling multiple proxy cores
@$pb.GrpcServiceName('ProxyCore.ProxyCore')
class ProxyCoreClient extends $grpc.Client {
  /// The hostname for this service.
  static const $core.String defaultHost = '';

  /// OAuth scopes needed for the client.
  static const $core.List<$core.String> oauthScopes = [
    '',
  ];

  ProxyCoreClient(super.channel, {super.options, super.interceptors});

  $grpc.ResponseFuture<$0.Empty> startCore($0.StartCoreRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$startCore, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> stopCore($0.Empty request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$stopCore, request, options: options);
  }

  $grpc.ResponseFuture<$0.BooleanResponse> isCoreRunning($0.Empty request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$isCoreRunning, request, options: options);
  }

  $grpc.ResponseFuture<$0.VersionResponse> getVersion($0.Empty request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$getVersion, request, options: options);
  }

  $grpc.ResponseFuture<$0.LogResponse> fetchLogs($0.Empty request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$fetchLogs, request, options: options);
  }

  $grpc.ResponseFuture<$0.Empty> clearLogs($0.Empty request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$clearLogs, request, options: options);
  }

  $grpc.ResponseFuture<$0.MeasurePingResponse> measurePing($0.MeasurePingRequest request, {$grpc.CallOptions? options,}) {
    return $createUnaryCall(_$measurePing, request, options: options);
  }

    // method descriptors

  static final _$startCore = $grpc.ClientMethod<$0.StartCoreRequest, $0.Empty>(
      '/ProxyCore.ProxyCore/startCore',
      ($0.StartCoreRequest value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$stopCore = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/ProxyCore.ProxyCore/stopCore',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$isCoreRunning = $grpc.ClientMethod<$0.Empty, $0.BooleanResponse>(
      '/ProxyCore.ProxyCore/isCoreRunning',
      ($0.Empty value) => value.writeToBuffer(),
      $0.BooleanResponse.fromBuffer);
  static final _$getVersion = $grpc.ClientMethod<$0.Empty, $0.VersionResponse>(
      '/ProxyCore.ProxyCore/getVersion',
      ($0.Empty value) => value.writeToBuffer(),
      $0.VersionResponse.fromBuffer);
  static final _$fetchLogs = $grpc.ClientMethod<$0.Empty, $0.LogResponse>(
      '/ProxyCore.ProxyCore/fetchLogs',
      ($0.Empty value) => value.writeToBuffer(),
      $0.LogResponse.fromBuffer);
  static final _$clearLogs = $grpc.ClientMethod<$0.Empty, $0.Empty>(
      '/ProxyCore.ProxyCore/clearLogs',
      ($0.Empty value) => value.writeToBuffer(),
      $0.Empty.fromBuffer);
  static final _$measurePing = $grpc.ClientMethod<$0.MeasurePingRequest, $0.MeasurePingResponse>(
      '/ProxyCore.ProxyCore/measurePing',
      ($0.MeasurePingRequest value) => value.writeToBuffer(),
      $0.MeasurePingResponse.fromBuffer);
}

@$pb.GrpcServiceName('ProxyCore.ProxyCore')
abstract class ProxyCoreServiceBase extends $grpc.Service {
  $core.String get $name => 'ProxyCore.ProxyCore';

  ProxyCoreServiceBase() {
    $addMethod($grpc.ServiceMethod<$0.StartCoreRequest, $0.Empty>(
        'startCore',
        startCore_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.StartCoreRequest.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'stopCore',
        stopCore_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.BooleanResponse>(
        'isCoreRunning',
        isCoreRunning_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.BooleanResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.VersionResponse>(
        'getVersion',
        getVersion_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.VersionResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.LogResponse>(
        'fetchLogs',
        fetchLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.LogResponse value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.Empty, $0.Empty>(
        'clearLogs',
        clearLogs_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.Empty.fromBuffer(value),
        ($0.Empty value) => value.writeToBuffer()));
    $addMethod($grpc.ServiceMethod<$0.MeasurePingRequest, $0.MeasurePingResponse>(
        'measurePing',
        measurePing_Pre,
        false,
        false,
        ($core.List<$core.int> value) => $0.MeasurePingRequest.fromBuffer(value),
        ($0.MeasurePingResponse value) => value.writeToBuffer()));
  }

  $async.Future<$0.Empty> startCore_Pre($grpc.ServiceCall $call, $async.Future<$0.StartCoreRequest> $request) async {
    return startCore($call, await $request);
  }

  $async.Future<$0.Empty> startCore($grpc.ServiceCall call, $0.StartCoreRequest request);

  $async.Future<$0.Empty> stopCore_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return stopCore($call, await $request);
  }

  $async.Future<$0.Empty> stopCore($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.BooleanResponse> isCoreRunning_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return isCoreRunning($call, await $request);
  }

  $async.Future<$0.BooleanResponse> isCoreRunning($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.VersionResponse> getVersion_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return getVersion($call, await $request);
  }

  $async.Future<$0.VersionResponse> getVersion($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.LogResponse> fetchLogs_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return fetchLogs($call, await $request);
  }

  $async.Future<$0.LogResponse> fetchLogs($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.Empty> clearLogs_Pre($grpc.ServiceCall $call, $async.Future<$0.Empty> $request) async {
    return clearLogs($call, await $request);
  }

  $async.Future<$0.Empty> clearLogs($grpc.ServiceCall call, $0.Empty request);

  $async.Future<$0.MeasurePingResponse> measurePing_Pre($grpc.ServiceCall $call, $async.Future<$0.MeasurePingRequest> $request) async {
    return measurePing($call, await $request);
  }

  $async.Future<$0.MeasurePingResponse> measurePing($grpc.ServiceCall call, $0.MeasurePingRequest request);

}
