import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class HistoryPage extends StatefulWidget {
  @override
  _HistoryPageState createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late Future<List<File>> _csvFiles;

  @override
  void initState() {
    super.initState();
    _csvFiles = _getCsvFiles();
  }

  /// ✅ Get all .csv files in the app storage
  Future<List<File>> _getCsvFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    List<FileSystemEntity> files = directory.listSync();

    return files
        .where((file) => file.path.endsWith('.csv'))
        .map((file) => File(file.path))
        .toList();
  }

  /// ✅ Delete a selected file
  Future<void> _deleteFile(File file) async {
    if (await file.exists()) {
      await file.delete();
      setState(() {
        _csvFiles = _getCsvFiles(); // Refresh list after deletion
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Deleted: ${file.path.split('/').last}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('History')),
      body: FutureBuilder<List<File>>(
        future: _csvFiles,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No CSV files found.'));
          }

          List<File> csvFiles = snapshot.data!;

          return ListView.builder(
            itemCount: csvFiles.length,
            itemBuilder: (context, index) {
              final file = csvFiles[index];
              return ListTile(
                title: Text(file.path.split('/').last),
                subtitle: Text("Tap to open"),
                leading: Icon(Icons.insert_drive_file),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _deleteFile(file);
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
