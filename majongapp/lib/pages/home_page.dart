import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:majongapp/db/database_helper.dart';
import 'package:majongapp/main.dart';
import '../services/roboflow_service.dart';
import '../services/scoring_service.dart';
import '../utils/tiles.dart';
import '../utils/image_utils.dart';
import 'record_page.dart';
import 'dart:convert';
import '../utils/yaku_map.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late double screenWidth;

  Widget tileBox(
    String imagePath, {
    required bool isSelected,
    required bool isWinning,
    required bool isInMeld,
    required double screenWidth,
  }) {
    double globalTileScale = 0.6;
    double baseWidth = (screenWidth - 4 * 9 - 32) / 10;
    double width = baseWidth * globalTileScale;
    double height = width * 1.5;
  return AnimatedContainer(
    duration: const Duration(milliseconds: 150),
    margin: EdgeInsets.only(bottom: isSelected ? 8 : 0),
    child: imagePath.isNotEmpty
        ? Image.asset(
            imagePath,
            width: width,
            height: height,
            fit: BoxFit.contain,
          )
        : Container(
            width: width,
            height: height,
            color: Colors.grey,
          ),
  );
}
  bool isEditMode = false;
  Set<int> selectedIndices = {};
  Set<int> actionIndices = {}; 
  List<Map<String, dynamic>> actionSets = [];
  int? winningTileIndex;
  bool showActionMenu = false;
  // 27:東,28:南,29:西,30:北
  int selfWind = 27;
  int roundWind = 27;
  bool is_tsumo = true;
  bool isRichi = false;
  bool isHoutei = false;
  bool isHaitei = false;
  bool isChankan = false;
  bool isRinshan = false;
  int nextWind(int current) {
  final idx = current-27;
  return ((idx + 1) % 4)+27;
  }
  final List<String> winds = ["東", "南", "西", "北"];
  final List<String> winds_string = ["EW", "SW", "WW", "NW"];
  int _selectedIndex = 0;
  final ImagePicker picker = ImagePicker();
  final RoboflowService rfService = RoboflowService();
  Map<String, dynamic>? result;
  List<String> sortedClasses = ["1D","2D","3D","4D","5D","6D","7D","8D","9D","1B","2B","3B","EW","EW"];
  int doraCount = 0;

  // 手牌排序
  List<String> sortTiles(List<String> tiles) {
    final order = [
      "1D","2D","3D","4D","5D","6D","7D","8D","9D",
      "1B","2B","3B","4B","5B","6B","7B","8B","9B",
      "1C","2C","3C","4C","5C","6C","7C","8C","9C",
      "EW","SW","WW","NW","WD","GD","RD"
    ];
    tiles.sort((a, b) => order.indexOf(a).compareTo(order.indexOf(b)));
    return tiles;
  }
  Widget _buildActionButton(String text, Color color, VoidCallback onPressed) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: color,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    onPressed: onPressed,
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 18)),
  );
}





void _onChi() {
  print("執行 吃");
  setState(() {
    final indices = selectedNotifier.value.toList();
    actionSets.add({
      "tiles": indices.map((i) => sortedClasses[i]).toList(),
      "indices": indices.toList(), 
      "type": "chi",
      "opened": true,
    });
    selectedNotifier.value.clear();
    selectedIndices.clear();
    showActionMenu = false;
  
  });
}

void _onPon() {
  print("執行 碰");
  setState(() {
    final indices = selectedNotifier.value.toList();

    print("Selected indices for Pon: $indices");
    actionSets.add({
      "tiles": indices.map((i) => sortedClasses[i]).toList(),
      "indices": indices,
      "type": "pon",
      "opened": true,
    });
    selectedNotifier.value.clear();
    selectedIndices.clear();
    showActionMenu = false;
    print("Updated actionSets: $actionSets");
  });
}



void _onKan() {
  print("執行 槓");
  setState(() {
    final indices = selectedNotifier.value.toList();
    actionSets.add({
      "tiles": indices.map((i) => sortedClasses[i]).toList(),
      "indices": indices.toList(),
      "type": "kan",
      "opened": true,
    });
    selectedNotifier.value.clear(); // 清除選取
    selectedIndices.clear();
    showActionMenu = false;
    selectedIndices.clear();
  });
}

void _onAnkan() {
  print("執行 暗槓");
  setState(() {
    final indices = selectedNotifier.value.toList();
    actionSets.add({
      "tiles": indices.map((i) => sortedClasses[i]).toList(),
      "indices": indices.toList(),
      "type": "kan",
      "opened": false,
    });
    selectedNotifier.value.clear(); // 清除選取
    selectedIndices.clear();
    showActionMenu = false;
    selectedIndices.clear();
  });
}
void _onCancel() {
  print("執行 取消");
  setState(() {
    showActionMenu = false;
    selectedIndices.clear();
  });
}
void _showExtraSettings() {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text("其他設定"),
        content: SizedBox(
          height: 200, 
          child: Scrollbar(
            thumbVisibility: true, 
            child: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setStateDialog) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CheckboxListTile(
                        title: const Text("立直"),
                        value: isRichi,
                        onChanged: (val) {
                          setStateDialog(() => isRichi = val ?? false);
                          setState(() {});
                        },
                      ),
                      CheckboxListTile(
                        title: const Text("河底撈魚"),
                        value: isHoutei,
                        onChanged: (val) {
                          setStateDialog(() => isHoutei = val ?? false);
                          setState(() {});
                        },
                      ),
                      CheckboxListTile(
                        title: const Text("海底撈月"),
                        value: isHaitei,
                        onChanged: (val) {
                          setStateDialog(() => isHaitei = val ?? false);
                          setState(() {});
                        },
                      ),
                      


                      CheckboxListTile(
                        title: const Text("搶槓"),
                        value: isChankan,
                        onChanged: (val) {
                          setStateDialog(() => isChankan = val ?? false);
                          setState(() {});
                        },
                      ),
                      CheckboxListTile(
                        title: const Text("嶺上開花"),
                        value: isRinshan,
                        onChanged: (val) {
                          setStateDialog(() => isRinshan = val ?? false);
                          setState(() {});
                        },
                      ),
                    
                    ],
                  );
                },
              ),
              
            ),
          ),
        ),
        actionsPadding: EdgeInsets.zero,
        buttonPadding: EdgeInsets.zero,

        actions: [
          TextButton(
            child: const Text("關閉"),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      );
    },
  );
}







void _showScoreResult(Map<String, dynamic> scoreResult, String winTile) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      final yaku = scoreResult['yaku'];
      final yakuList = (yaku is List ? yaku : []).join(', ');

      final han = scoreResult['han'];
      final fu = scoreResult['fu'];
      final cost = scoreResult['cost'] ?? {};
      final totalCost = cost['total'] ?? 0;
      final mainCost = cost['main'] ?? 0;
      final additionalCost = cost['additional'] ?? 0;

      return Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.6,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Text(
                    "和牌: $winTile",
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 12),
                Text("役: $yakuList", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 6),
                Text("符: $fu", style: const TextStyle(fontSize: 16)),
                Text("翻: $han", style: const TextStyle(fontSize: 16)),
                const Divider(height: 24, thickness: 1),
                Text(
                  "分數:",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Text("總計: $totalCost", style: const TextStyle(fontSize: 16, color: Colors.green)),
                Text("本場: $mainCost", style: const TextStyle(fontSize: 16)),
                Text("加算: $additionalCost", style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                Center(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text("關閉"),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


void _showActionMenu() {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.black87,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (ctx) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton("吃", Colors.green, () {
              _onChi();
              Navigator.pop(ctx);
            }),
            _buildActionButton("碰", Colors.blue, () {
              _onPon();
              Navigator.pop(ctx);
            }),
            _buildActionButton("槓", Colors.purple, () {
              _onKan();
              Navigator.pop(ctx);
            }),
            _buildActionButton("暗槓", Colors.red, () {
              _onAnkan();
              Navigator.pop(ctx);
            }),
            _buildActionButton("取消", Colors.grey, () {
              _onCancel();
              Navigator.pop(ctx);
            }),
          ],
        ),
      );
    },
  );
}



  // 彈出選牌視窗
  Future<String?> pickTileDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.blueGrey,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueGrey,
            borderRadius: BorderRadius.circular(8),
          ),
          width: double.maxFinite,
          height: 400,
          child: classToFile.isNotEmpty
              ? GridView.count(
                  crossAxisCount: 8,
                  padding: const EdgeInsets.all(8),
                  crossAxisSpacing: 4,
                  mainAxisSpacing: 4,
                  children: classToFile.entries.map((entry) {
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, entry.key),
                      child: Image.asset(entry.value, fit: BoxFit.contain),
                    );
                  }).toList(),
                )
              : const Center(
                  child: Text("沒有牌可以選擇", style: TextStyle(color: Colors.white)),
                ),
        ),
      ),
    );
  }

  // 選擇圖片
  Future<void> _pickImage() async {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext ctx) {
        return SizedBox(
          height: 150,
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('拍照', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) await _processImage(image.path);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('從相簿選擇', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) await _processImage(image.path);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // 處理圖片並呼叫 Roboflow
  Future<void> _processImage(String imagePath) async {
  final base64 = await imageToBase64(imagePath);
  print("Base64 length: ${base64.length}");
  print("Start: ${base64.substring(0,50)}");
  print("End: ${base64.substring(base64.length - 50)}");

  final res = await rfService.sendBase64Image(base64);

  print("Full response: $res");
  
  // 安全檢查
  if (res != null &&
      res['outputs'] is List &&
      res['outputs'].isNotEmpty &&
      res['outputs'][0] is Map &&
      res['outputs'][0]['output2'] is Map &&
      res['outputs'][0]['output2']['predictions'] is List) {

    final predictions = res['outputs'][0]['output2']['predictions'] as List;

    final classes = predictions
        .where((p) => p != null && p['class'] != null)
        .map((p) => p['class'] as String)
        .toList();

    setState(() {
      result = res;
      sortedClasses = sortTiles(classes).take(14).toList();
    });
  } else {
    print("辨識失敗或資料格式不正確");
    setState(() {
      result = null;
    });
  }
}




ValueNotifier<Set<int>> selectedNotifier = ValueNotifier({});
ValueNotifier<int?> winningNotifier = ValueNotifier(null);

Widget _handTilesPage() {
  double screenWidth = MediaQuery.of(context).size.width;
  double cardWidth = (screenWidth - 4 * 9 - 32) / 10;
  double cardHeight = cardWidth * 1.5;

  return Center(
    child: result == null  && sortedClasses.isEmpty
        ? const Text('等待使用者選擇照片', style: TextStyle(color: Colors.white))
        : SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: cardHeight,
                  child: ValueListenableBuilder<Set<int>>(
                    valueListenable: selectedNotifier,
                    builder: (_, selectedIndices, __) {
                      return ValueListenableBuilder<int?>(
                        valueListenable: winningNotifier,
                        builder: (_, winningIndex, __) {
                          return ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: sortedClasses.length,
                            itemBuilder: (_, index) {
                              final cls = sortedClasses[index];
                              final path = classToFile[cls] ?? '';

                              return GestureDetector(
                                onTap: () async {
                                  if (isEditMode) {
                                    final newTile = await pickTileDialog(context);
                                    if (newTile != null) {
                                      setState(() {
                                        sortedClasses[index] = newTile;
                                        sortedClasses = sortTiles(sortedClasses);
                                      });
                                    }
                                  } else {
                                    final hitSetIndex = actionSets.indexWhere(
                                        (set) => set['indices'].contains(index));
                                    if (hitSetIndex != -1) {
                                      setState(() {
                                        actionSets.removeAt(hitSetIndex);
                                      });
                                      return;
                                    }

                                    // 更新選牌
                                    final newSelected = Set<int>.from(selectedNotifier.value);
                                    if (newSelected.contains(index)) {
                                      newSelected.remove(index);
                                    } else {
                                      newSelected.add(index);
                                    }
                                    selectedNotifier.value = newSelected;
                                    selectedIndices = newSelected;
                                    if (newSelected.length == 3) {
                                      _showActionMenu();
                                    }
                                  }
                                },
                                onLongPress: () {
                                  winningNotifier.value =
                                      winningNotifier.value == index ? null : index;
                                },
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  margin: EdgeInsets.only(
                                      bottom:
                                          selectedNotifier.value.contains(index) ? 8 : 0),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: winningNotifier.value == index
                                          ? Colors.greenAccent
                                          : actionSets.any(
                                                  (set) => set['indices'].contains(index))
                                              ? Colors.red
                                              : selectedNotifier.value.contains(index)
                                                  ? Colors.yellowAccent
                                                  : Colors.transparent,
                                      width: 3,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: tileBox(
                                  path,
                                  isSelected: selectedNotifier.value.contains(index),
                                  isWinning: winningNotifier.value == index,
                                  isInMeld: actionSets.any((set) => set['indices'].contains(index)),
                                  screenWidth: MediaQuery.of(context).size.width,
                                ),
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
                // 寶牌輸入
                Row(
                  children: [
                    const Text("寶牌數: ", style: TextStyle(color: Colors.white)),
                    SizedBox(
                      width: 60,
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          hintText: "0",
                          hintStyle: TextStyle(color: Colors.white54),
                          border: UnderlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {
                          doraCount = int.tryParse(value) ?? 0;
                        }),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // 各種按鈕
                Row(
                  children: [
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                      onPressed: sortedClasses.isEmpty
                          ? null
                          : () {
                            if (winningNotifier.value == null) {
                              showDialog(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: const Text("牌型不合法"),
                                  content: const Text("請長按牌選擇最後和牌",style: TextStyle(color: Colors.black)),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(ctx),
                                      child: const Text("關閉"),
                                    )
                                  ],
                                ),
                              );
                              return;
                            }
                              final handData = {
                                "tiles": sortedClasses,
                                "dora": doraCount,
                                "melds": actionSets
                                    .map((set) => {
                                          "type": set['type'],
                                          "tiles": set['indices']
                                              .map((idx) => sortedClasses[idx])
                                              .toList(),
                                          "opened": set['opened'] ?? true,
                                        })
                                    .toList(),
                                "win_tile": winningNotifier.value != null
                                    ? sortedClasses[winningNotifier.value!]
                                    : null,
                                "isRichi": isRichi,
                                "isHoutei": isHoutei,
                                "isHaitei": isHaitei,
                                "isChankan": isChankan,
                                "isRinshan": isRinshan,
                              };

                              print("整手牌: ${handData['tiles']}");
                              print("寶牌數: ${handData['dora']}");
                              print("melds: ${handData['melds']}");
                              print("最後摸到的牌: ${handData['win_tile']}");

                              ScoringService.calculateScore(
                                handData['tiles'] as List<String>,
                                winds_string[selfWind - 27],
                                winds_string[roundWind - 27],
                                handData['win_tile'] as String,
                                doraCount: handData['dora'] as int,
                                is_tsumo: is_tsumo,
                                isRichi: handData['isRichi'] as bool,
                                isHoutei: handData['isHoutei'] as bool,
                                isHaitei: handData['isHaitei'] as bool,
                                isChankan: handData['isChankan'] as bool,
                                isRinshan: handData['isRinshan'] as bool,
                                melds: handData['melds'] as List<Map<String, dynamic>>,
                              ).then((scoreResult) {
                                final han = scoreResult['han'] ?? 0;

                                  if (han == 0) {
                                    // 沒有胡牌
                                    showDialog(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text("牌型不合法"),
                                        content: const Text("這手牌無法胡牌"),
                                        actions: [
                                          TextButton(
                                            onPressed: () => Navigator.pop(ctx),
                                            child: const Text("關閉"),
                                          )
                                        ],
                                      ),
                                    );
                                    return;
                                  }
                                print("計算結果: $scoreResult");
                                showDialog(
                                context: context,
                                builder: (ctx) {
                                  final yakuList = (scoreResult['yaku'] as List<dynamic>);
                                  final han = scoreResult['han'];
                                  final fu = scoreResult['fu'];
                                  final mainCost = scoreResult['cost']['main'];
                                  final additionalCost = scoreResult['cost']['additional'];
                                  final totalCost = scoreResult['cost']['total'];

                                  final bool isParent = selfWind == roundWind; // 判斷親家
                                  String scoreText = "";

                                  if (is_tsumo) {
                                    if (isParent) {
                                      // 親家自摸
                                      scoreText = "總 $totalCost 子家 $additionalCost";
                                    } else {
                                      // 子家自摸
                                      scoreText = "總 $totalCost 親家 $mainCost\n子家 $additionalCost";
                                    }
                                  } else {
                                    // 榮和
                                    scoreText = "總 $totalCost";
                                  }

                                  return AlertDialog(
                                    title: const Text("胡牌結果", style: TextStyle(color: Colors.black)),
                                    content: SingleChildScrollView(
                                      child: DefaultTextStyle(
                                        style: const TextStyle(color: Colors.black),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text("役: ${yakuList.map((y) => yakuTranslation[y] ?? y).join(', ')}"),
                                            Text("符: $fu"),
                                            Text("翻: $han"),
                                            const SizedBox(height: 8),
                                            Text("$scoreText"),
                                          ],
                                        ),
                                      ),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () async {
                                          final record = {
                                            "tiles": jsonEncode(sortedClasses),
                                            "win_tile": handData['win_tile'],
                                            "melds": jsonEncode(handData['melds']),
                                            "han": han,
                                            "fu": fu,
                                            "yaku": jsonEncode(scoreResult['yaku']),
                                            "total_score": totalCost,
                                            "created_at": DateTime.now().toIso8601String()
                                          };

                                          await DatabaseHelper.instance.insertRecord(record);

                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text("紀錄已儲存"))
                                          );
                                        },
                                        child: const Text("儲存"),
                                      ),
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                        },
                                        child: const Text("關閉"),
                                      ),
                                    ],
                                  );
                                },
                              );

                              }).catchError((error) {
                                print("計算失敗: $error");
                              });
                            },
                      child: const Text("檢查手牌"),
                    ),
                    const SizedBox(width: 12),
                    // 自風
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          selfWind = nextWind(selfWind);
                        });
                      },
                      child: Text("自風: ${winds[selfWind - 27]}"),
                    ),
                    const SizedBox(width: 12),
                    // 場風
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          roundWind = nextWind(roundWind);
                        });
                      },
                      child: Text("場風: ${winds[roundWind - 27]}"),
                    ),
                    const SizedBox(width: 12),
                    // 自摸/榮和切換
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      onPressed: () {
                        setState(() {
                          is_tsumo = !is_tsumo;
                        });
                      },
                      child: Text(is_tsumo ? "自摸" : "榮和"),
                    ),
                    const SizedBox(width: 12),

                    // 其他設定
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
                      onPressed: () {
                        _showExtraSettings();
                      },
                      child: const Text("其他設定"),
                    ),
                    const SizedBox(width: 12),
                  
                    
                  ],
                ),
              ],
            ),
          ),
  );
}


  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    
    return Scaffold(
      appBar: AppBar(
  title: Text(
    _selectedIndex == 0
        ? "手牌偵測"
        : "歷史紀錄", 
  ),
  actions: _selectedIndex == 0
      ? [
          Row(
            children: [
              Text(
                isEditMode ? "編輯模式" : "選擇模式",
                style: const TextStyle(fontSize: 16),
              ),
              Switch(
                value: isEditMode,
                onChanged: (value) {
                  setState(() {
                    isEditMode = value;
                    selectedIndices.clear();
                  });
                },
                activeTrackColor: Colors.lightBlue,
                inactiveTrackColor: Colors.grey,
              )
            ],
          ),
        ]
      : [],
),
      



      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.green),
              child: Text('選單', style: TextStyle(color: Colors.white, fontSize: 24)),
            ),
            ListTile(
              title: const Text('手牌'),
              leading: const Icon(Icons.view_column),
              selected: _selectedIndex == 0,
              onTap: () => setState(() {
                _selectedIndex = 0;
                Navigator.pop(context);
              }),
            ),
            ListTile(
              title: const Text('歷史紀錄'),
              leading: const Icon(Icons.list),
              selected: _selectedIndex == 1,
              onTap: () => setState(() {
                _selectedIndex = 1;
                Navigator.pop(context);
              }),
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          Stack(
            children: [
              _handTilesPage(),

              if (showActionMenu)
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildActionButton("吃", Colors.green, _onChi),
                      _buildActionButton("碰", Colors.orange, _onPon),
                      _buildActionButton("槓", Colors.red, _onKan),
                      _buildActionButton("暗槓", Colors.purple, _onAnkan),
                    ],
                  ),
                ),
            ],
          ),

          RecordPage(),
        ],
      ),

      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(onPressed: _pickImage, child: const Icon(Icons.camera))
          : null,
    );
  }
}
