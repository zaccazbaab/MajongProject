import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class RoboflowService {
  final String workflowUrl =
      "https://serverless.roboflow.com/infer/workflows/mahjong-cd5im/mahjongriichi";

  // 上傳本地圖片
  Future<Map<String, dynamic>?> sendImage(String imagePath) async {
    final apiKey = dotenv.env['ROBOFLOW_API_KEY'] ?? "";
    if (apiKey.isEmpty) {
      print("❌ API key 尚未設定，請確認 .env 是否存在且 dotenv 已初始化");
      return null;
    }

    try {
      final bytes = await File(imagePath).readAsBytes();
      final base64Image = base64Encode(bytes);

      final url = Uri.parse(workflowUrl);

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "api_key": apiKey,
          "inputs": {
            "image": {"type": "base64", "value": base64Image}
          }
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        print("✅ 辨識結果: $result");
        return result;
      } else {
        print("❌ API 錯誤: ${response.statusCode}");
        print("訊息: ${response.body}");
      }
    } catch (e) {
      print("❌ API 呼叫例外: $e");
    }
    return null;
  }
}

