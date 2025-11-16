import 'dart:convert';
import 'package:flutter/material.dart';
import '../db/database_helper.dart';
import '../utils/tiles.dart';
import '../utils/yaku_map.dart';
import '../main.dart';

class RecordPage extends StatefulWidget {
  const RecordPage({super.key});

  @override
  _RecordPageState createState() => _RecordPageState();
}

class _RecordPageState extends State<RecordPage> with RouteAware {
  ValueNotifier<List<Map<String, dynamic>>> recordsNotifier = ValueNotifier([]);

  @override
  void initState() {
    super.initState();
    print("RecordPage initState called");
    _refreshRecords(); // 初次載入
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    print("RecordPage didChangeDependencies called");
    routeObserver.subscribe(this, ModalRoute.of(context)!);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  // 從其他頁面返回
  @override
  void didPopNext() {
    print("RecordPage returned to foreground (didPopNext)");
    _refreshRecords();
  }

  Future<void> _refreshRecords() async {
    final allRecords = await DatabaseHelper.instance.getAllRecords();
    print("Fetched ${allRecords.length} records");
    recordsNotifier.value = allRecords;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ValueListenableBuilder<List<Map<String, dynamic>>>(
        valueListenable: recordsNotifier,
        builder: (context, records, _) {
          if (records.isEmpty) {
            return const Center(child: Text("目前沒有紀錄"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final r = records[index];
              final tiles = jsonDecode(r["tiles"]);
              final melds = jsonDecode(r["melds"]);
              final yakuJson = r['yaku'] ?? '[]';
              List<dynamic> yakuList;
              try {
                final decoded = jsonDecode(yakuJson);
                yakuList = decoded is List ? decoded : [];
              } catch (_) {
                yakuList = [];
              }
              final yakuText = yakuList.map((y) => yakuTranslation[y] ?? y).join(', ');

              return Card(
                color: Colors.grey[850],
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(r["created_at"].toString(), style: const TextStyle(color: Colors.grey, fontSize: 12)),
                          Text("${r["total_score"]} 點", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      _handTileRow(List<String>.from(tiles.map((e) => e.toString())), r["win_tile"]),
                      if (melds.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        const Text("副露：", style: TextStyle(color: Colors.white70)),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            for (var m in melds)
                              Text("・${formatMeld(m)}", style: const TextStyle(color: Colors.white70)),
                          ],
                        ),
                      ],
                      const SizedBox(height: 4),
                      Text("役：$yakuText", style: const TextStyle(color: Colors.white70)),
                      Text("番：${r["han"]} / 符：${r["fu"]}", style: const TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _handTileRow(List<String> tiles, String? winTile) {
    List<String> handTiles = List<String>.from(tiles);
    if (winTile != null) handTiles.remove(winTile);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ...handTiles.take(13).map(_tileBox).toList(),
          if (winTile != null) const SizedBox(width: 12),
          if (winTile != null) _tileBox(winTile),
        ],
      ),
    );
  }

  Widget _tileBox(String tile) {
    final path = classToFile[tile];
    if (path != null) {
      return Container(
        width: 30,
        height: 45,
        margin: const EdgeInsets.all(2),
        child: Image.asset(path, fit: BoxFit.contain),
      );
    } else {
      return Container(
        width: 30,
        height: 45,
        margin: const EdgeInsets.all(2),
        color: Colors.grey,
        child: Center(child: Text(tile, style: const TextStyle(color: Colors.white, fontSize: 10))),
      );
    }
  }
}

String formatMeld(Map<String, dynamic> meld) {
  // type mapping
  const typeMap = {
    "chi": "吃",
    "pon": "碰",
    "kan": "槓",
  };

  // 花色 mapping
  const suitMap = {
    "C": "m",
    "B": "s",
    "D": "p",
  };

  final typeText = typeMap[meld["type"]] ?? meld["type"];

  final tilesText = (meld["tiles"] as List<dynamic>)
      .map((t) {
        final s = t.toString();
        if (s.length < 2) return s;
        final num = s.substring(0, s.length - 1);
        final suit = s.substring(s.length - 1);
        return "$num${suitMap[suit] ?? suit}";
      })
      .join(",");

  return "$typeText:$tilesText";
}
