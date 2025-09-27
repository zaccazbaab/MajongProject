// lib/models/hand.dart

class Hand {
  final List<String> tiles;     // 13 張原手牌
  final String winningTile;     // 最後和牌的那張
  final bool isTsumo;           // 自摸 true / 榮和 false
  final bool isDealer;          // 是否莊家
  final int doraCount;          // 寶牌數

  Hand({
    required this.tiles,
    required this.winningTile,
    required this.isTsumo,
    required this.isDealer,
    this.doraCount = 0,
  });

  /// 取得完整的14張牌
  List<String> get fullHand => [...tiles, winningTile];
}
