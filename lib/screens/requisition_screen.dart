import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../models/inventory_item.dart';
import 'app_shell.dart';
import 'widgets.dart';

class RequisitionScreen extends StatefulWidget {
  const RequisitionScreen({super.key});

  @override
  State<RequisitionScreen> createState() => _RequisitionScreenState();
}

class _RequisitionScreenState extends State<RequisitionScreen> {
  List<InventoryItem> _items = [];
  final Map<String, TextEditingController> _quantities = {};
  final _searchController = TextEditingController();
  bool _loading = true;
  bool _sharing = false;

  @override
  void initState() {
    super.initState();
    refreshSignal.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    refreshSignal.removeListener(_load);
    _searchController.dispose();
    for (final controller in _quantities.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    final items = await AppDatabase.instance.getReorderItems();
    if (!mounted) return;
    final currentCodes = items.map((item) => item.code).toSet();
    for (final key in _quantities.keys.toList()) {
      if (!currentCodes.contains(key)) {
        _quantities.remove(key)?.dispose();
      }
    }
    for (final item in items) {
      _quantities.putIfAbsent(item.code, () => TextEditingController(text: qtyText(item.suggestedOrder)));
    }
    setState(() {
      _items = items;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = _items.where((item) => query.isEmpty || '${item.nameEn} ${item.nameMr} ${item.code} ${item.category}'.toLowerCase().contains(query)).toList();
    final grouped = <String, List<InventoryItem>>{};
    for (final item in visibleItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(title: const Text('Purchase requirements', style: TextStyle(color: ink, fontWeight: FontWeight.w800)), backgroundColor: canvas, surfaceTintColor: Colors.transparent, actions: [IconButton(onPressed: _load, icon: const Icon(Icons.refresh, color: teal))]),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: teal))
          : _items.isEmpty
              ? const EmptyState(title: 'Nothing to order right now', message: 'Items at or below their minimum stock level will appear here.', icon: Icons.check_circle_outline)
              : Column(children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 5, 18, 13),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B353B), Color(0xFF0C7770)]), borderRadius: BorderRadius.circular(18)),
                      child: Row(children: [
                        const Icon(Icons.shopping_basket_outlined, color: gold, size: 25),
                        const SizedBox(width: 12),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('${_items.length} items need attention', style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                          const SizedBox(height: 3),
                          const Text('Review suggested quantities before sharing with suppliers.', style: TextStyle(color: Colors.white70, fontSize: 10.5)),
                        ])),
                      ]),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 10),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(hintText: 'Search order items / category / code', prefixIcon: const Icon(Icons.search, color: teal), suffixIcon: _searchController.text.isEmpty ? null : IconButton(onPressed: () { _searchController.clear(); setState(() {}); }, icon: const Icon(Icons.close)), filled: true, fillColor: Colors.white, border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none)),
                    ),
                  ),
                  Expanded(child: visibleItems.isEmpty
                      ? const Center(child: Padding(padding: EdgeInsets.all(22), child: Text('No matching order items. Try another search.', style: TextStyle(color: Colors.black54))))
                      : ListView(padding: const EdgeInsets.fromLTRB(18, 0, 18, 15), children: [
                    for (final group in grouped.entries) ...[
                      Padding(padding: const EdgeInsets.fromLTRB(2, 12, 2, 8), child: Text(group.key, style: const TextStyle(color: teal, fontWeight: FontWeight.w800, fontSize: 13))),
                      for (final item in group.value) _reorderCard(item),
                    ],
                  ])),
                  SafeArea(
                    top: false,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 14),
                      decoration: const BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE7EEEC)))),
                      child: FilledButton.icon(
                        onPressed: _sharing ? null : _shareRequirement,
                        icon: _sharing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.chat_outlined),
                        label: Text(_sharing ? 'Preparing list…' : 'Share requirement on WhatsApp'),
                        style: FilledButton.styleFrom(backgroundColor: const Color(0xFF16845B), foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ),
                  ),
                ]),
    );
  }

  Widget _reorderCard(InventoryItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Container(
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: const Color(0xFFE6EEEB))),
          child: Row(children: [
            const Icon(Icons.inventory_2_outlined, color: teal, size: 20),
            const SizedBox(width: 10),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 12.5)),
              Text('${item.nameMr} · ${qtyText(item.currentStock)} ${item.unit} available', style: const TextStyle(color: Colors.black45, fontSize: 10.5)),
            ])),
            const SizedBox(width: 7),
            SizedBox(
              width: 82,
              child: TextField(
                controller: _quantities[item.code],
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  labelText: 'Order ${item.unit}',
                  labelStyle: const TextStyle(fontSize: 9, color: Colors.black45),
                  filled: true,
                  fillColor: canvas,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide.none),
                ),
                style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13),
              ),
            ),
          ]),
        ),
      );

  Future<void> _shareRequirement() async {
    final sections = <String>[];
    final query = _searchController.text.trim().toLowerCase();
    final visibleItems = _items.where((item) => query.isEmpty || '${item.nameEn} ${item.nameMr} ${item.code} ${item.category}'.toLowerCase().contains(query)).toList();
    final grouped = <String, List<InventoryItem>>{};
    for (final item in visibleItems) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    for (final group in grouped.entries) {
      final lines = <String>[];
      for (final item in group.value) {
        final quantity = double.tryParse(_quantities[item.code]?.text.trim() ?? '') ?? 0;
        if (quantity <= 0) continue;
        lines.add('• ${item.nameEn} (${item.nameMr}): ${qtyText(quantity)} ${item.unit}');
      }
      if (lines.isNotEmpty) sections.add('${group.key}\n${lines.join('\n')}');
    }
    if (sections.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter an order quantity greater than zero.')));
      return;
    }
    final message = [
      'COASTAL PEARL — KITCHEN PURCHASE REQUIREMENT',
      DateFormat('dd MMM yyyy').format(DateTime.now()),
      '',
      ...sections.expand((section) => [section, '']),
      'Please confirm availability and delivery. Thank you.',
    ].join('\n');
    setState(() => _sharing = true);
    try {
      await SharePlus.instance.share(ShareParams(text: message, subject: 'Coastal Pearl purchase requirement'));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open share menu: $error')));
    } finally {
      if (mounted) setState(() => _sharing = false);
    }
  }
}
