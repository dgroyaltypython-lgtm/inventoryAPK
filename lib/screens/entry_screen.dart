import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../data/app_database.dart';
import '../models/inventory_item.dart';
import 'app_shell.dart';
import 'widgets.dart';

class EntryScreen extends StatefulWidget {
  const EntryScreen({super.key});

  @override
  State<EntryScreen> createState() => _EntryScreenState();
}

class _EntryScreenState extends State<EntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantity = TextEditingController();
  final _rate = TextEditingController();
  final _supplier = TextEditingController();
  final _billRef = TextEditingController();
  final _staff = TextEditingController();
  final _notes = TextEditingController();
  final _itemSearch = TextEditingController();

  List<InventoryItem> _items = [];
  String? _selectedCode;
  String _type = 'Purchase';
  String _paymentMode = 'UPI';
  DateTime _date = DateTime.now();
  bool _saving = false;

  InventoryItem? get _selectedItem {
    for (final item in _items) {
      if (item.code == _selectedCode) return item;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _loadItems();
    refreshSignal.addListener(_loadItems);
  }

  @override
  void dispose() {
    refreshSignal.removeListener(_loadItems);
    _quantity.dispose();
    _rate.dispose();
    _supplier.dispose();
    _billRef.dispose();
    _staff.dispose();
    _notes.dispose();
    _itemSearch.dispose();
    super.dispose();
  }

  Future<void> _loadItems() async {
    final items = await AppDatabase.instance.getInventory();
    if (!mounted) return;
    setState(() {
      _items = items;
      if (_selectedCode == null && items.isNotEmpty) _selectedCode = items.first.code;
      if (_selectedCode != null && !items.any((item) => item.code == _selectedCode)) {
        _selectedCode = items.isEmpty ? null : items.first.code;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedItem;
    final query = _itemSearch.text.trim().toLowerCase();
    final visibleItems = _items.where((item) => query.isEmpty || '${item.nameEn} ${item.nameMr} ${item.code} ${item.category}'.toLowerCase().contains(query)).toList();
    return Scaffold(
      backgroundColor: canvas,
      appBar: AppBar(
        title: const Text('Stock entry', style: TextStyle(color: ink, fontWeight: FontWeight.w800)),
        backgroundColor: canvas,
        surfaceTintColor: Colors.transparent,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 28),
          children: [
            Container(
              padding: const EdgeInsets.all(17),
              decoration: BoxDecoration(color: const Color(0xFFE4F1ED), borderRadius: BorderRadius.circular(18)),
              child: const Row(children: [
                Icon(Icons.fact_check_outlined, color: teal, size: 22),
                SizedBox(width: 11),
                Expanded(child: Text('Record each stock movement. Your current balance updates automatically.', style: TextStyle(color: ink, fontSize: 12, height: 1.4, fontWeight: FontWeight.w600))),
              ]),
            ),
            const SizedBox(height: 18),
            const Text('TRANSACTION TYPE', style: TextStyle(color: Colors.black54, letterSpacing: 0.9, fontWeight: FontWeight.w800, fontSize: 10)),
            const SizedBox(height: 9),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Purchase', label: Text('Purchase'), icon: Icon(Icons.add_shopping_cart_outlined)),
                ButtonSegment(value: 'Used', label: Text('Used'), icon: Icon(Icons.restaurant_outlined)),
                ButtonSegment(value: 'Wastage', label: Text('Wastage'), icon: Icon(Icons.delete_outline)),
              ],
              selected: {_type},
              onSelectionChanged: (value) => setState(() => _type = value.first),
              style: SegmentedButton.styleFrom(selectedBackgroundColor: teal, selectedForegroundColor: Colors.white, textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
              showSelectedIcon: false,
            ),
            const SizedBox(height: 19),
            _label('SEARCH ITEM'),
            TextField(
              controller: _itemSearch,
              onChanged: (_) => setState(() {}),
              decoration: _decoration('Search English / Marathi name, category or code', Icons.search).copyWith(
                suffixIcon: _itemSearch.text.isEmpty ? null : IconButton(onPressed: () { _itemSearch.clear(); setState(() {}); }, icon: const Icon(Icons.close)),
              ),
            ),
            const SizedBox(height: 12),
            _label('ITEM'),
            DropdownButtonFormField<String>(
              value: _selectedCode,
              isExpanded: true,
              decoration: _decoration('Select item', Icons.inventory_2_outlined),
              items: (visibleItems.any((item) => item.code == _selectedCode) || _selectedCode == null ? visibleItems : [...visibleItems, ..._items.where((item) => item.code == _selectedCode)]).map((item) => DropdownMenuItem<String>(
                value: item.code,
                child: Text('${item.nameEn} · ${item.code}', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedCode = value),
              validator: (value) => value == null ? 'Choose an inventory item' : null,
            ),
            if (selected != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(children: [
                  Text(selected.nameMr, style: const TextStyle(color: Colors.black54, fontSize: 11)),
                  const Spacer(),
                  Text('Current: ${qtyText(selected.currentStock)} ${selected.unit}', style: const TextStyle(color: teal, fontSize: 11, fontWeight: FontWeight.w800)),
                ]),
              ),
            const SizedBox(height: 17),
            Row(children: [
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label('QUANTITY'),
                TextFormField(
                  controller: _quantity,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('e.g. 5', Icons.scale_outlined),
                  validator: (value) {
                    final number = double.tryParse(value ?? '');
                    return number == null || number <= 0 ? 'Enter quantity' : null;
                  },
                ),
              ])),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _label(_type == 'Purchase' ? 'RATE / UNIT (₹)' : 'RATE (OPTIONAL)'),
                TextFormField(
                  controller: _rate,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: _decoration('0.00', Icons.currency_rupee),
                  validator: (value) {
                    if (_type != 'Purchase' || (value ?? '').trim().isEmpty) return null;
                    final number = double.tryParse(value!);
                    return number == null || number < 0 ? 'Check rate' : null;
                  },
                ),
              ])),
            ]),
            const SizedBox(height: 17),
            _label('ENTRY DATE'),
            OutlinedButton.icon(
              onPressed: _pickDate,
              icon: const Icon(Icons.calendar_month_outlined, color: teal),
              label: Text(DateFormat('EEEE, dd MMM yyyy').format(_date), style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
              style: OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE0EAE7)), padding: const EdgeInsets.symmetric(vertical: 14), alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
            if (_type == 'Purchase') ...[
              const SizedBox(height: 17),
              _label('SUPPLIER'),
              TextFormField(controller: _supplier, decoration: _decoration('Supplier name (optional)', Icons.storefront_outlined)),
              const SizedBox(height: 14),
              _label('PAYMENT MODE'),
              DropdownButtonFormField<String>(
                value: _paymentMode,
                decoration: _decoration('Payment mode', Icons.payments_outlined),
                items: const ['UPI', 'Cash', 'Card', 'Credit', 'Bank Transfer'].map((value) => DropdownMenuItem(value: value, child: Text(value))).toList(),
                onChanged: (value) => setState(() => _paymentMode = value ?? 'UPI'),
              ),
              const SizedBox(height: 14),
              _label('BILL / REFERENCE NO.'),
              TextFormField(controller: _billRef, decoration: _decoration('Bill number (optional)', Icons.receipt_long_outlined)),
            ],
            const SizedBox(height: 17),
            _label('ENTERED BY'),
            TextFormField(controller: _staff, decoration: _decoration('Staff name (optional)', Icons.person_outline)),
            const SizedBox(height: 14),
            _label('NOTES'),
            TextFormField(controller: _notes, maxLines: 2, decoration: _decoration('Special notes (optional)', Icons.notes_outlined)),
            const SizedBox(height: 23),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _saving || _items.isEmpty ? null : _save,
                icon: _saving ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Icon(Icons.check_circle_outline),
                label: Text(_saving ? 'Saving entry…' : 'Save stock entry'),
                style: FilledButton.styleFrom(backgroundColor: teal, foregroundColor: Colors.white, disabledBackgroundColor: teal.withValues(alpha: 0.35), padding: const EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)), textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String value) => Padding(
        padding: const EdgeInsets.only(bottom: 7),
        child: Text(value, style: const TextStyle(color: Colors.black54, letterSpacing: 0.8, fontWeight: FontWeight.w800, fontSize: 10)),
      );

  InputDecoration _decoration(String hint, IconData icon) => InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon, color: teal, size: 18),
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EAE7))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: Color(0xFFE0EAE7))),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: teal, width: 1.5)),
      );

  Future<void> _pickDate() async {
    final picked = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedCode == null) return;
    setState(() => _saving = true);
    try {
      await AppDatabase.instance.addEntry(
        date: _date,
        type: _type,
        itemCode: _selectedCode!,
        quantity: double.parse(_quantity.text.trim()),
        rate: double.tryParse(_rate.text.trim()),
        supplier: _supplier.text,
        billRef: _billRef.text,
        paymentMode: _type == 'Purchase' ? _paymentMode : null,
        staff: _staff.text,
        notes: _notes.text,
      );
      refreshSignal.value++;
      _quantity.clear();
      _rate.clear();
      _billRef.clear();
      _notes.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$_type entry saved. Current stock has been updated.'), backgroundColor: teal));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save entry: $error'), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}
