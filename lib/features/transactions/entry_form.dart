import 'package:flutter/material.dart';
import 'package:kashly/domain/entities/transaction.dart';

class TransactionEntryForm extends StatefulWidget {
  const TransactionEntryForm({super.key});

  @override
  State<TransactionEntryForm> createState() => _TransactionEntryFormState();
}

class _TransactionEntryFormState extends State<TransactionEntryForm> {
  final _formKey = GlobalKey<FormState>();
  // Controllers for fields

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Transaction')),
      body: Form(
        key: _formKey,
        child: ListView(
          children: [
            TextFormField(decoration: const InputDecoration(labelText: 'Amount'), validator: (value) => value!.isEmpty ? 'Required' : null),
            // Date picker
            // Type radio: in/out
            TextFormField(decoration: const InputDecoration(labelText: 'Category')),
            TextFormField(decoration: const InputDecoration(labelText: 'Remark')),
            TextFormField(decoration: const InputDecoration(labelText: 'Method')),
            // Attachments picker
            // Quick categories buttons
            DropdownButton<String>(
              value: 'none',
              items: const [
                DropdownMenuItem(value: 'none', child: Text('None')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                // Weekly, monthly, yearly
              ],
              onChanged: (value) {},
            ),
            // Split transaction support: add multiple sub-entries
            ElevatedButton(onPressed: () {}, child: const Text('Add Split')),
            ElevatedButton(onPressed: () {
              if (_formKey.currentState!.validate()) {
                // Save transaction
              }
            }, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
