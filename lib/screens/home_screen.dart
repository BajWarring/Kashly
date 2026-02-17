import 'package:flutter/material.dart';
import '../models/cashbook.dart';
import '../widgets/cashbook_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;
  String _searchQuery = '';

  // Sample data
  final List<CashBook> _cashbooks = [
    CashBook(
      id: '1',
      name: 'Personal Expenses',
      balance: 5420.50,
      isPositive: true,
    ),
    CashBook(
      id: '2',
      name: 'Business Account',
      balance: 12350.75,
      isPositive: true,
    ),
    CashBook(
      id: '3',
      name: 'Groceries',
      balance: 250.00,
      isPositive: false,
    ),
    CashBook(
      id: '4',
      name: 'Investment Fund',
      balance: 25000.00,
      isPositive: true,
    ),
    CashBook(
      id: '5',
      name: 'Travel Budget',
      balance: 1500.00,
      isPositive: true,
    ),
  ];

  List<CashBook> get _filteredCashbooks {
    if (_searchQuery.isEmpty) {
      return _cashbooks;
    }
    return _cashbooks
        .where((book) =>
            book.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  void _showFilterOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filter Options',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.arrow_upward),
                title: const Text('Positive Balance'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement filter logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.arrow_downward),
                title: const Text('Negative Balance'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement filter logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.sort_by_alpha),
                title: const Text('Sort by Name'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sort logic
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_money),
                title: const Text('Sort by Balance'),
                onTap: () {
                  Navigator.pop(context);
                  // Implement sort logic
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _addCashBook() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final TextEditingController nameController = TextEditingController();
        final TextEditingController balanceController = TextEditingController();

        return AlertDialog(
          title: const Text('Add New CashBook'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'CashBook Name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: balanceController,
                decoration: const InputDecoration(
                  labelText: 'Initial Balance',
                  border: OutlineInputBorder(),
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                // Add cashbook logic here
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('CashBook added successfully')),
                );
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _isSearching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'Search cashbooks...',
                  border: InputBorder.none,
                ),
                onChanged: (value) {
                  setState(() {
                    _searchQuery = value;
                  });
                },
              )
            : const Text('CashBook'),
        actions: [
          if (_isSearching)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                setState(() {
                  _isSearching = false;
                  _searchController.clear();
                  _searchQuery = '';
                });
              },
            )
          else
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () {
                setState(() {
                  _isSearching = true;
                });
              },
            ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterOptions,
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              'Your Books',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),
          Expanded(
            child: _filteredCashbooks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.book_outlined,
                          size: 64,
                          color: Theme.of(context)
                              .colorScheme
                              .onSurfaceVariant
                              .withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'No cashbooks yet'
                              : 'No cashbooks found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Tap the + button to add your first cashbook'
                              : 'Try a different search term',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _filteredCashbooks.length,
                    itemBuilder: (context, index) {
                      return CashBookCard(
                        cashbook: _filteredCashbooks[index],
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Opened ${_filteredCashbooks[index].name}'),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addCashBook,
        icon: const Icon(Icons.add),
        label: const Text('Add CashBook'),
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
