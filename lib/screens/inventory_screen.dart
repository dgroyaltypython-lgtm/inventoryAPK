import 'package:flutter/material.dart';

import '../data/app_database.dart';
import '../models/inventory_item.dart';
import 'app_shell.dart';
import 'widgets.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  final _searchController = TextEditingController();
  List<InventoryItem> _items = [];
  List<String> _categories = ['All'];
  String _category = 'All';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_loadItems);
    refreshSignal.addListener(_loadItems);
    _loadItems();
  }

  @override
  void dispose() {
    refreshSignal.removeListener(_loadItems);
    _searchController.removeListener(_loadItems);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    try {
      final values = await Future.wait<Object>([
        AppDatabase.instance.getInventory(search: _searchController.text, category: _category),
        AppDatabase.instance.getCategories(),
      ]);
      if (!mounted) return;
      setState(() {
        _items = values[0] as List<InventoryItem>;
        _categories = ['All', ...(values[1] as List<String>)];
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grouped = <String, List<InventoryItem>>{};
    for (final item in _items) {
      grouped.putIfAbsent(item.category, () => []).add(item);
    }
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: const Text('Inventory', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 14),
            child: IconButton.filledTonal(
              onPressed: _showAddItem,
              tooltip: 'Add item',
              icon: const Icon(Icons.add, color: teal),
            ),
          ),
        ],
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 5, 18, 12),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search item, Marathi name or item code',
              prefixIcon: const Icon(Icons.search, color: teal),
              suffixIcon: _searchController.text.isEmpty
                  ? null
                  : IconButton(onPressed: _searchController.clear, icon: const Icon(Icons.close)),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
        ),
        SizedBox(
          height: 42,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 7),
            itemBuilder: (context, index) {
              final value = _categories[index];
              final selected = value == _category;
              return ChoiceChip(
                label: Text(value, style: TextStyle(fontSize: 11.5, color: selected ? Colors.white : ink, fontWeight: FontWeight.w700)),
                selected: selected,
                onSelected: (_) => setState(() {
                  _category = value;
                  _loading = true;
                  _loadItems();
                }),
                selectedColor: teal,
                backgroundColor: Colors.white,
                side: BorderSide(color: selected ? teal : const Color(0xFFE1EAE7)),
                showCheckmark: false,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: teal))
              : _items.isEmpty
                  ? const EmptyState(title: 'No matching items', message: 'Try another keyword or add a new inventory item.')
                  : RefreshIndicator(
                      color: teal,
                      onRefresh: _loadItems,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(18, 5, 18, 28),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(2, 4, 2, 10),
                            child: Row(children: [
                              Text('${_items.length} items', style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 12)),
                              const Spacer(),
                              const Icon(Icons.swipe_down_alt_outlined, color: Colors.black38, size: 15),
                              const SizedBox(width: 4),
                              const Text('Tap an item to edit minimum', style: TextStyle(color: Colors.black45, fontSize: 10.5)),
                            ]),
                          ),
                          for (final group in grouped.entries) ...[
                            Padding(
                              padding: const EdgeInsets.fromLTRB(2, 12, 2, 8),
                              child: Row(children: [
                                Expanded(child: Text(group.key, style: const TextStyle(color: teal, fontWeight: FontWeight.w800, fontSize: 13))),
                                Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: const Color(0xFFE4F1ED), borderRadius: BorderRadius.circular(10)), child: Text('${group.value.length}', style: const TextStyle(color: teal, fontSize: 10, fontWeight: FontWeight.w800))),
                              ]),
                            ),
                            for (final item in group.value) _itemCard(item),
                          ],
                        ],
                      ),
                    ),
        ),
      ]),
    );
  }

  Widget _itemCard(InventoryItem item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(17),
          child: InkWell(
            borderRadius: BorderRadius.circular(17),
            onTap: () => _showItemOptions(item),
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 13, 13, 13),
              decoration: BoxDecoration(borderRadius: BorderRadius.circular(17), border: Border.all(color: const Color(0xFFE6EEEB))),
              child: Row(children: [
                Container(width: 42, height: 42, decoration: BoxDecoration(color: const Color(0xFFEAF4F1), borderRadius: BorderRadius.circular(13)), child: Icon(_iconFor(item.category), color: teal, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.nameEn, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13)),
                  const SizedBox(height: 2),
                  Text('${item.nameMr}  ·  ${item.code}', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: Colors.black45, fontSize: 10.5)),
                  const SizedBox(height: 7),
                  Row(children: [
                    Text('Min: ${item.minimumStock == null ? 'Not set' : qtyText(item.minimumStock!)}', style: const TextStyle(color: Colors.black54, fontSize: 10)),
                    const SizedBox(width: 8),
                    StockStatus(low: item.needsReorder),
                  ]),
                ])),
                const SizedBox(width: 8),
                Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  Text(qtyText(item.currentStock), style: TextStyle(color: item.needsReorder ? const Color(0xFFB45309) : ink, fontWeight: FontWeight.w900, fontSize: 16)),
                  Text(item.unit, style: const TextStyle(color: Colors.black45, fontSize: 10)),
                ]),
              ]),
            ),
          ),
        ),
      );

  IconData _iconFor(String category) {
    final lower = category.toLowerCase();
    if (lower.contains('seafood') || lower.contains('fish')) return Icons.set_meal_outlined;
    if (lower.contains('egg') || lower.contains('poultry') || lower.contains('chicken')) return Icons.egg_alt_outlined;
    if (lower.contains('meat') || lower.contains('mutton')) return Icons.restaurant_menu_outlined;
    if (lower.contains('vegetable')) return Icons.eco_outlined;
    return Icons.inventory_2_outlined;
  }

  Future<void> _showItemOptions(InventoryItem item) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 7, 22, 26),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nameEn, style: const TextStyle(color: ink, fontSize: 19, fontWeight: FontWeight.w800)),
          Text('${item.nameMr} · ${item.code}', style: const TextStyle(color: Colors.black54, fontSize: 12)),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _detailBox('CURRENT STOCK', '${qtyText(item.currentStock)} ${item.unit}')),
            const SizedBox(width: 10),
            Expanded(child: _detailBox('MINIMUM STOCK', item.minimumStock == null ? 'Not set' : '${qtyText(item.minimumStock!)} ${item.unit}')),
          ]),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.pop(sheetContext);
                _editMinimum(item);
              },
              icon: const Icon(Icons.tune),
              label: const Text('Set / edit minimum stock'),
              style: FilledButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 14)),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _detailBox(String label, String value) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(color: canvas, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 0.7)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 13)),
        ]),
      );

  Future<void> _editMinimum(InventoryItem item) async {
    final controller = TextEditingController(text: item.minimumStock?.toString() ?? '');
    final result = await showDialog<double?>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Minimum stock level'),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.nameEn, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          TextField(controller: controller, autofocus: true, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: InputDecoration(labelText: 'Minimum quantity (${item.unit})', hintText: 'e.g. 5', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, -1), child: const Text('Clear minimum')),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Cancel')),
          FilledButton(onPressed: () {
            final parsed = double.tryParse(controller.text.trim());
            if (controller.text.trim().isNotEmpty && (parsed == null || parsed < 0)) return;
            Navigator.pop(dialogContext, parsed);
          }, child: const Text('Save')),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await AppDatabase.instance.updateMinimumStock(item.code, result < 0 ? null : result);
    refreshSignal.value++;
    _loadItems();
  }

  Future<void> _showAddItem() async {
    final name = TextEditingController();
    final marathi = TextEditingController();
    final category = TextEditingController(text: 'Seafood - Local Fish');
    final opening = TextEditingController(text: '0');
    final minimum = TextEditingController(text: '1');
    String unit = 'kg';
    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(builder: (context, updateDialog) => AlertDialog(
        title: const Text('Add inventory item'),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: name, decoration: const InputDecoration(labelText: 'Item name (English)')),
            TextField(controller: marathi, decoration: const InputDecoration(labelText: 'Item name (Marathi)')),
            TextField(controller: category, decoration: const InputDecoration(labelText: 'Category')),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(value: unit, decoration: const InputDecoration(labelText: 'Unit'), items: const [
              DropdownMenuItem(value: 'kg', child: Text('kg')), DropdownMenuItem(value: 'g', child: Text('g')),
              DropdownMenuItem(value: 'ltr', child: Text('ltr')), DropdownMenuItem(value: 'ml', child: Text('ml')),
              DropdownMenuItem(value: 'pcs', child: Text('pcs')), DropdownMenuItem(value: 'tray', child: Text('tray')),
              DropdownMenuItem(value: 'pack', child: Text('pack')), DropdownMenuItem(value: 'box', child: Text('box')),
            ], onChanged: (value) => updateDialog(() => unit = value ?? 'kg')),
            TextField(controller: opening, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Opening stock')),
            TextField(controller: minimum, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Minimum stock')),
          ])),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Add item')),
        ],
      )),
    );
    if (saved == true && name.text.trim().isNotEmpty && category.text.trim().isNotEmpty) {
      await AppDatabase.instance.addCustomItem(
        nameEn: name.text,
        nameMr: marathi.text,
        category: category.text,
        unit: unit,
        openingStock: double.tryParse(opening.text) ?? 0,
        minimumStock: double.tryParse(minimum.text),
      );
      refreshSignal.value++;
      await _loadItems();
    }
    name.dispose();
    marathi.dispose();
    category.dispose();
    opening.dispose();
    minimum.dispose();
  }
}
