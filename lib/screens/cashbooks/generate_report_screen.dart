import 'package:flutter/material.dart';
import '../../core/models/book.dart';
import '../../core/models/field_option.dart';
import '../../core/database_helper.dart';
import '../../core/theme.dart';

// Helper class for shared dialogs on this screen
class FilterDialogs {
  static Future<List<String>?> showSelectionDialog(BuildContext context, String title, List<String> options, bool isMulti) async {
    List<String> selected = [];
    String? singleSelected = options.isNotEmpty ? options.first : null;

    return showDialog<List<String>>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          backgroundColor: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark)),
                const SizedBox(height: 16),
                ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: options.length,
                    itemBuilder: (c, i) {
                      final opt = options[i];
                      if (isMulti) {
                        final isSelected = selected.contains(opt);
                        return CheckboxListTile(
                          value: isSelected,
                          activeColor: accent,
                          contentPadding: EdgeInsets.zero,
                          title: Text(opt, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                          onChanged: (v) {
                            setStateDialog(() {
                              // FIXED: Added curly braces for the linter
                              if (v == true) {
                                selected.add(opt);
                              } else {
                                selected.remove(opt);
                              }
                            });
                          },
                        );
                      } else {
                        return InkWell(
                          onTap: () => setStateDialog(() => singleSelected = opt),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Icon(singleSelected == opt ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: singleSelected == opt ? accent : textMuted),
                                const SizedBox(width: 12),
                                Text(opt, style: const TextStyle(fontWeight: FontWeight.w600, color: textDark)),
                              ],
                            ),
                          )
                        );
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, isMulti ? selected : [singleSelected!]),
                    style: ElevatedButton.styleFrom(backgroundColor: accent, padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), elevation: 0),
                    child: const Text('Apply', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
                  ),
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class GenerateReportScreen extends StatefulWidget {
  final Book book;
  const GenerateReportScreen({super.key, required this.book});

  @override
  State<GenerateReportScreen> createState() => _GenerateReportScreenState();
}

class _GenerateReportScreenState extends State<GenerateReportScreen> {
  int _reportTypeIndex = 0;
  
  String _dateDisplay = 'All Time';
  String _typeDisplay = 'All Entries';
  String _catDisplay = 'All Categories';
  String _payDisplay = 'All Methods';

  Widget _buildSectionHeader(String title) {
    return Padding(padding: const EdgeInsets.only(left: 4, bottom: 12, top: 24), child: Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: textLight, letterSpacing: 1.2)));
  }

  Widget _buildFilterChip(String label, String value, IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(color: appBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: borderCol)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: textMuted)),
            const SizedBox(height: 6),
            Row(
              children: [
                Icon(icon, size: 14, color: accent), 
                const SizedBox(width: 6),
                Expanded(child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: textDark), maxLines: 1, overflow: TextOverflow.ellipsis)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildRadio(int val, String title, String sub) {
    return InkWell(
      onTap: () => setState(() => _reportTypeIndex = val),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(_reportTypeIndex == val ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: _reportTypeIndex == val ? accent : textMuted),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: textDark)),
                  Text(sub, style: const TextStyle(fontSize: 12, color: textMuted)),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generate Report')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSectionHeader('FILTERS'),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                Row(children: [
                  Expanded(child: _buildFilterChip('DATE', _dateDisplay, Icons.calendar_today, () {
                    // Date pickers implementation
                    setState(() => _dateDisplay = 'Custom Date');
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFilterChip('TYPE', _typeDisplay, Icons.swap_vert, () async {
                    final res = await FilterDialogs.showSelectionDialog(context, 'Entry Type', ['All Entries', 'Cash In', 'Cash Out'], false);
                    if (res != null && res.isNotEmpty) {
                      setState(() => _typeDisplay = res.first);
                    }
                  })),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildFilterChip('CATEGORY', _catDisplay, Icons.category, () async {
                    List<FieldOption> opts = await DatabaseHelper.instance.getAllOptions('Category');
                    List<String> optNames = opts.map((e) => e.value).toList();
                    
                    // FIXED: Context protection after an async await
                    if (!context.mounted) return; 
                    
                    final res = await FilterDialogs.showSelectionDialog(context, 'Categories', optNames, true);
                    if (res != null && res.isNotEmpty) {
                      setState(() => _catDisplay = '${res.length} Selected');
                    }
                  })),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFilterChip('PAYMENT', _payDisplay, Icons.account_balance_wallet, () async {
                    List<FieldOption> opts = await DatabaseHelper.instance.getAllOptions('Payment Method');
                    List<String> optNames = opts.map((e) => e.value).toList();
                    
                    // FIXED: Context protection after an async await
                    if (!context.mounted) return; 
                    
                    final res = await FilterDialogs.showSelectionDialog(context, 'Payment Method', optNames, true);
                    if (res != null && res.isNotEmpty) {
                      setState(() => _payDisplay = '${res.length} Selected');
                    }
                  })),
                ]),
                const SizedBox(height: 12),
                Row(children: [
                  Expanded(child: _buildFilterChip('SEARCH', 'Any text...', Icons.search, () {})),
                  const SizedBox(width: 12),
                  Expanded(child: _buildFilterChip('CUSTOM FIELD', 'Any', Icons.dashboard_customize, () {})),
                ]),
              ],
            ),
          ),

          _buildSectionHeader('REPORT TYPE'),
          Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: borderCol)),
            child: Column(
              children: [
                _buildRadio(0, 'Complete Detailed Report', 'Shows every single entry line by line'),
                const Divider(height: 1, color: borderCol),
                _buildRadio(1, 'Day-wise Summary', 'Grouped by daily totals'),
                const Divider(height: 1, color: borderCol),
                _buildRadio(2, 'Month-wise Summary', 'Grouped by monthly totals'),
                const Divider(height: 1, color: borderCol),
                _buildRadio(3, 'Category-wise Summary', 'Shows totals spent/received per category'),
                const Divider(height: 1, color: borderCol),
                _buildRadio(4, 'Payment Method Summary', 'Grouped by Cash, Bank, etc.'),
              ],
            ),
          ),
          
          const SizedBox(height: 100),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: FloatingActionButton.extended(
            onPressed: () {}, // Trigger actual PDF export here
            backgroundColor: accent, elevation: 4,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            icon: const Icon(Icons.picture_as_pdf, color: Colors.white),
            label: const Text('Generate PDF', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ),
    );
  }
}
