import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

class RecentEntriesScreen extends StatefulWidget {
  const RecentEntriesScreen({super.key});

  @override
  State<RecentEntriesScreen> createState() => _RecentEntriesScreenState();
}

class _RecentEntriesScreenState extends State<RecentEntriesScreen> {
  final box = Hive.box('entries');
  String? selectedBlock;
  String? selectedType;

  void _deleteEntry(int index) async {
    await box.deleteAt(index);
    
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text("Room entry deleted")));
    setState(() {});
  }

  // 🧮 Helper: Calculate estimated power usage
  double _calculatePower(List equipments) {
    double totalPower = 0;
    for (var e in equipments) {
      final qty = e['qty'] ?? 0;
      switch (e['type']) {
        case 'Light':
          totalPower += qty * 40;
          break;
        case 'Fan':
          totalPower += qty * 75;
          break;
        case 'AC':
          totalPower += qty * 1200;
          break;
        case 'TV':
          totalPower += qty * 150;
          break;
        default:
          totalPower += qty * 50;
      }
    }
    return totalPower;
  }

  @override
  Widget build(BuildContext context) {
    final blocks =
        box.values.map((e) => e['block'] as String?).whereType<String>().toSet();

    // Collect all equipment types
    final types = box.values
        .expand((e) => (e['equipments'] as List<dynamic>?)
                ?.map((eq) => eq['type'] as String?)
                .whereType<String>() ??
            [])
        .toSet();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text('Recent Entries',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),

          // 🟩 Filters Row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                Expanded(
                  child: _filterDropdown(
                    "Block",
                    blocks.toList().cast<String>(),
                    selectedBlock,
                    (v) => setState(() => selectedBlock = v == "All" ? null : v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _filterDropdown(
                    "Equipment",
                    types.toList().cast<String>(),
                    selectedType,
                    (v) => setState(() => selectedType = v == "All" ? null : v),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // 🧩 Room List
          Expanded(
            child: ValueListenableBuilder(
              valueListenable: box.listenable(),
              builder: (context, Box entries, _) {
                var filteredRooms = entries.values.toList();

                // Filter by Block
                if (selectedBlock != null) {
                  filteredRooms = filteredRooms
                      .where((e) => e['block'] == selectedBlock)
                      .toList();
                }

                // Filter by Equipment Type
                if (selectedType != null) {
                  filteredRooms = filteredRooms
                      .where((room) => (room['equipments'] as List<dynamic>?)
                              ?.any((eq) => eq['type'] == selectedType) ??
                          false)
                      .toList();
                }

                if (filteredRooms.isEmpty) {
                  return const Center(child: Text("No entries found"));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: filteredRooms.length,
                  itemBuilder: (context, index) {
                    final data = filteredRooms[index];
                    final equipments =
                        (data['equipments'] as List<dynamic>?)?.cast<Map>() ??
                            [];
                    final photoPath = data['photoPath'];
                    final totalPower = _calculatePower(equipments);
                    final equipmentCount = equipments.length;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.grey.withAlpha(31),
                              offset: const Offset(0, 4),
                              blurRadius: 8)
                        ],
                      ),
                      child: ExpansionTile(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                        leading: photoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.file(
                                  File(photoPath),
                                  width: 50,
                                  height: 50,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : const Icon(Icons.photo_outlined,
                                color: Colors.green, size: 40),
                        title: Text("${data['block']} - ${data['room']}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Text(
                          "Floor: ${data['floor'] ?? '-'} • $equipmentCount equipments • ${totalPower.toStringAsFixed(0)} W",
                          style: const TextStyle(color: Colors.black54),
                        ),
                        children: [
                          ...equipments.map((e) => ListTile(
                                leading: const Icon(Icons.settings,
                                    color: Colors.blueAccent),
                                title: Text(e['type'] ?? ''),
                                subtitle: Text(
                                    "${e['make']} • Qty: ${e['qty'] ?? 0}"),
                              )),
                          Padding(
                            padding:
                                const EdgeInsets.only(bottom: 12, right: 12),
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: const Icon(Icons.delete,
                                    color: Colors.red),
                                onPressed: () {
                                  final indexToDelete =
                                      box.values.toList().indexOf(data);
                                  _deleteEntry(indexToDelete);
                                },
                              ),
                            ),
                          )
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // 🟩 Filter Dropdown Widget
  Widget _filterDropdown(String label, List<String> items, String? selectedValue,
      Function(String?) onChanged) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 4))
        ],
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          hint: Text(label),
          value: selectedValue,
          isExpanded: true,
          onChanged: onChanged,
          items: ['All', ...items]
              .map((e) => DropdownMenuItem(value: e, child: Text(e)))
              .toList(),
        ),
      ),
    );
  }
}
