import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:syncfusion_flutter_xlsio/xlsio.dart' as xlsio;
import 'package:open_filex/open_filex.dart';

class ExportDataScreen extends StatelessWidget {
  const ExportDataScreen({super.key});

  /// ✅ Calculate power for equipment item
  double _equipmentPower(Map eq) {
    final qty = (eq['qty'] is num) ? (eq['qty'] as num).toDouble() : 0.0;
    switch (eq['type']) {
      case 'Light':
        return qty * 40;
      case 'Fan':
        return qty * 75;
      case 'AC':
        return qty * 1200;
      case 'TV':
        return qty * 150;
      default:
        return qty * 50;
    }
  }

  /// ✅ Export Excel
  Future<void> _exportToExcel(BuildContext context) async {
    final box = Hive.box('entries');

    if (box.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("No entries to export!")),
      );
      return;
    }

    final workbook = xlsio.Workbook();
    final sheet = workbook.worksheets[0];
    sheet.name = 'Energy Audit Data';

    // Header row
    final headers = [
      'Block',
      'Floor',
      'Room',
      'Equipment Type',
      'Make/Model',
      'Qty',
      'Power (W)',
      'Timestamp',
      'Photo'
    ];

    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.getRangeByIndex(1, i + 1);
      cell.setText(headers[i]);
      cell.cellStyle.bold = true;
      cell.cellStyle.backColor = '#E0E0E0';
    }

    int row = 2;

    // Iterate rooms
    for (var i = 0; i < box.length; i++) {
      final data = box.getAt(i);
      final block = data['block'] ?? '';
      final floor = data['floor'] ?? '';
      final room = data['room'] ?? '';
      final timestamp = data['timestamp'] ?? '';
      final photoPath = data['photoPath'];
      final eqList = (data['equipments'] as List?) ?? [];

      // Merge block, room cells vertically across equipment rows
      int startRow = row;
      for (var eq in eqList) {
        final eqMap = Map<String, dynamic>.from(eq);

        sheet.getRangeByIndex(row, 1).setText(block);
        sheet.getRangeByIndex(row, 2).setText(floor);
        sheet.getRangeByIndex(row, 3).setText(room);
        sheet.getRangeByIndex(row, 4).setText(eqMap['type'] ?? '');
        sheet.getRangeByIndex(row, 5).setText(eqMap['make'] ?? '');
        sheet.getRangeByIndex(row, 6)
            .setNumber((eqMap['qty'] ?? 0).toDouble());
        sheet.getRangeByIndex(row, 7)
            .setNumber(_equipmentPower(eqMap).toDouble());
        sheet.getRangeByIndex(row, 8).setText(timestamp);
        row++;
      }

      // Insert photo only once per room
      if (photoPath != null && File(photoPath).existsSync()) {
        final image = File(photoPath).readAsBytesSync();
        final picture = sheet.pictures.addStream(startRow, 9, image);
        picture.height = 80;
        picture.width = 80;
      }

      // Merge block, floor, room cells vertically if multiple equipments
      if (eqList.length > 1) {
        sheet.getRangeByIndex(startRow, 1, row - 1, 1).merge();
        sheet.getRangeByIndex(startRow, 2, row - 1, 2).merge();
        sheet.getRangeByIndex(startRow, 3, row - 1, 3).merge();
        sheet.getRangeByIndex(startRow, 8, row - 1, 8).merge();
      }
    }

    // Auto-fit columns
    for (int i = 1; i <= headers.length; i++) {
      sheet.autoFitColumn(i);
    }

    // Save file
    final bytes = workbook.saveAsStream();
    workbook.dispose();

    final directory =
        await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${directory.path}/Energy_Audit_Report.xlsx');
    await file.writeAsBytes(bytes, flush: true);

    // avoid using BuildContext across async gaps
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("✅ Excel saved at: ${file.path}")),
    );

    await OpenFilex.open(file.path);
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('entries');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Export Data',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box entries, _) {
          final totalRooms = entries.length;
          final blocks = entries.values.map((e) => e['block']).toSet();
          final totalBlocks = blocks.length;

          // Calculate total power correctly
          double totalPower = 0;
          for (var e in entries.values) {
            final eqList = (e['equipments'] as List?) ?? [];
            for (var eq in eqList) {
              totalPower += _equipmentPower(Map<String, dynamic>.from(eq));
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _gradientHeader(totalRooms, totalBlocks, totalPower, context),
                const SizedBox(height: 24),
                const Text(
                  "Block-wise Data",
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: Colors.black87),
                ),
                const SizedBox(height: 10),
                if (blocks.isEmpty)
                  const Text("No block data found.",
                      style: TextStyle(color: Colors.black54))
                else
                  Column(
                    children: blocks
                        .map((block) => _blockTile(block, entries))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _gradientHeader(
      int totalRooms, int totalBlocks, double totalPower, BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.green, Colors.teal],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.green.withAlpha(77), // 0.3 * 255 ≈ 77
              offset: const Offset(0, 6),
              blurRadius: 12)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Export Energy Audit Report",
              style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 20)),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoCard("Blocks", "$totalBlocks", Colors.white70),
              _infoCard("Rooms", "$totalRooms", Colors.white70),
              _infoCard(
                  "Power", "${totalPower.toStringAsFixed(0)} W", Colors.white70),
            ],
          ),
          const SizedBox(height: 24),
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.file_download, color: Colors.white),
              label: const Text("Download Excel",
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white.withAlpha(51), // 0.2 * 255 ≈ 51
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              ),
              onPressed: () => _exportToExcel(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoCard(String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: const TextStyle(fontSize: 14, color: Colors.white70)),
        Text(value,
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: Colors.white)),
      ],
    );
  }

  Widget _blockTile(String block, Box entries) {
    final blockEntries =
        entries.values.where((e) => e['block'] == block).toList();
    final totalRooms = blockEntries.length;

    double blockPower = 0;
    for (var room in blockEntries) {
      final eqList = (room['equipments'] as List?) ?? [];
      for (var eq in eqList) {
        blockPower += _equipmentPower(Map<String, dynamic>.from(eq));
      }
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withAlpha(38), // 0.15 * 255 ≈ 38
              offset: const Offset(0, 4),
              blurRadius: 6)
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
              child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(block,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 4),
              Text("Rooms: $totalRooms",
                  style: const TextStyle(color: Colors.black54)),
              Text("Power: ${blockPower.toStringAsFixed(0)} W",
                  style: const TextStyle(color: Colors.black54)),
            ],
          )),
          const Icon(Icons.file_download_outlined,
              color: Colors.green, size: 28),
        ],
      ),
    );
  }
}
