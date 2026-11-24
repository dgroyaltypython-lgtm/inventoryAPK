import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../models/inventory_item.dart';
import 'app_shell.dart';
import 'widgets.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({required this.onGoToStock, super.key});
  final VoidCallback onGoToStock;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  Map<String, Object>? _stats;
  List<InventoryItem> _lowItems = [];
  List<Map<String, Object?>> _recent = [];
  bool _loading = true;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
    refreshSignal.addListener(_load);
  }

  @override
  void dispose() {
    refreshSignal.removeListener(_load);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final values = await Future.wait<Object>([
        AppDatabase.instance.getDashboardStats(),
        AppDatabase.instance.getReorderItems(),
        AppDatabase.instance.getRecentEntries(limit: 6),
      ]);
      if (!mounted) return;
      setState(() {
        _stats = values[0] as Map<String, Object>;
        _lowItems = values[1] as List<InventoryItem>;
        _recent = values[2] as List<Map<String, Object?>>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hour = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good morning' : (hour < 17 ? 'Good afternoon' : 'Good evening');
    final date = DateFormat('EEEE, dd MMMM yyyy').format(DateTime.now());
    final query = _searchController.text.trim().toLowerCase();
    final lowItems = _lowItems.where((item) => query.isEmpty || '${item.nameEn} ${item.nameMr} ${item.code} ${item.category}'.toLowerCase().contains(query)).toList();
    final recent = _recent.where((row) => query.isEmpty || '${row['name_en']} ${row['name_mr']} ${row['item_code']} ${row['category']} ${row['entry_type']}'.toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: canvas,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: teal))
            : RefreshIndicator(
                color: teal,
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.only(bottom: 26),
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 4),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(hintText: 'Search dashboard stock or recent activity', prefixIcon: const Icon(Icons.search, color: teal), suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none)),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(colors: [Color(0xFF0B353B), Color(0xFF0D6F6B)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [BoxShadow(color: ink.withValues(alpha: 0.14), blurRadius: 20, offset: const Offset(0, 10))],
                        ),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Row(children: [
                            Container(height: 38, width: 38, decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.13), borderRadius: BorderRadius.circular(13)), child: const Icon(Icons.waves_rounded, color: gold)),
                            const SizedBox(width: 10),
                            const Text('COASTAL PEARL', style: TextStyle(color: Colors.white, letterSpacing: 1.3, fontWeight: FontWeight.w800, fontSize: 12)),
                            const Spacer(),
                            const Icon(Icons.wifi_off_rounded, color: Colors.white70, size: 16),
                            const SizedBox(width: 5),
                            const Text('Offline ready', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                          ]),
                          const SizedBox(height: 22),
                          Text(greeting, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                          const SizedBox(height: 4),
                          const Text('Kitchen stock,\nunder control.', style: TextStyle(color: Colors.white, fontSize: 25, height: 1.12, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 12),
                          Text(date, style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                        ]),
                      ),
                    ),
                    const SectionTitle('Today at a glance'),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.48,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        children: [
                          MetricCard(label: 'Inventory items', value: '${_stats?['items'] ?? 0}', icon: Icons.inventory_2_outlined),
                          MetricCard(label: 'Need reordering', value: '${_stats?['lowStock'] ?? 0}', icon: Icons.warning_amber_rounded, tint: const Color(0xFFCA7D25), helper: 'At or below minimum'),
                          MetricCard(label: 'Purchases today', value: moneyText((_stats?['purchases'] as num?) ?? 0), icon: Icons.south_west_rounded, tint: const Color(0xFF287A60)),
                          MetricCard(label: 'Used today', value: '${qtyText((_stats?['usedQty'] as num?) ?? 0)} units', icon: Icons.restaurant_outlined, tint: const Color(0xFF5974A5)),
                        ],
                      ),
                    ),
                    SectionTitle('Stock to watch', action: 'View all', onAction: widget.onGoToStock),
                    if (lowItems.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: EmptyState(title: 'All minimums covered', message: 'No items currently need reordering.', icon: Icons.check_circle_outline))
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EEEC))),
                          child: Column(children: lowItems.take(5).map((item) => _lowItem(item)).toList()),
                        ),
                      ),
                    const SectionTitle('Recent activity'),
                    if (recent.isEmpty)
                      const Padding(padding: EdgeInsets.symmetric(horizontal: 18), child: EmptyState(title: 'No entries yet', message: 'Record your first purchase, usage or wastage entry.', icon: Icons.receipt_long_outlined))
                    else
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        child: Container(
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: const Color(0xFFE7EEEC))),
                          child: Column(children: recent.asMap().entries.map((entry) => _recentRow(entry.value)).toList()),
                        ),
                      ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _lowItem(InventoryItem item) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(children: [
          Container(width: 38, height: 38, decoration: BoxDecoration(color: const Color(0xFFFFF2E8), borderRadius: BorderRadius.circular(12)), child: const Icon(Icons.inventory_2_outlined, color: Color(0xFFB76B29), size: 19)),
          const SizedBox(width: 11),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w700, fontSize: 13)),
            Text('${item.category} · ${item.code}', style: const TextStyle(color: Colors.black45, fontSize: 10.5)),
          ])),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${qtyText(item.currentStock)} ${item.unit}', style: const TextStyle(color: Color(0xFFB45309), fontWeight: FontWeight.w800, fontSize: 12)),
            Text('Min ${qtyText(item.minimumStock ?? 0)}', style: const TextStyle(color: Colors.black45, fontSize: 10)),
          ]),
        ]),
      );

  Widget _recentRow(Map<String, Object?> row) {
    final type = row['entry_type']?.toString() ?? '';
    final date = row['entry_date']?.toString() ?? '';
    final icon = type == 'Purchase' ? Icons.add_shopping_cart : (type == 'Used' ? Icons.restaurant : Icons.delete_outline);
    final tint = type == 'Purchase' ? const Color(0xFF27775E) : (type == 'Used' ? const Color(0xFF5571A3) : const Color(0xFFC26C42));
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      child: Row(children: [
        Container(width: 36, height: 36, decoration: BoxDecoration(color: tint.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: tint, size: 18)),
        const SizedBox(width: 10),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(row['name_en']?.toString() ?? 'Item', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 12.5, fontWeight: FontWeight.w700)),
          Text('$type · $date', style: const TextStyle(color: Colors.black45, fontSize: 10.5)),
        ])),
        Text('${qtyText((row['quantity'] as num?) ?? 0)} ${row['unit'] ?? ''}', style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 11.5)),
      ]),
    );
  }
}
