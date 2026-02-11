// lib/data_conversion/image_processor.dart
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/foundation.dart';

// --- CONSTANTS ---
const int MATRIX_WIDTH = 128;
const int MATRIX_HEIGHT = 96;

// --- 1. HEX ARRAY PRINT UTILITY (For Debugging) ---
void printFrameAsHexArray(Uint8List rgb565Buffer, int width, int height) {
  if (rgb565Buffer.length != width * height * 2) {
    print("Error: Buffer size is incorrect.");
    return;
  }

  final int numPixels = width * height;
  final ByteData view = rgb565Buffer.buffer.asByteData();

  StringBuffer output = StringBuffer();
  output.writeln("const uint16_t FRAME_TEST_ARRAY[] PROGMEM = {");

  for (int p = 0; p < numPixels; p++) {
    final int j = p * 2;
    // Read the 16-bit value (Little Endian as written in converter)
    final int colorValue = view.getUint16(j, Endian.little);

    String hexString = '0x${colorValue.toRadixString(16).toUpperCase().padLeft(4, '0')}';

    output.write(hexString);

    if (p < numPixels - 1) {
      output.write(", ");
    }

    // Formatting: 16 pixels per line
    if ((p + 1) % 16 == 0) {
      output.writeln(" \t// 0x${(p + 1).toRadixString(16).toUpperCase()} (${p + 1}) pixels");
    }
  }

  output.writeln("\n};");
  print("\n--- HEX DEBUG ARRAY (Copy to Arduino for static test) ---");
  print(output.toString());
  print("---------------------------------------------------------");
}

// --- 2. THE ISOLATE CONVERSION FUNCTION (Top-level/Compute) ---
Uint8List rgb565Converter(List<dynamic> inputData) {
  final Uint8List rgbaBytes = inputData[0] as Uint8List;
  final int width = inputData[1] as int;
  final int height = inputData[2] as int;

  final int numPixels = width * height;
  final int rgb565Size = numPixels * 2;
  final Uint8List rgb565Buffer = Uint8List(rgb565Size);
  final ByteData view = rgb565Buffer.buffer.asByteData();

  for (int pixelIndex = 0; pixelIndex < numPixels; pixelIndex++) {
    final int i = pixelIndex * 4; // RGBA index
    final int j = pixelIndex * 2; // RGB565 index

    if (i + 3 >= rgbaBytes.length) break;

    // Read 8-bit components
    final int r8 = rgbaBytes[i];
    final int g8 = rgbaBytes[i + 1];
    final int b8 = rgbaBytes[i + 2];

    // Convert and pack to 16-bit RGB565 (R5 G6 B5)
    final int r5 = r8 >> 3;
    final int g6 = g8 >> 2;
    final int b5 = b8 >> 3;

    final int rgb565 = (r5 << 11) | (g6 << 5) | b5;

    // Write the 16-bit value (2 bytes) using Little Endian
    view.setUint16(j, rgb565, Endian.little);
  }

  return rgb565Buffer;
}

// --- 3. MAIN ASYNC WRAPPER FUNCTION ---
Future<Uint8List?> captureAndConvertWidget(GlobalKey repaintKey) async {
  try {
    // 1. Capture RGBA Bytes (Main Thread)
    RenderRepaintBoundary boundary =
    repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;

    ui.Image image = await boundary.toImage(pixelRatio: 1.0);
    ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);

    if (byteData == null) return null;

    final Uint8List rgbaBytes = byteData.buffer.asUint8List();

    // 2. Conversion in Isolate (Off Main Thread)
    final List<dynamic> inputData = [rgbaBytes, MATRIX_WIDTH, MATRIX_HEIGHT];
    final Uint8List rgb565Buffer = await compute(rgb565Converter, inputData);

    return rgb565Buffer;

  } catch (e) {
    debugPrint("Error in capture and convert: $e");
    return null;
  }
}