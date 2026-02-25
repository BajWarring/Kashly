import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/di/providers.dart';

class CashbookDetailPage extends ConsumerWidget {
  final String id;

  const CashbookDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashbook = ref.watch(cashbookDetailProvider(id)); // Assume provider

    return Scaffold(
      appBar: AppBar(title: Text(cashbook.name)),
      body: Column(
        children: [
          // Summary cards
          Row(
            children: [
              Card(child: Padding(padding: const EdgeInsets.all(8), child: Text('Total Balance: ${cashbook.openingBalance}'))),
              Card(child: Padding(padding: const EdgeInsets.all(8), child: const Text('Total In: 0'))),
              Card(child: Padding(padding: const EdgeInsets.all(8), child: const Text('Total Out: 0'))),
              Card(child: Padding(padding: const EdgeInsets.all(8), child: const Text('Reconciled: 0'))),
            ],
          ),
          // Transaction list with running balance, compact, infinite scroll
          Expanded(
            child: ListView.builder(
              itemBuilder: (context, index) {
                // Fetch transactions
                return ListTile(title: const Text('Transaction'));
              },
            ),
          ),
          // Per cashbook backup toggle
          SwitchListTile(
            title: const Text('Auto Backup'),
            value: cashbook.backupSettings.autoBackupEnabled,
            onChanged: (value) {
              // Update
            },
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(onPressed: () {}, child: const Text('In')),
          FloatingActionButton(onPressed: () {}, child: const Text('Out')),
          FloatingActionButton(onPressed: () {}, child: const Text('Quick')),
        ],
      ),
    );
  }
}
