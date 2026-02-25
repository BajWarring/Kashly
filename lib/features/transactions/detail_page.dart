import 'package:flutter/material.dart';
import 'package:kashly/domain/entities/transaction.dart';
import 'package:kashly/domain/entities/transaction_history.dart';

class TransactionDetailPage extends StatelessWidget {
  final String id;

  const TransactionDetailPage({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    final transaction = Transaction(id: id, /* Fetch */ ); // Assume fetch

    return Scaffold(
      appBar: AppBar(title: const Text('Transaction Detail')),
      body: Column(
        children: [
          Text('Amount: ${transaction.amount}'),
          // Other fields
          Text('Sync Status: ${transaction.syncStatus}'),
          // Show drive sync status
          // Edit history
          ExpansionTile(
            title: const Text('Edit History'),
            children: [
              // List history entries
              ListView.builder(
                shrinkWrap: true,
                itemBuilder: (context, index) {
                  final history = TransactionHistory(/* Fetch */ );
                  return ListTile(
                    title: Text('${history.fieldName}: ${history.oldValue} -> ${history.newValue}'),
                    subtitle: Text('By ${history.changedBy} at ${history.changedAt}'),
                  );
                },
              ),
            ],
          ),
          // Actions: edit, delete, mark reconciled, attach receipt, sync now
          Row(
            children: [
              IconButton(icon: const Icon(Icons.edit), onPressed: () {}),
              IconButton(icon: const Icon(Icons.delete), onPressed: () {}),
              IconButton(icon: const Icon(Icons.check), onPressed: () {}),
              IconButton(icon: const Icon(Icons.attach_file), onPressed: () {}),
              IconButton(icon: const Icon(Icons.sync), onPressed: () {}),
            ],
          ),
        ],
      ),
    );
  }
}
