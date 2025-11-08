import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/roboflow_service.dart';
import '../utils/tiles.dart';
import '../utils/image_utils.dart';
import 'record_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  final ImagePicker picker = ImagePicker();
  final RoboflowService rfService = RoboflowService();
  Map<String, dynamic>? result;
  List<String> sortedClasses = [];
  int doraCount = 0; // 寶牌數量

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
      sortedClasses = [];
    });
  }
}



  Widget _handTilesPage() {
    double screenWidth = MediaQuery.of(context).size.width;
    double cardWidth = (screenWidth - 4 * 9 - 32) / 10;
    double cardHeight = cardWidth * 1.5;

    return Center(
      child: result == null
          ? const Text('等待使用者選擇照片', style: TextStyle(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: cardHeight,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: sortedClasses.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 4),
                      itemBuilder: (_, index) {
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
                          child: path.isNotEmpty
                              ? Image.asset(path, width: cardWidth, height: cardHeight)
                              : Container(width: cardWidth, height: cardHeight, color: Colors.grey),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
                    onPressed: sortedClasses.isEmpty ? null : () {
                      final handData = {
                        "tiles": sortedClasses,
                        "dora": doraCount,
                      };
                      print("整手牌: ${handData['tiles']}");
                      print("寶牌數: ${handData['dora']}");
                      // TODO: 呼叫點數計算模組
                    },
                    child: const Text("檢查手牌"),
                  ),
                ],
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("麻將程式")),
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
          _handTilesPage(),
          const RecordPage(),
        ],
      ),
      floatingActionButton: _selectedIndex == 0
          ? FloatingActionButton(onPressed: _pickImage, child: const Icon(Icons.camera))
          : null,
    );
  }
}
