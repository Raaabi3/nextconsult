import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class LocalExplorerScreen extends StatefulWidget {
  const LocalExplorerScreen({Key? key, required String filePath, required Null Function() onTap}) : super(key: key);

  @override
  _LocalExplorerScreenState createState() => _LocalExplorerScreenState();
}

class _LocalExplorerScreenState extends State<LocalExplorerScreen> {
  late Directory currentDir;
  List<FileSystemEntity> items = [];

  @override
  void initState() {
    super.initState();
    _initDir();
  }

  Future<void> _initDir() async {
    final status = await Permission.storage.request();
    if (!status.isGranted) {
      return;
    }

    Directory dir = Directory('/storage/emulated/0'); // Start from internal storage
    if (!(await dir.exists())) {
      dir = await getApplicationDocumentsDirectory(); // fallback
    }

    setState(() {
      currentDir = dir;
    });

    _listFiles(dir);
  }

  void _listFiles(Directory dir) {
    final children = dir.listSync()..sort((a, b) => a.path.compareTo(b.path));
    setState(() {
      currentDir = dir;
      items = children;
    });
  }

  void _navigateTo(FileSystemEntity entity) {
    if (entity is Directory) {
      _listFiles(entity);
    } else if (entity is File) {
      // open file / preview / whatever you want
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("Tapped file: ${entity.path}"),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(currentDir.path),
        leading: Navigator.canPop(context)
            ? BackButton(onPressed: () {
                Navigator.pop(context);
              })
            : null,
      ),
      body: ListView.builder(
        itemCount: items.length,
        itemBuilder: (_, index) {
          final item = items[index];
          final isDir = FileSystemEntity.isDirectorySync(item.path);
          return ListTile(
            leading: Icon(isDir ? Icons.folder : Icons.insert_drive_file),
            title: Text(item.path.split('/').last),
            onTap: () => _navigateTo(item),
          );
        },
      ),
    );
  }
}
