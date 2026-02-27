import 'package:flutter/material.dart';

class CashbooksListPage extends StatelessWidget {
  const CashbooksListPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Cashbooks')),
      body: ListView(
        children: const [
          // TODO: Add search, sort, filters, fields, actions as per spec
          // search: true
          // sort: name, last_updated, balance
          // filters: active, archived, synced, unsynced
          // fields: cashbook_name, current_balance, last_updated, sync_status_icon
          // actions: create, edit, archive, delete, backup_now
        ],
      ),
    );
  }
}
