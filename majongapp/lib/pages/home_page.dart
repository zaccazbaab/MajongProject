import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/roboflow_service.dart';
import '../utils/tiles.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int? highlightedIndex; // 標記牌索引

  final ImagePicker picker = ImagePicker();
  final RoboflowService rfService = RoboflowService();

  Map<String, dynamic>? result;
  List<String> sortedClasses = [];

  // 排序方法
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

  // 彈出選牌視窗
  Future<String?> pickTileDialog(BuildContext context) {
    return showDialog<String>(
      context: context,
      barrierColor: Colors.black38,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black87,
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
                    final cls = entry.key;
                    final path = entry.value;
                    return GestureDetector(
                      onTap: () => Navigator.pop(context, cls),
                      child: Image.asset(
                        path,
                        fit: BoxFit.contain,
                      ),
                    );
                  }).toList(),
                )
              : const Center(
                  child: Text(
                    "沒有牌可以選擇",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
        ),
      ),
    );
  }

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
                  if (image != null) {
                    final res = await rfService.sendImageFile(image.path);
                    if (res != null) {
                      final classes = (res['outputs'][0]['output2']['predictions'] as List)
                          .map((p) => p['class'] as String)
                          .toList();
                      final sorted = sortTiles(classes).take(14).toList();
                      setState(() {
                        result = res;
                        sortedClasses = sorted;
                      });
                    }
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('從相簿選擇', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final res = await rfService.sendImageFile(image.path);
                    if (res != null) {
                      final classes = (res['outputs'][0]['output2']['predictions'] as List)
                          .map((p) => p['class'] as String)
                          .toList();
                      final sorted = sortTiles(classes).take(14).toList();
                      setState(() {
                        result = res;
                        sortedClasses = sorted;
                      });
                    }
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  @override
Widget build(BuildContext context) {
  return Scaffold(
    appBar: AppBar(title: const Text('麻將程式')),
    floatingActionButton: FloatingActionButton(
      onPressed: _pickImage,
      child: const Icon(Icons.camera),
    ),
    body: Center(
      child: result == null
          ? const Text(
              '等待使用者選擇照片',
              style: TextStyle(color: Colors.white),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  SizedBox(
                    height: MediaQuery.of(context).size.width / 10 * 1.5,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedClasses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (context, index) {
                        final cls = sortedClasses[index];
                        final path = classToFile[cls] ?? '';
                        return GestureDetector(
                          onTap: () async {
                            final newCls = await pickTileDialog(context);
                            if (newCls != null) {
                              setState(() {
                                sortedClasses[index] = newCls;
                                sortedClasses = sortTiles(sortedClasses);
                              });
                            }
                          },
                          onLongPress: () {
                            setState(() {
                              highlightedIndex = highlightedIndex == index ? null : index;
                            });
                          },
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              double screenWidth = MediaQuery.of(context).size.width;
                              double cardWidth = (screenWidth - 4 * 9 - 32) / 10;
                              double cardHeight = cardWidth * 1.5;

                              Widget tileWidget = path.isNotEmpty
                                  ? Image.asset(
                                      path,
                                      width: cardWidth,
                                      height: cardHeight,
                                      errorBuilder: (_, __, ___) {
                                        print('找不到資源: $path');
                                        return Container(
                                          width: cardWidth,
                                          height: cardHeight,
                                          color: Colors.grey,
                                        );
                                      },
                                    )
                                  : Container(
                                      width: cardWidth,
                                      height: cardHeight,
                                      color: Colors.transparent,
                                    );

                              // 標記紅框
                              if (highlightedIndex == index) {
                                tileWidget = Container(
                                  width: cardWidth,
                                  height: cardHeight,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.red, width: 3),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: tileWidget,
                                );
                              }

                              return tileWidget;
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  //手牌按鈕
                  ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[900], // 深紅色
                  ),
                  onPressed: () {
                    if (highlightedIndex == null) {
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text("提醒"),
                          content: const Text(
                            "請長按一張牌標記為最後摸牌！",
                            style: TextStyle(color: Colors.black), // 黑色文字
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text("OK"),
                            ),
                          ],
                        ),
                      );
                      return;
                    }

                    final handData = {
                      "tiles": sortedClasses,
                      "lastTile": sortedClasses[highlightedIndex!],
                    };

                    print("整手牌: ${handData['tiles']}");
                    print("最後摸牌: ${handData['lastTile']}");
                    // 可將 handData 傳給胡牌計算函數
                  },
                  child: const Text("檢查手牌"),
),
                ],
              ),
            ),
    ),
  );
}
}
