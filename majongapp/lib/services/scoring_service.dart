import 'dart:convert';
import 'package:http/http.dart' as http;
class ScoringService {
  static const String baseUrl ="https://mahjong-py-api.vercel.app/check_hand";

  static Future<Map<String, dynamic>> calculateScore(List<String> tiles,String player_wind,String round_wind ,String win_tile,{int doraCount=0,bool is_tsumo=true,List<Map<String, dynamic>>? melds ,bool isHaitei=false,bool isHoutei=false,bool isChankan=false,bool isRichi=false,bool isRinshan=false}) async {
    final url = Uri.parse(baseUrl);
    print("Calculating score with tiles: $tiles\nmelds:$melds\nwin_tile:$win_tile\ndoraCount: $doraCount\nis_tsumo: $is_tsumo\nplayer_wind: $player_wind\nround_wind: $round_wind");
    print("Is Riichi: $isRichi");
    print("Is Houtei: $isHoutei");
    print("Is Haitei: $isHaitei");
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'tiles': tiles,
        'melds': melds,
        'dora_count': doraCount,
        'is_tsumo':is_tsumo,
        'player_wind':player_wind,
        'round_wind':round_wind,
        'win_tile':win_tile,
        'isHaitei':isHaitei,
        'isHoutei':isHoutei,
        'isChankan':isChankan,
        'isRichi':isRichi,
        'isRinshan':isRinshan,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to calculate score');
    }
  }
}