import 'dart:convert';
import 'package:http/http.dart' as http;

class RoboflowService {
  final String vercelUrl = "https://mahjong-backend-xp31.vercel.app/api/inferMahjong";

  Future<Map<String, dynamic>?> sendBase64Image(String base64Image) async {
    final cleanBase64 = base64Image.replaceAll('\n', '');

    print("Sending base64 length: ${cleanBase64.length}");

    try {
      final response = await http.post(
        Uri.parse(vercelUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"imageBase64": cleanBase64}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        print("API 回傳錯誤: ${response.statusCode}, ${response.body}");
        return null;
      }
    } catch (e) {
      print("RoboflowService 發生錯誤: $e");
      return null;
    }
  }
}
