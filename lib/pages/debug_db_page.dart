import 'package:flutter/material.dart';
import 'package:sqflite/sqflite.dart';

import '../core/database/database_provider.dart';

class DebugDbPage extends StatefulWidget {
  const DebugDbPage({super.key});

  @override
  State<DebugDbPage> createState() => _DebugDbPageState();
}

class _DebugDbPageState extends State<DebugDbPage> {
  List<Map<String, dynamic>> rows = [];
  bool loading = false;

  @override
  void initState() {
    super.initState();
    loadRows();
  }

  Future<void> loadRows() async {
    setState(() => loading = true);

    final db = await DatabaseProvider.database;
    final data = await db.query("posts", orderBy: "id DESC");

    setState(() {
      rows = data;
      loading = false;
    });
  }

  Future<void> deleteRow(int id) async {
    final db = await DatabaseProvider.database;
    await db.delete("posts", where: "id = ?", whereArgs: [id]);
    await loadRows();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("SQLite Debug"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: loadRows,
          ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : rows.isEmpty
          ? const Center(child: Text("Database is empty"))
          : ListView.builder(
        itemCount: rows.length,
        itemBuilder: (context, index) {
          final row = rows[index];

          return Card(
            margin: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: ListTile(
              title: Text(
                "Post ID: ${row['id']}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                row.toString(),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => deleteRow(row['id']),
              ),
            ),
          );
        },
      ),
    );
  }
}
