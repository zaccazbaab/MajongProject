import 'dart:io';
import 'dart:convert';

Future<String> imageToBase64(String imagePath) async {
  final bytes = await File(imagePath).readAsBytes();
  final base64Image = base64Encode(bytes);
  return base64Image;
}
