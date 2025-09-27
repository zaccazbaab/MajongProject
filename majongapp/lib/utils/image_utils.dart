import 'dart:io';
import 'dart:convert';

Future<String> imageToBase64(String imagePath) async {
  final bytes = await File(imagePath).readAsBytes();
  return base64Encode(bytes);
}
