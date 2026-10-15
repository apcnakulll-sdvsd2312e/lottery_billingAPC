import 'package:flutter/material.dart';
import 'package:print_bluetooth_thermal/print_bluetooth_thermal.dart';
import 'package:esc_pos_utils_plus/esc_pos_utils_plus.dart';

void main() {
  runApp(const LotteryBillingApp());
}

class LotteryBillingApp extends StatelessWidget {
  const LotteryBillingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Lottery Billing & Stock',
      theme: ThemeData(primarySwatch: Colors.indigo, useMaterial3: true),
      home: const BillingHomeScreen(),
    );
  }
}

class BillingHomeScreen extends StatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  State<BillingHomeScreen> createState() => _BillingHomeScreenState();
}

class _BillingHomeScreenState extends State<BillingHomeScreen> {
  // দোকানের তথ্য
  final String shopName = "BURI MA LOTTERY";
  final String shopAddress = "Motiganj, Bongaon";
  final String shopPhone = "Mob: +91 9876543210";

  // ফিল্ড কন্ট্রোলার
  final TextEditingController _partyController = TextEditingController();
  final TextEditingController _groupController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _discountController = TextEditingController();
  final TextEditingController _paidController = TextEditingController();

  String _selectedDraw = '1:00 PM';
  int _selectedSem = 5;
  int _quantityPieces = 25;

  final Map<int, int> semPiecesConfig = {
    5: 25,
    10: 10,
    30: 30,
    50: 50,
    100: 100,
    200: 200,
  };

  double _totalBill = 0.0;
  double _dueAmount = 0.0;

  // ব্লুটুথ প্রিন্টার ভেরিয়েবল
  List<BluetoothInfo> _availablePrinters = [];
  bool _isConnected = false;

  @override
  void initState() {
    super.initState();
    _scanPrinters();
  }

  void _calculateBill() {
    double rate = double.tryParse(_rateController.text) ?? 0.0;
    double discount = double.tryParse(_discountController.text) ?? 0.0;
    double paid = double.tryParse(_paidController.text) ?? 0.0;

    double gross = _quantityPieces * rate;
    double net = gross - discount;
    if (net < 0) net = 0;

    setState(() {
      _totalBill = net;
      _dueAmount = net - paid;
    });
  }

  void _updateSem(int sem) {
    setState(() {
      _selectedSem = sem;
      _quantityPieces = semPiecesConfig[sem] ?? 1;
      _calculateBill();
    });
  }

  // কাছাকাছি পেয়ার্ড করা প্রিন্টার স্ক্যান
  Future<void> _scanPrinters() async {
    final List<BluetoothInfo> list = await PrintBluetoothThermal.pairedBluetooths;
    setState(() {
      _availablePrinters = list;
    });
  }

  // প্রিন্টারে কানেক্ট করা
  Future<void> _connectToPrinter(String macAddress) async {
    final bool result = await PrintBluetoothThermal.connect(macPrinterAddress: macAddress);
    setState(() {
      _isConnected = result;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(result ? 'প্রিন্টার কানেক্ট হয়েছে!' : 'কানেকশন ব্যর্থ হয়েছে!')),
    );
  }

  // 58mm মেমো ফরম্যাট তৈরি ও প্রিন্ট
  Future<void> _printReceipt() async {
    bool connected = await PrintBluetoothThermal.connectionStatus;
    if (!connected) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('অনুগ্রহ করে আগে প্রিন্টার কানেক্ট করুন!')),
      );
      return;
    }

    // 58mm থার্মাল পেপারের সাইজ (PaperSize.mm58)
    final profile = await CapabilityProfile.load();
    final generator = Generator(PaperSize.mm58, profile);
    List<int> bytes = [];

    // রিসিট হেডার
    bytes += generator.text(shopName,
        styles: const PosStyles(align: PosAlign.center, bold: true, height: PosTextSize.size2));
    bytes += generator.text(shopAddress, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.text(shopPhone, styles: const PosStyles(align: PosAlign.center));
    bytes += generator.hr();

    // বিল বিস্তারিত
    bytes += generator.text('Draw: $_selectedDraw', styles: const PosStyles(bold: true));
    bytes += generator.text('Party: ${_partyController.text.isEmpty ? "CASH" : _partyController.text}');
    bytes += generator.text('Sem: $_selectedSem Sem | Group: ${_groupController.text}');
    bytes += generator.text('Qty: $_quantityPieces Pcs | Rate: Rs.${_rateController.text}');
    bytes += generator.hr();

    // মোট হিসাব
    bytes += generator.row([
      PosColumn(text: 'Total Bill:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rs.${_totalBill.toStringAsFixed(2)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Paid:', width: 7),
      PosColumn(text: 'Rs.${_paidController.text.isEmpty ? "0.00" : _paidController.text}', width: 5, styles: const PosStyles(align: PosAlign.right)),
    ]);
    bytes += generator.row([
      PosColumn(text: 'Balance Due:', width: 7, styles: const PosStyles(bold: true)),
      PosColumn(text: 'Rs.${_dueAmount.toStringAsFixed(2)}', width: 5, styles: const PosStyles(align: PosAlign.right, bold: true)),
    ]);

    bytes += generator.hr();
    bytes += generator.text('Thank You! Visit Again.', styles: const PosStyles(align: PosAlign.center));
    bytes += generator.feed(2);
    bytes += generator.cut();

    // ব্লুটুথ প্রিন্টারে ডেটা পাঠানো
    await PrintBluetoothThermal.writeBytes(bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লটারী স্টক ও বিলিং'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: Icon(_isConnected ? Icons.bluetooth_connected : Icons.bluetooth_disabled),
            onPressed: () => _showPrinterSelectionDialog(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // দোকান হেডার
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  children: [
                    Text(shopName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
                    Text(shopAddress, style: const TextStyle(fontSize: 13)),
                    Text(shopPhone, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ড্র টাইম ও পার্টি
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedDraw,
                    decoration: const InputDecoration(labelText: 'ড্র টাইম', border: OutlineInputBorder()),
                    items: ['1:00 PM', '6:00 PM', '8:00 PM'].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (val) => setState(() => _selectedDraw = val!),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _partyController,
                    decoration: const InputDecoration(labelText: 'পার্টির নাম', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // সেম সিলেকশন
            const Text('সেম (Sem):', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              children: semPiecesConfig.keys.map((sem) {
                final isSelected = _selectedSem == sem;
                return ChoiceChip(
                  label: Text('$sem সেম'),
                  selected: isSelected,
                  selectedColor: Colors.indigo,
                  labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
                  onSelected: (_) => _updateSem(sem),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // গ্রুপ ও টিকিট সংখ্যা
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _groupController,
                    decoration: const InputDecoration(labelText: 'গ্রুপ (84A-E / L)', border: OutlineInputBorder()),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextFormField(
                    initialValue: '$_quantityPieces পিস',
                    key: Key('qty_$_quantityPieces'),
                    readOnly: true,
                    decoration: const InputDecoration(labelText: 'মোট পাতা / পিস', border: OutlineInputBorder()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // রেট, কমিশন ও জমা
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _rateController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'দর (₹)', border: OutlineInputBorder()),
                    onChanged: (_) => _calculateBill(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: _discountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'ছাড়/কমিশন (₹)', border: OutlineInputBorder()),
                    onChanged: (_) => _calculateBill(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            TextField(
              controller: _paidController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'জমা টাকা (₹)', border: OutlineInputBorder()),
              onChanged: (_) => _calculateBill(),
            ),
            const SizedBox(height: 16),

            // মোট বিল ও বাকি
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('মোট বিল:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₹${_totalBill.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green, fontSize: 16)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('বকেয়া / বাকি:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('₹${_dueAmount.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: _dueAmount > 0 ? Colors.red : Colors.black, fontSize: 16)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // প্রিন্ট বাটন
            ElevatedButton.icon(
              onPressed: _printReceipt,
              icon: const Icon(Icons.print),
              label: const Text('58mm প্রিন্ট স্লিপ বের করুন', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // প্রিন্টার সিলেক্ট করার পপআপ ডায়ালগ
  void _showPrinterSelectionDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('ব্লুটুথ প্রিন্টার বেছে নিন'),
          content: _availablePrinters.isEmpty
              ? const Text('কোনো পেয়ার্ড প্রিন্টার পাওয়া যায়নি। ফোনের ব্লুটুথ সেটিংসে গিয়ে আগে প্রিন্টারটি পেয়ার (Pair) করুন।')
              : SizedBox(
                  width: double.maxFinite,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _availablePrinters.length,
                    itemBuilder: (context, index) {
                      final printer = _availablePrinters[index];
                      return ListTile(
                        leading: const Icon(Icons.print),
                        title: Text(printer.name),
                        subtitle: Text(printer.macAdress),
                        onTap: () {
                          Navigator.pop(context);
                          _connectToPrinter(printer.macAdress);
                        },
                      );
                    },
                  ),
                ),
          actions: [
            TextButton(
              onPressed: () {
                _scanPrinters();
                Navigator.pop(context);
              },
              child: const Text('রিফ্রেশ'),
            ),
          ],
        );
      },
    );
  }
}
