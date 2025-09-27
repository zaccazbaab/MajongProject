import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

class RoboflowService {
  final String apiUrl =
    "https://majong-backend-vercel-74swytgyi-zaccazbaabs-projects.vercel.app/api/inferMahjong";

  Future<Map<String, dynamic>?> sendImageFile(String imagePath) async {
    try {
      // 轉 Base64  
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"imageBase64": base64Image}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print("辨識結果: $data");
        return data;
      } else {
        print("API 錯誤: ${response.statusCode}");
        print("訊息: ${response.body}");
      }
    } catch (e) {
      print("呼叫 API 例外: $e");
    }
    return null;
  }
}
