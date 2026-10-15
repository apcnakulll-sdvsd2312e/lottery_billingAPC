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
      title: 'Lottery Billing App',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Lottery Billing'),
        ),
        body: const Center(
          child: Text(
            'App is Running Successfully!',
            style: TextStyle(fontSize: 20),
          ),
        ),
      ),
    );
  }
}
