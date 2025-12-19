import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  /// ✅ Safely compute power for one equipment
double _powerForEquipment(Map e) {
  final qty = (e['qty'] is num)
      ? (e['qty'] as num).toDouble()
      : double.tryParse(e['qty']?.toString() ?? '0') ?? 0.0;

  // ✅ Get wattage — prefer user input, else fallback
  double wattage = 0.0;

  if (e.containsKey('wattage') && e['wattage'] != null) {
    wattage = (e['wattage'] is num)
        ? (e['wattage'] as num).toDouble()
        : double.tryParse(e['wattage'].toString()) ?? 0.0;
  }

  // ⚡ Default fallback if wattage is not provided
  if (wattage == 0.0) {
    switch (e['type']) {
      case 'Light':
        wattage = 40.0;
        break;
      case 'Fan':
        wattage = 75.0;
        break;
      case 'AC':
        wattage = 1200.0;
        break;
      case 'TV':
        wattage = 150.0;
        break;
      default:
        wattage = 50.0;
        break;
    }
  }

  return qty * wattage;
}


  /// ✅ Compute total power for one room
  double _roomPower(List eqList) {
    double total = 0.0;
    for (var eq in eqList) {
      if (eq is Map) {
        total += _powerForEquipment(Map<String, dynamic>.from(eq));
      }
    }
    return total;
  }

  @override
  Widget build(BuildContext context) {
    final box = Hive.box('entries');

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Dashboard',
                style: TextStyle(
                    color: Colors.green, fontWeight: FontWeight.bold)),
            Text('Campus Energy Audit',
                style: TextStyle(color: Colors.black54, fontSize: 14)),
          ],
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box entries, _) {
          if (entries.isEmpty) {
            return const Center(
              child: Text("No data yet. Add room entries to begin."),
            );
          }

          final rooms = entries.values.toList();

          // 🏢 Unique blocks
          final blocks = rooms.map((e) => e['block']).toSet();

          double totalPower = 0.0;
          int totalEquipments = 0;
          int totalRooms = rooms.length;

          Map<String, double> blockPower = {};
          Map<String, int> blockRooms = {};

          for (var room in rooms) {
            final eqList = (room['equipments'] as List?) ?? [];
            totalEquipments += eqList.length;

            final roomPower = _roomPower(eqList);
            totalPower += roomPower;

            final block = (room['block'] ?? 'Unknown').toString();
            blockPower[block] = (blockPower[block] ?? 0.0) + roomPower;
            blockRooms[block] = (blockRooms[block] ?? 0) + 1;
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _summaryCard(
                        "Buildings",
                        "${blocks.length}",
                        Icons.apartment,
                        Colors.green,
                      ),
                    ),
                    Expanded(
                      child: _summaryCard(
                        "Rooms Audited",
                        "$totalRooms",
                        Icons.meeting_room,
                        Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ⚡ Estimated Power Usage
                _energyCard(totalPower, totalEquipments),

                const SizedBox(height: 20),

                // 🧱 Block-wise Completion
                _blockProgressCard(blockPower, blockRooms, totalPower),
              ],
            ),
          );
        },
      ),
    );
  }

  /// 🏷️ Summary Card
  Widget _summaryCard(
      String title, String value, IconData icon, Color color) {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 30),
          const SizedBox(height: 8),
          Text(value,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold)),
          Text(title, style: const TextStyle(color: Colors.white70)),
        ],
      ),
    );
  }

  /// ⚡ EPU Card
  Widget _energyCard(double totalPower, int equipments) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.orange.withValues(alpha: 0.15),
              offset: const Offset(0, 3),
              blurRadius: 6)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.flash_on, color: Colors.orange),
              SizedBox(width: 8),
              Text("Estimated Power Usage",
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 10),
          Text("${totalPower.toStringAsFixed(1)} W",
              style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange)),
          Text("Across $equipments equipments",
              style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  /// 🧱 Block-wise Completion Card (20 rooms = 100%)
  Widget _blockProgressCard(
      Map<String, double> blockPower,
      Map<String, int> blockRooms,
      double totalPower) {
    if (blockPower.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withValues(alpha: 0.15),
                offset: const Offset(0, 4),
                blurRadius: 8)
          ],
        ),
        child: const Center(
          child: Text("No blocks found.",
              style: TextStyle(color: Colors.black54)),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.15),
              offset: const Offset(0, 4),
              blurRadius: 8)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Block-wise Completion (Target: 20 rooms per block)",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          ...blockPower.entries.map((e) {
            final blockName = e.key;
            final blockP = e.value;
            final completedRooms = blockRooms[blockName] ?? 0;
            final percent = (completedRooms / 20).clamp(0.0, 1.0);
            final displayPercent = (percent * 100).toStringAsFixed(0);

            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(blockName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w500, fontSize: 15)),
                      Text("$completedRooms / 20 rooms ($displayPercent%)",
                          style: const TextStyle(color: Colors.green)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: percent,
                    color: Colors.green,
                    backgroundColor: Colors.grey.shade300,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "Power Usage: ${blockP.toStringAsFixed(1)} W",
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
