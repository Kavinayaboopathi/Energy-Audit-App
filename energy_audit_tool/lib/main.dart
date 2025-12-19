import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/dashboard.dart';
import 'screens/add_entry.dart';
import 'screens/export_data.dart';
import 'screens/recent_entries.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for offline storage
  await Hive.initFlutter();
  await Hive.openBox('entries'); // local storage

  runApp(const EnergyAuditApp());
}

class EnergyAuditApp extends StatefulWidget {
  const EnergyAuditApp({super.key});

  @override
  State<EnergyAuditApp> createState() => _EnergyAuditAppState();
}

class _EnergyAuditAppState extends State<EnergyAuditApp> {
  int _selectedIndex = 0;

  // ✅ Add all pages
  final List<Widget> _pages = const [
    DashboardScreen(),
    AddEntryScreen(),
    RecentEntriesScreen(),
    ExportDataScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Energy Audit Tool',
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.green,
        fontFamily: 'Roboto',
      ),
      home: Scaffold(
        body: _pages[_selectedIndex],
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => setState(() => _selectedIndex = i),
          destinations: const [
            NavigationDestination(icon: Icon(Icons.home), label: "Home"),
            NavigationDestination(icon: Icon(Icons.add), label: "Add"),
            NavigationDestination(icon: Icon(Icons.list), label: "Entries"),
            NavigationDestination(
                icon: Icon(Icons.file_download), label: "Export"),
          ],
        ),
      ),
    );
  }
}
