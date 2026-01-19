import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService {
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;

  SocketService._internal();

  WebSocketChannel? _channel;
  bool _isConnected = false;

  bool get isConnected => _isConnected;

  void connect(String url) {
    print("Yaa it is connected");
    if (_isConnected) return;

    _channel = WebSocketChannel.connect(Uri.parse(url));
    print("The channel is $_channel");
    _isConnected = true;
  }

  void sendJson(Map<String, dynamic> data) {
    print("The send data is $data");
    if (!_isConnected) return;
    _channel!.sink.add(jsonEncode(data));
  }

  void sendRaw(dynamic data) {
    if (!_isConnected) return;
    _channel!.sink.add(data);
  }

  void disconnect() {
    _channel?.sink.close();
    _channel = null;
    _isConnected = false;
  }
}
