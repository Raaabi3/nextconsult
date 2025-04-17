import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';

class FileHandler {
  static Future<String> get _localPath async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  static Future<File> _localFile(String filename) async {
    final path = await _localPath;
    return File('$path/$filename');
  }

  static Future<File> saveFile(Uint8List bytes, String filename) async {
    final file = await _localFile(filename);
    return file.writeAsBytes(bytes);
  }

  static Future<Uint8List?> readFile(String filename) async {
    try {
      final file = await _localFile(filename);
      return await file.readAsBytes();
    } catch (e) {
      return null;
    }
  }

  static Future<bool> deleteFile(String filename) async {
    try {
      final file = await _localFile(filename);
      await file.delete();
      return true;
    } catch (e) {
      return false;
    }
  }
}