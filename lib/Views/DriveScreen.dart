import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:nextconsult/Widgets/LocalExplorerScreen.dart';
import '../Controllers/Auth_Controller.dart';
import '../Helpers/GoogleSignIn.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({Key? key}) : super(key: key);

  @override
  State<UploadScreen> createState() => _DriveScreen();
}

class _DriveScreen extends State<UploadScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  List<drive.File> _driveFiles = [];
  bool _isLoading = false;
  bool _hasMore = true;
  String? _nextPageToken;
  String? _statusMessage;
  String _searchQuery = '';
  List<drive.File> _driveItems = [];

  String _currentFolderId = 'root';
  List<String> _folderStack = ['root'];
  final AuthController _authController = AuthController();

  final gridDelegate = const SliverGridDelegateWithFixedCrossAxisCount(
    crossAxisCount: 2,
    crossAxisSpacing: 8,
    mainAxisSpacing: 8,
    childAspectRatio: 0.9,
  );

  Future<void> _navigateToFolder(String folderId) async {
    setState(() {
      _currentFolderId = folderId;
      _folderStack.add(folderId);
      _nextPageToken = null;
      _driveItems.clear();
      _hasMore = true;
    });
    await _fetchDriveFiles();
  }

  void _navigateUp() {
    if (_folderStack.length > 1) {
      setState(() {
        _folderStack.removeLast();
        _currentFolderId = _folderStack.last;
        _nextPageToken = null;
        _driveItems.clear();
        _hasMore = true;
      });
      _fetchDriveFiles();
    }
  }

  Future<void> downloadFile(drive.File file) async {
    if (file.id == null || file.name == null) return;

    // Ask user for destination folder
    String? selectedDirectory = await FilePicker.platform.getDirectoryPath();
    if (selectedDirectory == null) return; // User canceled

    final parts = selectedDirectory.split('/');
    final seen = <String>{};
    final normalized = <String>[];
    for (final part in parts) {
      if (seen.contains(part) && part != '') break;
      seen.add(part);
      normalized.add(part);
    }
    selectedDirectory = normalized.join('/');

    setState(() {
      _isLoading = true;
      _statusMessage = 'Downloading ${file.name}...';
    });

    try {
      final driveApi = await getDriveApi();

      // Get the file media content
      final mediaStream =
          await driveApi.files.get(
                file.id!,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      // Create output file
      final outputPath = '$selectedDirectory/${file.name}';
      print("Output path: $outputPath");
      final outputFile = File(outputPath);
      final outputSink = outputFile.openWrite();

      await mediaStream.stream.pipe(outputSink);

      await outputSink.flush();
      await outputSink.close();

      setState(() {
        _statusMessage = '✅ Downloaded to $outputPath';
      });
    } catch (e) {
      print("Download error: $e");
      setState(() {
        _statusMessage = '❌ Download failed.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchDriveFiles();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    if (!_scrollController.hasClients) return;
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 100) {
      _fetchDriveFiles();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _uploadToDrive(String filePath) async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Uploading file...';
    });

    try {
      final driveApi = await getDriveApi();
      final file = File(filePath);
      final media = drive.Media(file.openRead(), await file.length());
      final driveFile =
          drive.File()
            ..name = file.path.split('/').last
            ..parents = [_currentFolderId];

      await driveApi.files.create(driveFile, uploadMedia: media);

      setState(() {
        _statusMessage = '✅ Upload successful!';
      });

      _refreshFileList();
    } catch (e) {
      print("Upload error: $e");
      setState(() {
        _statusMessage = '❌ Upload failed.';
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchDriveFiles({bool clear = false}) async {
    if (_isLoading || !_hasMore) return;

    setState(() => _isLoading = true);

    try {
      final driveApi = await getDriveApi();

      String query;
      if (_searchQuery.isNotEmpty) {
        query = "name contains '$_searchQuery' and trashed = false";
      } else {
        query = "'$_currentFolderId' in parents and trashed = false";
      }

      final fileList = await driveApi.files.list(
        spaces: 'drive',
        q: query,
        $fields: 'files(id,name,size,createdTime,mimeType),nextPageToken',
        pageSize: 20,
        pageToken: _nextPageToken,
      );

      setState(() {
        if (clear) {
          _driveItems = fileList.files ?? [];
        } else {
          _driveItems.addAll(fileList.files ?? []);
        }
        _nextPageToken = fileList.nextPageToken;
        _hasMore = _nextPageToken != null;
        _statusMessage = _driveItems.isEmpty ? 'No items found.' : null;
      });
    } catch (e) {
      print("Fetch error: $e");
      setState(() => _statusMessage = "❌ Failed to fetch items.");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Widget _buildBreadcrumbs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
      child: Row(
        children: [
          if (_currentFolderId != 'root')
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                setState(() {
                  _currentFolderId = 'root';
                  _folderStack = ['root'];
                  _nextPageToken = null;
                  _driveItems.clear();
                  _hasMore = true;
                });
                _fetchDriveFiles();
              },
              tooltip: 'Go to root',
            ),
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            onPressed: _folderStack.length > 1 ? _navigateUp : null,
            tooltip: 'Go up',
          ),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (int i = 0; i < _folderStack.length; i++)
                    Row(
                      children: [
                        if (i > 0) const Icon(Icons.chevron_right, size: 16),
                        GestureDetector(
                          onTap: () {
                            if (i < _folderStack.length - 1) {
                              setState(() {
                                _folderStack = _folderStack.sublist(0, i + 1);
                                _currentFolderId = _folderStack.last;
                                _nextPageToken = null;
                                _driveItems.clear();
                                _hasMore = true;
                              });
                              _fetchDriveFiles();
                            }
                          },
                          child: Text(
                            i == 0 ? 'My Drive' : 'Folder ${i + 1}',
                            style: TextStyle(
                              fontWeight:
                                  i == _folderStack.length - 1
                                      ? FontWeight.bold
                                      : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemTile(drive.File item) {
    final isFolder = item.mimeType == 'application/vnd.google-apps.folder';

    return Card(
      color: Colors.grey[100],
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.all(4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isFolder) {
            _navigateToFolder(item.id!);
          } else {
            downloadFile(item);
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Icon(
                  isFolder ? Icons.folder : Icons.insert_drive_file,
                  size: 48,
                  color: isFolder ? Colors.amber : Colors.blueAccent,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                item.name ?? 'Unnamed item',
                style: const TextStyle(fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (!isFolder) ...[
                Text(
                  "Size: ${formatBytes(item.size)}",
                  style: const TextStyle(fontSize: 12),
                ),
                Text(
                  "Created: ${formatDate(item.createdTime)}",
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _refreshFileList() {
    setState(() {
      _nextPageToken = null;
      _driveFiles.clear();
      _hasMore = true;
    });
    _fetchDriveFiles(clear: true);
  }

  String formatBytes(String? bytes) {
    if (bytes == null) return "Unknown";
    int size = int.tryParse(bytes) ?? 0;
    if (size <= 0) return "0 B";
    const suffixes = ["B", "KB", "MB", "GB", "TB"];
    int i = 0;
    while (size >= 1024 && i < suffixes.length - 1) {
      size = size ~/ 1024;
      i++;
    }
    return "$size ${suffixes[i]}";
  }

  String formatDate(DateTime? date) {
    if (date == null) return "Unknown date";
    return DateFormat('dd MMM yyyy - HH:mm').format(date.toLocal());
  }

  Widget _buildFileTile(drive.File file) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: ListTile(
        leading: const Icon(
          Icons.insert_drive_file,
          size: 30,
          color: Colors.blueAccent,
        ),
        title: Text(file.name ?? 'Unnamed file'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Size: ${formatBytes(file.size)}"),
            Text("Created: ${formatDate(file.createdTime)}"),
            Text(
              "ID: ${file.id}",
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        isThreeLine: true,
        onTap: () => downloadFile(file),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search files...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon:
              _searchQuery.isNotEmpty
                  ? IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _searchQuery = '';
                      _refreshFileList();
                    },
                  )
                  : null,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
        onSubmitted: (value) {
          _searchQuery = value.trim();
          _refreshFileList();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        backgroundColor: Colors.white,
        child: Column(
          children: [
            AppBar(
              backgroundColor: Colors.blueAccent,
              title: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Colors.white,

                    child: Image.asset("assets/images/user.png", scale: 2),
                  ),
                  const SizedBox(width: 10),
                  Text("Mohamed Ben Rabie",style: TextStyle(color: Colors.white),),
                  Spacer(),
                  IconButton(
                    color: Colors.white,
                    icon: Icon(Icons.logout),
                    onPressed: () => _authController.logout(context),
                  ),
                ],
              ),

              automaticallyImplyLeading: false,
            ),

            Expanded(
              child: ListView.builder(
                itemCount: _folderStack.length,
                itemBuilder: (context, index) {
                  final folderId = _folderStack[index];
                  return Column(
                    children: [
                      Divider(),
                      ListTile(
                        title: Text(folderId),
                        onTap: () => _navigateToFolder(folderId),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.blueAccent,
        title: Row(
          children: [
            const Text(
              'Google Drive Files',
              style: TextStyle(color: Colors.white),
            ),
            Spacer(),
            IconButton(
              color: Colors.white,
              onPressed:
                  _isLoading
                      ? null
                      : () async {
                        final result = await FilePicker.platform.pickFiles();
                        if (result != null &&
                            result.files.single.path != null) {
                          await _uploadToDrive(result.files.single.path!);
                        }
                      },
              icon: const Icon(Icons.upload),
            ),
            IconButton(
              color: Colors.white,

              onPressed: _isLoading ? null : _refreshFileList,
              icon: const Icon(Icons.refresh),
              tooltip: "Refresh Files",
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          _buildBreadcrumbs(),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 12),
            child: const SizedBox(width: 10),
          ),
          if (_statusMessage != null)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                _statusMessage!,
                style: TextStyle(
                  color:
                      _statusMessage!.contains("❌") ? Colors.red : Colors.green,
                ),
              ),
            ),
          const Divider(),
          Expanded(
            child: GridView.builder(
              controller: _scrollController,
              gridDelegate: gridDelegate,
              padding: const EdgeInsets.all(8),
              itemCount: _driveItems.length + (_hasMore ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < _driveItems.length) {
                  return _buildItemTile(_driveItems[index]);
                } else {
                  return Align(alignment: Alignment.center,child: CircularProgressIndicator());
                }
              },
            ),
          ),
        ],
      ),
    );
  }
}
