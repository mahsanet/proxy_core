import 'package:grpc/grpc.dart' as grpc;

final grpc.ClientChannel grpcChannelConfig = grpc.ClientChannel(
  'localhost',
  port: 30051,
  options: const grpc.ChannelOptions(
    credentials: grpc.ChannelCredentials.insecure(),
    keepAlive: grpc.ClientKeepAliveOptions(),
    idleTimeout: Duration(seconds: 50),
    connectionTimeout: Duration(seconds: 50),
    connectTimeout: Duration(seconds: 50),
  ),
);
