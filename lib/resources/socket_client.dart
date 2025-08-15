import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class SocketClient {
  ///  This is for implementing the Singleton Pattern (only one instance of SocketClient exists in the whole app)
  static SocketClient? _instance;

  /// socket connection instance
  IO.Socket? socket;

  SocketClient._internal() {
    /// while testing -> connects to local server
    /// while in use -> use hosted backend server
    final serverUrl = kDebugMode
        ? 'http://10.0.2.2:10000'
        : dotenv.env['SERVER_URL']!;
    socket = IO.io(serverUrl, <String, dynamic>{
      /// Forces using WebSocket transport only
      'transports': ['websocket'],
      'autoConnect': false,
    });

    /// Attach event listeners first
    socket!.onConnect((_) {
      print('✅ Socket connected: ${socket!.id}');
    });

    socket!.onConnectError((data) {
      print('❌ Connection error: $data');
    });

    socket!.onDisconnect((_) {
      print('🔌 Socket disconnected');
    });

    /// & starts the actual socket connection
    socket!.connect();
  }

  /// static means this method belongs to the class itself, not to any instance.
  static SocketClient? get instance {
    /// If _instance is null, create a new SocketClient using the private constructor
    /// If it already exists, just return the existing one
    /// This ensures only one socket connection exists throughout your app.
    _instance ??= SocketClient._internal();
    print('Instance returned: ${_instance}');
    return _instance!;
  }
}
