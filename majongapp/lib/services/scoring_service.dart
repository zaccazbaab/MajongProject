import '../models/hand.dart';

class ScoringService {
  /// 計算役 & 符 (目前先放簡單版)
  Map<String, dynamic> calculate(Hand hand) {
    // TODO: 未來在這裡做役判斷 & 符數計算
    // 現在先回傳一個假資料
    return {
      "han": 1,
      "fu": 30,
      "yaku": ["立直"], 
      "points": hand.isDealer ? 1500 : 1000,
    };
  }
}
