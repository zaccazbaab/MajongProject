import 'dart:convert';
import 'package:http/http.dart' as http;
class ScoringService {
  static const String baseUrl ="https://mahjongpyapi-production.up.railway.app/check_hand";

  static Future<Map<String, dynamic>> calculateScore(List<String> tiles,String player_wind,String round_wind ,{int doraCount=0,bool is_tsumo=true}) async {
    final url = Uri.parse(baseUrl);
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tiles': tiles,
        'dora_count': doraCount,
        'is_tsumo':true,
        'player_wind':player_wind,
        'round_wind':round_wind,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to calculate score');
    }
  }
}