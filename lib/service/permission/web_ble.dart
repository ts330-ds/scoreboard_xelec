@JS()
library web_ble;

import 'dart:js_interop';

@JS('connectBluetooth')
external JSPromise connectBluetooth();

@JS('sendCommand')
external JSPromise sendCommand(JSString cmd);

class WebBle {
  static Future<void> connect() async {
    await connectBluetooth().toDart;
  }

  static Future<void> send(String cmd) async {
    await sendCommand(cmd.toJS).toDart;
  }
}
