import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/roboflow_service.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _pickImage(BuildContext context) async {
    final ImagePicker picker = ImagePicker();
    final RoboflowService rfService = RoboflowService();

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
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    final result = await rfService.sendImage(image.path);
                    print("辨識結果: $result");
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo),
                title: const Text('從相簿選擇', style: TextStyle(color: Colors.black)),
                onTap: () async {
                  Navigator.pop(ctx);
                  final XFile? image =
                      await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    final result = await rfService.sendImage(image.path);
                    print("辨識結果: $result");
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('麻將程式')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _pickImage(context),
        child: const Icon(Icons.camera), // 相機圖示
      ),
      body: const Center(
        child: Text(
          '等待使用者選擇照片',
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }
}
