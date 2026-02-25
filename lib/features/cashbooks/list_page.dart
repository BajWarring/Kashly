import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kashly/domain/entities/cashbook.dart';
import 'package:kashly/core/di/providers.dart';
import 'package:go_router/go_router.dart';
import 'package:kashly/core/utils/icons.dart'; // Integrated icons

class CashbooksListPage extends ConsumerWidget {
  const CashbooksListPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cashbooks = ref.watch(cashbookProvider); // Assume provider for list

    return Scaffold(
      appBar: AppBar(title: const Text('Cashbooks')),
      body: Column(
        children: [
          TextField(
            decoration: const InputDecoration(labelText: 'Search'),
            onChanged: (value) {
              // Implement search
            },
          ),
          DropdownButton<String>(
            value: 'name',
            items: const [
              DropdownMenuItem(value: 'name', child: Text('Name')),
              DropdownMenuItem(value: 'last_updated', child: Text('Last Updated')),
              DropdownMenuItem(value: 'balance', child: Text('Balance')),
            ],
            onChanged: (value) {
              // Implement sort
            },
          ),
          // Filters: chips for active, archived, synced, unsynced
          Wrap(
            children: ['Active', 'Archived', 'Synced', 'Unsynced']
                .map((f) => Chip(label: Text(f), onSelected: (selected) {
                      // Filter logic
                    }))
                .toList(),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: cashbooks.length,
              itemBuilder: (context, index) {
                final cb = cashbooks[index];
                return Card(
                  child: ListTile(
                    title: Text(cb.name),
                    subtitle: Text('Balance: ${cb.openingBalance} ${cb.currency}\nLast Updated: ${cb.updatedAt}'),
                    trailing: getSyncStatusIcon(cb.syncStatus.name), // Use integrated icon
                    onTap: () => context.go('/cashbooks/${cb.id}'),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () {
          // Create action
        },
      ),
      // Actions: edit, archive, delete, backup_now in menu
    );
  }
}
