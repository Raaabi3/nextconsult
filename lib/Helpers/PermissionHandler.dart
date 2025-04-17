import 'package:permission_handler/permission_handler.dart';

Future<void> requestStoragePermission() async {
  if (!await Permission.storage.request().isGranted) {
    print('Storage permission denied');
  }
}
