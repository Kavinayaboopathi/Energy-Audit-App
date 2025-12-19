import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'qr_scanner.dart';

class AddEntryScreen extends StatefulWidget {
  const AddEntryScreen({super.key});

  @override
  State<AddEntryScreen> createState() => _AddEntryScreenState();
}

class _AddEntryScreenState extends State<AddEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  String? buildingCategory;
  String? block;
  String? floor;
  String? room;
  File? _imageFile;
  List<Map<String, dynamic>> equipments = [];

  final _roomController = TextEditingController();
  final ImagePicker _picker = ImagePicker();

  // ✅ Complete building data organized by category
  final Map<String, Map<String, Map<String, dynamic>>> _allBuildingsData = {
    'ACADEMIC BUILDING': {
      'A-Block': {'floors': 3, 'area': 6734.2},
      'B-Block': {'floors': 3, 'area': 6093.97},
      'C-Block': {'floors': 3, 'area': 8427.94},
      'D-Block': {'floors': 3, 'area': 6261.0},
      'E-Block': {'floors': 3, 'area': 6065.9},
      'F-Block': {'floors': 3, 'area': 7587.9},
      'MVB': {'floors': 4, 'area': 27119.32},
      'Physics and Chemistry Lab': {'floors': 3, 'area': 1356.63},
      'Basic Workshop': {'floors': 1, 'area': 1054.9},
      'Structural Laboratory': {'floors': 2, 'area': 671.15},
      'Tamil Library': {'floors': 1, 'area': 1982.2},
    },
    'ASSEMBLY BUILDINGS': {
      'Ramananda Adigaalar Auditorium': {'floors': 2, 'area': 1579.15},
      'Dhyana Mandapam': {'floors': 1, 'area': 187.63},
      'East Kore/KLCAS Seminar Hall': {'floors': 1, 'area': 641.5},
    },
    'HOSTEL BUILDING': {
      'Vallar Maiyam': {'floors': 2, 'area': 4090.5},
      'Boys Hostel 1': {'floors': 4, 'area': 2550.8},
      'Boys Hostel 2': {'floors': 4, 'area': 2831.68},
      'Boys Hostel 3': {'floors': 3, 'area': 5347.8},
      'Boys Hostel 4': {'floors': 3, 'area': 4204.2},
      'Boys Hostel 5': {'floors': 4, 'area': 3046.4},
      'Boys Hostel 6': {'floors': 4, 'area': 3046.4},
      'M-Gateway': {'floors': 2, 'area': 1117.04},
      'Girls Hostel A': {'floors': 3, 'area': 6371.7},
      'Girls Hostel B': {'floors': 3, 'area': 3304.5},
      'Girls Hostel C': {'floors': 4, 'area': 2769.32},
      'Sardha Mayiam': {'floors': 3, 'area': 4173.99},
      'W-Gateway': {'floors': 1, 'area': 21.7},
    },
    'CANTEEN BUILDING': {
      'Bakery': {'floors': 1, 'area': 92.18},
      'Campus Dinning': {'floors': 1, 'area': 334.6},
      'Commercial cum Storage': {'floors': 1, 'area': 161.5},
      'Kore Canteen': {'floors': 2, 'area': 1487.82},
      'KS Café Boys': {'floors': 1, 'area': 118.85},
    },
    'SPORTS & ACTIVITY': {
      'K Mart': {'floors': 2, 'area': 505.0},
      'Kraft - Gym': {'floors': 1, 'area': 605.0},
    },
    'OTHER BUILDINGS': {
      'Medical Centre': {'floors': 1, 'area': 303.43},
      'Power House 1': {'floors': 1, 'area': 342.53},
      'Power House 2': {'floors': 1, 'area': 342.53},
      'Power House 3': {'floors': 1, 'area': 342.53},
      'Power House 4': {'floors': 1, 'area': 342.53},
      'TV Hall (Boys)': {'floors': 1, 'area': 84.0},
      'TV Hall (Girls)': {'floors': 1, 'area': 84.0},
    },
    'RESIDENTIAL & QUARTERS BUILDING': {
      'Guest House (Main Gate)': {'floors': 2, 'area': 178.27},
      'New Guest House': {'floors': 2, 'area': 2183.0},
      'Staff Quarters A': {'floors': 2, 'area': 430.0},
      'Staff Quarters B': {'floors': 2, 'area': 430.0},
      'Staff Quarters C': {'floors': 2, 'area': 590.0},
      'Staff Quarters D': {'floors': 2, 'area': 564.0},
      'Staff Quarters E': {'floors': 2, 'area': 564.0},
    },
  };

  // ✅ Expanded equipment types
  final List<String> _types = [
    'Light',
    'Fan',
    'AC',
    'TV',
    'Projector',
    'Desktop PC',
    'Laptop',
    'Water Dispenser',
    'Printer',
    'Scanner',
    'Photocopier',
    'Smart Board',
    'Speaker System',
    'CCTV Camera',
    'Switch/Router',
    'Refrigerator',
    'Microwave',
    'Water Heater',
    'Exhaust Fan',
    'Other'
  ];

  // ✅ NEW: Make/Model options for each equipment type
  final Map<String, List<String>> _makeModels = {
    'Light': [
      'Philips – Stellar Bright 12W LED',
      'Syska – SSK-SRL 15W Slim Panel',
      'Wipro – Garnet DL01 12W',
      'Havells – Trim LED Panel 18W',
      'Crompton – Star Shine 9W LED',
      'Other'
    ],
    'Fan': [
      'Havells – Stealth Air',
      'Crompton – Aura Prime',
      'Usha – Striker Galaxy',
      'Orient – Aero Slim',
      'Bajaj – Frore 1200mm',
      'Other'
    ],
    'AC': [
      'Daikin – FTKP Series',
      'LG – Dual Inverter RS-Q19',
      'Voltas – 183V Vectra',
      'Samsung – AR18 Inverter Series',
      'Blue Star – IA312YNU',
      'Other'
    ],
    'TV': [
      'Samsung – Series 7 Smart TV',
      'LG – 43UQ7500 UHD',
      'Sony – Bravia KD-43X80K',
      'Mi – 5X Android TV',
      'TCL – P735 4K',
      'Other'
    ],
    'Projector': [
      'Epson – EB-S41',
      'BenQ – MS550',
      'Sony – VPL-DX221',
      'ViewSonic – PA503S',
      'LG – PH550G',
      'Other'
    ],
    'Desktop PC': [
      'Dell – OptiPlex 3080',
      'HP – ProDesk 400 G7',
      'Lenovo – ThinkCentre M720s',
      'Acer – Veriton S2680',
      'ASUS – ExpertCenter D500',
      'Other'
    ],
    'Laptop': [
      'Dell – Latitude 3420',
      'HP – ProBook 440 G8',
      'Lenovo – ThinkPad E14',
      'ASUS – VivoBook 15 X1502',
      'Acer – Aspire 7',
      'Other'
    ],
    'Water Dispenser': [
      'Blue Star – BWD3FMRGA',
      'Voltas – Mini Magic Pure-T',
      'Usha – Instafresh UD101',
      'Atlantis – Table Top Frosty',
      'Cunhee – WD25 Series',
      'Other'
    ],
    'Printer': [
      'HP – LaserJet Pro M126nw',
      'Canon – imageCLASS MF244dw',
      'Epson – EcoTank L3250',
      'Brother – DCP-L2541DW',
      'Ricoh – SP 210SU',
      'Other'
    ],
    'Scanner': [
      'Canon – LiDE 300',
      'Epson – Perfection V39',
      'HP – ScanJet Pro 2000 s2',
      'Fujitsu – fi-7160',
      'Brother – ADS-2200',
      'Other'
    ],
    'Photocopier': [
      'Canon – IR 2525',
      'Xerox – WorkCentre 5019',
      'Ricoh – MP 2014AD',
      'Konica Minolta – Bizhub 185',
      'Kyocera – TaskAlfa 1800',
      'Other'
    ],
    'Smart Board': [
      'Samsung – Flip 2 WM55R',
      'BenQ – RP6502',
      'ViewSonic – IFP6530',
      'LG – TR3DJ Series',
      'Promethean – ActivPanel Titanium',
      'Other'
    ],
    'Speaker System': [
      'JBL – Control 1 Pro',
      'Bose – Companion 2 Series III',
      'Sony – SA-D10',
      'Philips – MMS2625B',
      'Logitech – Z333',
      'Other'
    ],
    'CCTV Camera': [
      'Hikvision – DS-2CE1',
      'Dahua – DH-HAC-HFW1200D',
      'CP Plus – CP-VCG-D24',
      'TP-Link – VIGI C300HP',
      'Godrej – Active 2.0',
      'Other'
    ],
    'Switch/Router': [
      'Cisco – Catalyst 2960X',
      'TP-Link – Archer C6',
      'D-Link – DIR-825 AC1200',
      'Netgear – R6260 AC1600',
      'MikroTik – hAP ac²',
      'Other'
    ],
    'Refrigerator': [
      'LG – GL-B201SLBB 190L',
      'Samsung – RR21T2G2W',
      'Whirlpool – Neo 258LH',
      'Haier – HRD-1954BS',
      'Godrej – RD EDGE 200',
      'Other'
    ],
    'Microwave': [
      'Samsung – MS23K3513AK',
      'LG – MS2043DB',
      'IFB – 20PM2S',
      'Bajaj – 1701 MT',
      'Panasonic – NN-ST26JMFDG',
      'Other'
    ],
    'Water Heater': [
      'AO Smith – HSE-SAS 15L',
      'Bajaj – New Shakti 15L',
      'Havells – Instanio 3L',
      'Crompton – Solarium Qube 15L',
      'V-Guard – Victo 15L',
      'Other'
    ],
    'Exhaust Fan': [
      'Havells – Ventil Air DX',
      'Crompton – Brisk Air',
      'Usha – Crisp Air',
      'Bajaj – Maxima DX',
      'Orient – Hill Air',
      'Other'
    ],
  };

  // Common wattages as strings; UI will show '40 W' etc. plus "Other"
  final List<String> _wattages = [
    '5',
    '9',
    '15',
    '25',
    '40',
    '60',
    '75',
    '100',
    '150',
    '200',
    '250',
    '500',
    '1000',
    'Other'
  ];

  List<String> get _buildingCategories => _allBuildingsData.keys.toList();

  List<String> get _blocks {
    if (buildingCategory == null) return [];
    return _allBuildingsData[buildingCategory]!.keys.toList();
  }

  List<String> get _floors {
    if (buildingCategory == null || block == null) return [];
    int floorCount = _allBuildingsData[buildingCategory]![block]!['floors'] as int;
    // Generate floor numbers: for 2 floors -> ['1', '2'], for 3 floors -> ['1', '2', '3'], etc.
    return List.generate(floorCount, (i) => '${i + 1}');
  }

  double? get _buildingArea {
    if (buildingCategory == null || block == null) return null;
    return _allBuildingsData[buildingCategory]![block]!['area'] as double;
  }

  @override
  void dispose() {
    _roomController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(bool fromCamera) async {
    final picked = await _picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 75,
    );
    if (picked != null) {
      setState(() => _imageFile = File(picked.path));
    }
  }

  Future<String?> _saveImageLocally(File image) async {
    final dir = await getApplicationDocumentsDirectory();
    final path = '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final savedImage = await image.copy(path);
    return savedImage.path;
  }

  void _addEquipmentRow() {
    setState(() {
      // Add keys including wattage and customWattage
      equipments.add({
        'type': null,
        'make': null, // Changed to null for dropdown
        'customMake': '', // NEW: for custom make/model input
        'qty': 0.0,
        'customType': '',
        'wattage': null,
        'customWattage': ''
      });
    });
  }

  void _removeEquipmentRow(int index) {
    setState(() {
      equipments.removeAt(index);
    });
  }

  Future<void> _saveEntry() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    if (equipments.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Add at least one equipment!")),
      );
      return;
    }

    String? savedPath;
    if (_imageFile != null) {
      savedPath = await _saveImageLocally(_imageFile!);
    }

    // Convert equipment wattage to numeric double before saving
    final List<Map<String, dynamic>> finalEquipments =
        equipments.map((e) {
      double watt = 0.0;
      final selected = (e['wattage'] ?? '').toString();
      if (selected.toLowerCase() == 'other') {
        watt = double.tryParse((e['customWattage'] ?? '').toString()) ?? 0.0;
      } else {
        watt = double.tryParse(selected) ?? 0.0;
      }

      // If type was 'Other' and customType exists, prefer that in 'type' field
      final typeVal = (e['type'] == 'Other' && (e['customType'] ?? '').toString().isNotEmpty)
          ? e['customType']
          : e['type'];

      // ✅ NEW: Handle custom make/model
      final makeVal = (e['make'] == 'Other' && (e['customMake'] ?? '').toString().isNotEmpty)
          ? e['customMake']
          : e['make'];

      return {
        'type': typeVal,
        'make': makeVal ?? '',
        'qty': e['qty'] ?? 0.0,
        'wattage': watt,
        'rawWattageSelected': e['wattage'], // for debugging / reference (optional)
      };
    }).toList();

    final box = Hive.box('entries');
    await box.add({
      'buildingCategory': buildingCategory,
      'block': block,
      'floor': floor,
      'room': room,
      'area': _buildingArea,
      'equipments': finalEquipments,
      'photoPath': savedPath,
      'timestamp': DateTime.now().toString(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Room entry saved successfully!")),
    );

    setState(() {
      _formKey.currentState!.reset();
      _roomController.clear();
      buildingCategory = null;
      block = null;
      floor = null;
      room = null;
      equipments.clear();
      _imageFile = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: const Text(
          'Add Room Entry',
          style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              // QR Scan Button
              Center(
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.qr_code_scanner, color: Colors.green),
                  label: const Text(
                    "Scan Room QR",
                    style: TextStyle(
                      color: Colors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.green, width: 1.8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                  ),
                  onPressed: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const QRScannerScreen()),
                    );

                    if (result != null && result is String) {
                      final parts = result.split('-');

                      setState(() {
                        block = parts.isNotEmpty ? parts[0] : null;
                        floor = parts.length > 1
                            ? parts[1].replaceAll(RegExp(r'[^0-9]'), '')
                            : null;
                        room = parts.length > 2 ? parts[2] : null;
                        if (room != null) _roomController.text = room!;
                      });

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("QR Scanned: $result")),
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 20),

              // Building Category Dropdown
              _dropdown("Building Category", _buildingCategories, (v) {
                setState(() {
                  buildingCategory = v;
                  block = null;
                  floor = null;
                  room = null;
                  _roomController.clear();
                });
              }, buildingCategory),

              // Building/Block Dropdown
              _dropdown("Building/Block", _blocks, (v) {
                setState(() {
                  block = v;
                  floor = null;
                  room = null;
                  _roomController.clear();
                });
              }, block),

              // Floor Dropdown (dynamic based on block)
              _dropdown("Floor", _floors, (v) {
                setState(() {
                  floor = v;
                  room = null;
                  _roomController.clear();
                });
              }, floor),

              // Room Number Input Field (replaced dropdown)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _roomController,
                  decoration: const InputDecoration(
                    labelText: "Room Number",
                    hintText: "Enter room number (e.g., 101, Lab-1)",
                    prefixIcon: Icon(Icons.room, color: Colors.green),
                    border: OutlineInputBorder(),
                  ),
                  onSaved: (v) => room = v,
                  validator: (v) => v == null || v.isEmpty ? 'Enter room number' : null,
                ),
              ),

              const SizedBox(height: 10),

              // Building Area Display
              if (_buildingArea != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.square_foot, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(
                        "Building Area: ${_buildingArea!.toStringAsFixed(2)} sq.m",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ),

              // Equipments Section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    )
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Equipments",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 10),
                    ...equipments
                        .asMap()
                        .entries
                        .map((entry) => _equipmentRow(entry.key))
                        ,
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: OutlinedButton.icon(
                        onPressed: _addEquipmentRow,
                        icon: const Icon(Icons.add),
                        label: const Text("Add Equipment"),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Photo Section
              _photoSection(),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _saveEntry,
                icon: const Icon(Icons.save),
                label: const Text("Save Room Entry"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 14),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _photoSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        children: [
          const Text("Attach Site Photo",
              style: TextStyle(
                  fontWeight: FontWeight.bold, color: Colors.black87)),
          const SizedBox(height: 10),
          _imageFile == null
              ? const Icon(Icons.image, size: 80, color: Colors.grey)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _imageFile!,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              OutlinedButton.icon(
                onPressed: () => _pickImage(true),
                icon: const Icon(Icons.camera_alt),
                label: const Text("Camera"),
              ),
              OutlinedButton.icon(
                onPressed: () => _pickImage(false),
                icon: const Icon(Icons.photo),
                label: const Text("Gallery"),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _equipmentRow(int index) {
    final isOtherSelected = equipments[index]['type'] == 'Other';
    final isWattOther = (equipments[index]['wattage']?.toString().toLowerCase() == 'other');
    
    // ✅ NEW: Check if make/model should be dropdown or text input
    final selectedType = equipments[index]['type'];
    final hasMakeModelOptions = _makeModels.containsKey(selectedType);
    final isMakeOther = (equipments[index]['make']?.toString() == 'Other');

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        children: [
          Row(
            children: [
              // Type
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Type"),
                  value: equipments[index]['type'],
                  items: _types
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) {
                    setState(() {
                      equipments[index]['type'] = v;
                      // Reset make/model when type changes
                      equipments[index]['make'] = null;
                      equipments[index]['customMake'] = '';
                    });
                  },
                  validator: (v) => v == null ? 'Select type' : null,
                ),
              ),

              const SizedBox(width: 8),

              // ✅ NEW: Make/Model - Dropdown for predefined types, Text input for "Other" type
              Expanded(
                flex: 3,
                child: hasMakeModelOptions
                    ? DropdownButtonFormField<String>(
                        decoration: const InputDecoration(labelText: "Make/Model"),
                        value: equipments[index]['make'],
                        items: _makeModels[selectedType]!
                            .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                            .toList(),
                        onChanged: (v) => setState(() => equipments[index]['make'] = v),
                        validator: (v) => v == null ? 'Select make/model' : null,
                      )
                    : TextFormField(
                        decoration: const InputDecoration(labelText: "Make/Model"),
                        onChanged: (v) => equipments[index]['customMake'] = v,
                        validator: (v) => v!.isEmpty ? 'Enter make/model' : null,
                      ),
              ),

              const SizedBox(width: 8),

              // Qty
              Expanded(
                flex: 1,
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "Qty"),
                  keyboardType: TextInputType.number,
                  onSaved: (v) =>
                      equipments[index]['qty'] = double.tryParse(v ?? '') ?? 0.0,
                  validator: (v) => v!.isEmpty ? 'Enter qty' : null,
                ),
              ),

              const SizedBox(width: 8),

              // Wattage dropdown
              Expanded(
                flex: 1,
                child: DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: "Watt (W)"),
                  value: equipments[index]['wattage'],
                  items: _wattages
                      .map((w) => DropdownMenuItem(
                          value: w, child: Text(w == 'Other' ? 'Other' : '$w W')))
                      .toList(),
                  onChanged: (v) => setState(() => equipments[index]['wattage'] = v),
                  validator: (v) => v == null ? 'Select wattage' : null,
                ),
              ),

              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeEquipmentRow(index),
              ),
            ],
          ),

          // Show custom equipment input field when "Other" type is selected
          if (isOtherSelected)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                decoration: const InputDecoration(
                  labelText: "Enter Equipment Type",
                  hintText: "e.g., Water Cooler, Coffee Machine",
                  prefixIcon: Icon(Icons.edit, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
                onSaved: (v) => equipments[index]['customType'] = v ?? '',
                validator: (v) => v!.isEmpty ? 'Please specify equipment type' : null,
              ),
            ),

          // ✅ NEW: Show custom make/model input when "Other" is selected in make/model dropdown
          if (isMakeOther)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                initialValue: equipments[index]['customMake'],
                decoration: const InputDecoration(
                  labelText: "Enter Make/Model",
                  hintText: "e.g., Custom Brand XYZ",
                  prefixIcon: Icon(Icons.devices, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
                onChanged: (v) => setState(() => equipments[index]['customMake'] = v),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please specify make/model';
                  return null;
                },
              ),
            ),

          // Show custom wattage input when "Other" wattage selected
          if (isWattOther)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: TextFormField(
                initialValue: equipments[index]['customWattage'],
                decoration: const InputDecoration(
                  labelText: "Enter Wattage (W)",
                  hintText: "Numeric value, e.g., 37.5",
                  prefixIcon: Icon(Icons.power, color: Colors.orange),
                  border: OutlineInputBorder(),
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                onChanged: (v) => setState(() => equipments[index]['customWattage'] = v),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Enter wattage';
                  final val = double.tryParse(v);
                  if (val == null) return 'Enter valid number';
                  return null;
                },
              ),
            ),

        ],
      ),
    );
  }

  Widget _dropdown(
      String label, List<String> items, Function(String?) onChanged, String? currentValue) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(labelText: label),
        value: currentValue,
        items: items.isEmpty
            ? null
            : items
                .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                .toList(),
        onChanged: items.isEmpty ? null : onChanged,
        validator: (v) => v == null ? 'Select $label' : null,
      ),
    );
  }
}