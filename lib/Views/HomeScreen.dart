import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<File> downloadedFiles = [];
  bool isMonitoring = false;
  
  @override
  void initState() {
    super.initState();
    _initFileSystem();
  }

  Future<void> _initFileSystem() async {
    if (await _requestStoragePermission()) {
      await _loadSavedFiles();
      _startMonitoringDownloads();
    }
  }

  Future<bool> _requestStoragePermission() async {
    final status = await Permission.storage.request();
    return status.isGranted;
  }

  Future<void> _loadSavedFiles() async {
    final prefs = await SharedPreferences.getInstance();
    final filePaths = prefs.getStringList('savedFiles') ?? [];
    final existingFiles = <File>[];

    for (final path in filePaths) {
      final file = File(path);
      if (await file.exists()) {
        existingFiles.add(file);
      }
    }

    setState(() {
      downloadedFiles = existingFiles;
    });
  }

  Future<void> _startMonitoringDownloads() async {
    if (isMonitoring) return;
    
    setState(() => isMonitoring = true);
    
    watchDownloadsFolder((newFile) async {
      if (!downloadedFiles.any((f) => f.path == newFile.path)) {
        await _saveNewFile(newFile);
        setState(() => downloadedFiles.add(newFile));
      }
    });
  }

  Future<void> _saveNewFile(File file) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFiles = prefs.getStringList('savedFiles') ?? [];
    currentFiles.add(file.path);
    await prefs.setStringList('savedFiles', currentFiles);
  }

  // Open Google Drive in browser
  Future<void> openDrive() async {
    final Uri driveUri = Uri.parse('https://drive.google.com/drive/my-drive');
    if (!await launchUrl(driveUri, mode: LaunchMode.externalApplication)) {
      _showError('Could not launch Google Drive');
    }
  }

  // Monitor downloads folder
  void watchDownloadsFolder(Function(File) onNewFile) async {
    final downloadsPath = await getDownloadsDirectory();
    final dir = Directory(downloadsPath);

    List<String> existingFiles = dir.listSync()
      .where((e) => e is File)
      .map((e) => e.path)
      .toList();

    dir.watch().listen((event) {
      if (event.type == FileSystemEvent.create) {
        final newFile = File(event.path);
        if (!existingFiles.contains(newFile.path)) {
          existingFiles.add(newFile.path);
          onNewFile(newFile);
        }
      }
    });
  }

  // Get downloads directory path
  Future<String> getDownloadsDirectory() async {
    if (Platform.isAndroid) {
      Directory dir = Directory('/storage/emulated/0/Download');
      if (!await dir.exists()) {
        dir = Directory('/sdcard/Download');
      }
      return dir.path;
    } else if (Platform.isIOS) {
      final dir = await getApplicationDocumentsDirectory();
      return dir.path;
    }
    return await getDownloadsDirectory();
  }

  // File opening logic with both external and internal options
  Future<void> _openFile(File file, {bool forceInternal = false}) async {
    try {
      if (!await file.exists()) {
        _showError("File not found: ${file.path}");
        return;
      }

      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      
      // For PDFs, we can choose between internal and external viewers
      if (mimeType == 'application/pdf' && !forceInternal) {
        final shouldOpenInternally = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Open PDF'),
            content: const Text('How would you like to open this PDF?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('External App'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Internal Viewer'),
              ),
            ],
          ),
        ) ?? false;

        if (shouldOpenInternally) {
          _openPdfInternally(file);
          return;
        }
      }

      // Open with external app
      final result = await OpenFile.open(file.path, type: mimeType);
      
      if (result.type != ResultType.done) {
        _handleOpenFileError(result, file);
      }
    } catch (e) {
      _showError("Error opening file: ${e.toString()}");
    }
  }

  // Internal PDF viewer
  void _openPdfInternally(File file) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PdfViewerScreen(filePath: file.path),
      ),
    );
  }

  void _handleOpenFileError(OpenResult result, File file) {
    String errorMessage;
    
    switch (result.type) {
      case ResultType.noAppToOpen:
        errorMessage = "No app found to open this file type";
        break;
      case ResultType.fileNotFound:
        errorMessage = "File not found";
        break;
      case ResultType.permissionDenied:
        errorMessage = "Permission denied";
        break;
      default:
        errorMessage = "Error opening file";
    }

    _showError("$errorMessage: ${file.path}");
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  Future<void> _pickFiles() async {
    final result = await FilePicker.platform.pickFiles(allowMultiple: true);
    if (result != null) {
      final files = result.paths.map((path) => File(path!)).toList();
      await _saveFiles(files);
    }
  }

  Future<void> _saveFiles(List<File> files) async {
    final prefs = await SharedPreferences.getInstance();
    final currentFiles = prefs.getStringList('savedFiles') ?? [];
    
    for (final file in files) {
      if (!currentFiles.contains(file.path)) {
        currentFiles.add(file.path);
      }
    }

    await prefs.setStringList('savedFiles', currentFiles);
    await _loadSavedFiles();
  }

  Future<void> _deleteFile(int index) async {
    final file = downloadedFiles[index];
    await file.delete();
    
    final prefs = await SharedPreferences.getInstance();
    final currentFiles = prefs.getStringList('savedFiles') ?? [];
    currentFiles.remove(file.path);
    
    await prefs.setStringList('savedFiles', currentFiles);
    setState(() => downloadedFiles.removeAt(index));
  }

  Future<void> _renameFile(int index) async {
    final file = downloadedFiles[index];
    final newName = await showDialog<String>(
      context: context,
      builder: (context) => _RenameDialog(fileName: file.path.split('/').last),
    );

    if (newName != null && newName.isNotEmpty) {
      final newPath = '${file.parent.path}/$newName';
      final newFile = await file.rename(newPath);
      
      final prefs = await SharedPreferences.getInstance();
      final currentFiles = prefs.getStringList('savedFiles') ?? [];
      final fileIndex = currentFiles.indexOf(file.path);
      
      if (fileIndex != -1) {
        currentFiles[fileIndex] = newPath;
        await prefs.setStringList('savedFiles', currentFiles);
        setState(() => downloadedFiles[index] = newFile);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('File Manager'),
        actions: [
          IconButton(
            icon: const Icon(Icons.cloud),
            onPressed: openDrive,
            tooltip: 'Open Google Drive',
          ),
        ],
      ),
      body: Column(
        children: [
          ElevatedButton(
            onPressed: _pickFiles,
            child: const Text('Select Files'),
          ),
          if (isMonitoring)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: const [
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                  SizedBox(width: 4),
                  Text('Monitoring downloads folder'),
                ],
              ),
            ),
          Expanded(
            child: downloadedFiles.isEmpty
                ? const Center(child: Text('No files available'))
                : ListView.builder(
                    itemCount: downloadedFiles.length,
                    itemBuilder: (context, index) {
                      final file = downloadedFiles[index];
                      return ListTile(
                        leading: Icon(
                          _getFileIcon(file.path),
                          color: Theme.of(context).primaryColor,
                        ),
                        title: Text(file.path.split('/').last),
                        subtitle: Text(file.path),
                        onTap: () => _openFile(file),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) async {
                            if (value == 'delete') {
                              await _deleteFile(index);
                            } else if (value == 'rename') {
                              await _renameFile(index);
                            } else if (value == 'open') {
                              await _openFile(file);
                            } else if (value == 'open_internal' && 
                                file.path.toLowerCase().endsWith('.pdf')) {
                              _openPdfInternally(file);
                            }
                          },
                          itemBuilder: (context) => [
                            const PopupMenuItem(
                              value: 'open',
                              child: Text('Open'),
                            ),
                            if (file.path.toLowerCase().endsWith('.pdf'))
                              const PopupMenuItem(
                                value: 'open_internal',
                                child: Text('Open in PDF Viewer'),
                              ),
                            const PopupMenuItem(
                              value: 'rename',
                              child: Text('Rename'),
                            ),
                            const PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  IconData _getFileIcon(String path) {
    final extension = path.split('.').last.toLowerCase();
    
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'jpg':
      case 'png':
      case 'jpeg':
      case 'gif':
        return Icons.image;
      case 'mp3':
      case 'wav':
        return Icons.audiotrack;
      case 'mp4':
      case 'mov':
      case 'avi':
        return Icons.videocam;
      default:
        return Icons.insert_drive_file;
    }
  }
}

class _RenameDialog extends StatelessWidget {
  final String fileName;
  final TextEditingController _controller;

  _RenameDialog({required this.fileName})
      : _controller = TextEditingController(text: fileName);

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Rename File'),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: const InputDecoration(
          hintText: 'Enter new file name',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, _controller.text.trim()),
          child: const Text('Save'),
        ),
      ],
    );
  }
}

class PdfViewerScreen extends StatelessWidget {
  final String filePath;

  const PdfViewerScreen({super.key, required this.filePath});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(filePath.split('/').last)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.picture_as_pdf, size: 100),
            const SizedBox(height: 20),
            Text('PDF Viewer: ${filePath.split('/').last}'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => OpenFile.open(filePath),
              child: const Text('Open in External App'),
            ),
          ],
        ),
      ),
    );
  }
}