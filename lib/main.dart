import 'package:flutter/material.dart';

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
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: const BillingHomeScreen(),
    );
  }
}

class BillingHomeScreen extends StatefulWidget {
  const BillingHomeScreen({super.key});

  @override
  State<BillingHomeScreen> createState() =>
      _BillingHomeScreenState();
}

class _BillingHomeScreenState extends State<BillingHomeScreen> {
  final String shopName = 'BURI MA LOTTERY';
  final String shopAddress = 'Motiganj, Bongaon';
  final String shopPhone = 'Mob: +91 9876543210';

  final TextEditingController partyController =
      TextEditingController();
  final TextEditingController groupController =
      TextEditingController();
  final TextEditingController rateController =
      TextEditingController();
  final TextEditingController discountController =
      TextEditingController();
  final TextEditingController paidController =
      TextEditingController();

  String selectedDraw = '1:00 PM';
  int selectedSem = 5;
  int quantityPieces = 25;

  final Map<int, int> semPiecesConfig = {
    5: 25,
    10: 10,
    30: 30,
    50: 50,
    100: 100,
    200: 200,
  };

  double totalBill = 0;
  double dueAmount = 0;

  void calculateBill() {
    final rate = double.tryParse(rateController.text) ?? 0;
    final discount =
        double.tryParse(discountController.text) ?? 0;
    final paid = double.tryParse(paidController.text) ?? 0;

    final gross = quantityPieces * rate;
    final net = (gross - discount).clamp(0.0, double.infinity);

    setState(() {
      totalBill = net;
      dueAmount = (net - paid).clamp(0.0, double.infinity);
    });
  }

  void updateSem(int sem) {
    setState(() {
      selectedSem = sem;
      quantityPieces = semPiecesConfig[sem] ?? 1;
    });
    calculateBill();
  }

  void showBill() {
    final party = partyController.text.trim().isEmpty
        ? 'CASH'
        : partyController.text.trim();

    final group = groupController.text.trim().isEmpty
        ? '-'
        : groupController.text.trim();

    final paid = double.tryParse(paidController.text) ?? 0;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text(
          'BILL RECEIPT',
          textAlign: TextAlign.center,
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Column(
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                    Text(shopAddress),
                    Text(shopPhone),
                  ],
                ),
              ),
              const Divider(height: 24),
              Text('Draw: $selectedDraw'),
              Text('Party: $party'),
              Text('Sem: $selectedSem'),
              Text('Group: $group'),
              Text('Quantity: $quantityPieces Pcs'),
              Text('Rate: ₹${rateController.text}'),
              Text('Discount: ₹${discountController.text.isEmpty ? "0" : discountController.text}'),
              const Divider(height: 24),
              Text(
                'Total Bill: ₹${totalBill.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text('Paid: ₹${paid.toStringAsFixed(2)}'),
              Text(
                'Balance Due: ₹${dueAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
              const Divider(height: 24),
              const Center(child: Text('Thank You! Visit Again.')),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('CLOSE'),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    partyController.dispose();
    groupController.dispose();
    rateController.dispose();
    discountController.dispose();
    paidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('লটারি স্টক ও বিলিং'),
        backgroundColor: Colors.indigo,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              color: Colors.indigo.shade50,
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  children: [
                    Text(
                      shopName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.indigo,
                      ),
                    ),
                    Text(shopAddress),
                    Text(shopPhone),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    initialValue: selectedDraw,
                    decoration: const InputDecoration(
                      labelText: 'ড্র টাইম',
                      border: OutlineInputBorder(),
                    ),
                    items: ['1:00 PM', '6:00 PM', '8:00 PM']
                        .map(
                          (time) => DropdownMenuItem(
                            value: time,
                            child: Text(time),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => selectedDraw = value);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: partyController,
                    decoration: const InputDecoration(
                      labelText: 'পার্টির নাম',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            const Text(
              'সেম (Sem) নির্বাচন করুন',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),

            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: semPiecesConfig.keys.map((sem) {
                return ChoiceChip(
                  label: Text('$sem সেম'),
                  selected: selectedSem == sem,
                  onSelected: (_) => updateSem(sem),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: groupController,
                    decoration: const InputDecoration(
                      labelText: 'গ্রুপ',
                      hintText: 'যেমন 84A-E / L',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: InputDecorator(
                    decoration: const InputDecoration(
                      labelText: 'মোট পিস',
                      border: OutlineInputBorder(),
                    ),
                    child: Text('$quantityPieces Pcs'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: rateController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'দর (₹)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => calculateBill(),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: discountController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'ছাড়/কমিশন (₹)',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (_) => calculateBill(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            TextField(
              controller: paidController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'জমা টাকা (₹)',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => calculateBill(),
            ),
            const SizedBox(height: 20),

            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _billRow(
                      'মোট বিল',
                      '₹${totalBill.toStringAsFixed(2)}',
                      Colors.green,
                    ),
                    const Divider(),
                    _billRow(
                      'বকেয়া / বাকি',
                      '₹${dueAmount.toStringAsFixed(2)}',
                      Colors.red,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: showBill,
              icon: const Icon(Icons.receipt_long),
              label: const Text(
                'বিল তৈরি করুন',
                style: TextStyle(fontSize: 17),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _billRow(String title, String amount, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        Text(
          amount,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 17,
            color: color,
          ),
        ),
      ],
    );
  }
}
