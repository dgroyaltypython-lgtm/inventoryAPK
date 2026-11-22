import 'package:cross_file/cross_file.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../data/app_database.dart';
import '../services/report_service.dart';
import 'app_shell.dart';
import 'widgets.dart';

enum ReportPeriod { daily, weekly, monthly, yearly, custom }

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  ReportPeriod _period = ReportPeriod.daily;
  DateTime _selectedDate = DateTime.now();
  DateTime _customStart = DateTime.now();
  DateTime _customEnd = DateTime.now();
  Map<String, double> _summary = {};
  int _entryCount = 0;
  bool _loading = true;
  bool _exporting = false;

  DateTime get _start {
    switch (_period) {
      case ReportPeriod.daily:
        return DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
      case ReportPeriod.weekly:
        final day = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
        return day.subtract(Duration(days: day.weekday - 1));
      case ReportPeriod.monthly:
        return DateTime(_selectedDate.year, _selectedDate.month, 1);
      case ReportPeriod.yearly:
        return DateTime(_selectedDate.year, 1, 1);
      case ReportPeriod.custom:
        return DateTime(_customStart.year, _customStart.month, _customStart.day);
    }
  }

  DateTime get _end {
    switch (_period) {
      case ReportPeriod.daily:
        return _start;
      case ReportPeriod.weekly:
        return _start.add(const Duration(days: 6));
      case ReportPeriod.monthly:
        return DateTime(_selectedDate.year, _selectedDate.month + 1, 0);
      case ReportPeriod.yearly:
        return DateTime(_selectedDate.year, 12, 31);
      case ReportPeriod.custom:
        return DateTime(_customEnd.year, _customEnd.month, _customEnd.day);
    }
  }

  String get _periodLabel {
    switch (_period) {
      case ReportPeriod.daily: return 'Daily report';
      case ReportPeriod.weekly: return 'Weekly report';
      case ReportPeriod.monthly: return 'Monthly report';
      case ReportPeriod.yearly: return 'Yearly report';
      case ReportPeriod.custom: return 'Custom date report';
    }
  }

  @override
  void initState() {
    super.initState();
    refreshSignal.addListener(_loadSummary);
    _loadSummary();
  }

  @override
  void dispose() {
    refreshSignal.removeListener(_loadSummary);
    super.dispose();
  }

  Future<void> _loadSummary() async {
    setState(() => _loading = true);
    final rows = await AppDatabase.instance.getEntries(start: _start, end: _end);
    double purchase = 0;
    double used = 0;
    double wastage = 0;
    for (final row in rows) {
      final type = row['entry_type']?.toString();
      if (type == 'Purchase') purchase += ((row['amount'] as num?) ?? 0).toDouble();
      if (type == 'Used') used += ((row['quantity'] as num?) ?? 0).toDouble();
      if (type == 'Wastage') wastage += ((row['quantity'] as num?) ?? 0).toDouble();
    }
    if (!mounted) return;
    setState(() {
      _entryCount = rows.length;
      _summary = {'purchase': purchase, 'used': used, 'wastage': wastage};
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: canvas,
        appBar: AppBar(title: const Text('Reports & exports', style: TextStyle(color: ink, fontWeight: FontWeight.w800)), backgroundColor: canvas, surfaceTintColor: Colors.transparent),
        body: ListView(padding: const EdgeInsets.fromLTRB(18, 5, 18, 28), children: [
          Container(
            padding: const EdgeInsets.all(17),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF0B353B), Color(0xFF0C7770)]), borderRadius: BorderRadius.circular(19)),
            child: const Row(children: [
              Icon(Icons.insert_chart_outlined_rounded, color: gold, size: 25),
              SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Reports that stay on your device', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14)),
                SizedBox(height: 4),
                Text('Export clear CSV and PDF files for accounts and stock reviews.', style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35)),
              ])),
            ]),
          ),
          const SizedBox(height: 22),
          const Text('REPORT PERIOD', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 10)),
          const SizedBox(height: 9),
          Wrap(spacing: 7, runSpacing: 7, children: [
            _periodChip(ReportPeriod.daily, 'Daily'),
            _periodChip(ReportPeriod.weekly, 'Weekly'),
            _periodChip(ReportPeriod.monthly, 'Monthly'),
            _periodChip(ReportPeriod.yearly, 'Yearly'),
            _periodChip(ReportPeriod.custom, 'Custom'),
          ]),
          const SizedBox(height: 14),
          if (_period != ReportPeriod.custom)
            OutlinedButton.icon(
              onPressed: _pickAnchorDate,
              icon: const Icon(Icons.calendar_month_outlined, color: teal),
              label: Text(_anchorLabel, style: const TextStyle(color: ink, fontWeight: FontWeight.w700)),
              style: _outlinedStyle(),
            )
          else
            Row(children: [
              Expanded(child: OutlinedButton.icon(onPressed: () => _pickCustomDate(isStart: true), icon: const Icon(Icons.event, color: teal), label: Text(DateFormat('dd MMM yy').format(_customStart), style: const TextStyle(color: ink, fontSize: 11)), style: _outlinedStyle())),
              const SizedBox(width: 8),
              Expanded(child: OutlinedButton.icon(onPressed: () => _pickCustomDate(isStart: false), icon: const Icon(Icons.event, color: teal), label: Text(DateFormat('dd MMM yy').format(_customEnd), style: const TextStyle(color: ink, fontSize: 11)), style: _outlinedStyle())),
            ]),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(color: const Color(0xFFE5F1ED), borderRadius: BorderRadius.circular(13)),
            child: Row(children: [
              const Icon(Icons.date_range_outlined, size: 18, color: teal),
              const SizedBox(width: 8),
              Expanded(child: Text('${DateFormat('dd MMM yyyy').format(_start)}  —  ${DateFormat('dd MMM yyyy').format(_end)}', style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 11.5))),
            ]),
          ),
          const SizedBox(height: 18),
          const Text('PERIOD SUMMARY', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 10)),
          const SizedBox(height: 9),
          if (_loading)
            const Padding(padding: EdgeInsets.all(24), child: Center(child: CircularProgressIndicator(color: teal)))
          else
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18), border: Border.all(color: const Color(0xFFE6EEEB))),
              child: Column(children: [
                Row(children: [
                  Expanded(child: _summaryValue('TRANSACTIONS', '$_entryCount', Icons.receipt_long_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryValue('PURCHASE VALUE', moneyText(_summary['purchase'] ?? 0), Icons.shopping_bag_outlined)),
                ]),
                const Divider(height: 24),
                Row(children: [
                  Expanded(child: _summaryValue('TOTAL USED', '${qtyText(_summary['used'] ?? 0)} units', Icons.restaurant_outlined)),
                  const SizedBox(width: 10),
                  Expanded(child: _summaryValue('WASTAGE', '${qtyText(_summary['wastage'] ?? 0)} units', Icons.delete_outline)),
                ]),
              ]),
            ),
          const SizedBox(height: 23),
          const Text('EXPORT REPORT', style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w800, letterSpacing: 0.8, fontSize: 10)),
          const SizedBox(height: 9),
          Row(children: [
            Expanded(child: _exportButton(label: 'Export CSV', subtitle: 'Excel-friendly', icon: Icons.table_view_outlined, onPressed: () => _export(isPdf: false))),
            const SizedBox(width: 10),
            Expanded(child: _exportButton(label: 'Export PDF', subtitle: 'Print-ready', icon: Icons.picture_as_pdf_outlined, onPressed: () => _export(isPdf: true))),
          ]),
          const SizedBox(height: 13),
          const Text('The report is saved inside CoastalPearlReports and then shared using Android’s share menu. Choose WhatsApp, email, Drive or another available app.', style: TextStyle(color: Colors.black54, fontSize: 11, height: 1.45)),
        ]),
      );

  String get _anchorLabel {
    switch (_period) {
      case ReportPeriod.daily: return DateFormat('EEEE, dd MMM yyyy').format(_selectedDate);
      case ReportPeriod.weekly: return 'Week of ${DateFormat('dd MMM yyyy').format(_start)}';
      case ReportPeriod.monthly: return DateFormat('MMMM yyyy').format(_selectedDate);
      case ReportPeriod.yearly: return '${_selectedDate.year}';
      case ReportPeriod.custom: return '';
    }
  }

  Widget _periodChip(ReportPeriod period, String label) => ChoiceChip(
        label: Text(label, style: TextStyle(color: _period == period ? Colors.white : ink, fontWeight: FontWeight.w700, fontSize: 11.5)),
        selected: _period == period,
        onSelected: (_) {
          setState(() => _period = period);
          _loadSummary();
        },
        selectedColor: teal,
        backgroundColor: Colors.white,
        side: BorderSide(color: _period == period ? teal : const Color(0xFFE0EAE7)),
        showCheckmark: false,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)),
      );

  ButtonStyle _outlinedStyle() => OutlinedButton.styleFrom(backgroundColor: Colors.white, side: const BorderSide(color: Color(0xFFE0EAE7)), padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13), alignment: Alignment.centerLeft, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(13)));

  Widget _summaryValue(String label, String value, IconData icon) => Row(children: [
        Container(width: 34, height: 34, decoration: BoxDecoration(color: const Color(0xFFEAF4F1), borderRadius: BorderRadius.circular(11)), child: Icon(icon, color: teal, size: 17)),
        const SizedBox(width: 9),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(color: Colors.black45, fontSize: 8.8, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
          const SizedBox(height: 3),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(color: ink, fontSize: 13, fontWeight: FontWeight.w900)),
        ])),
      ]);

  Widget _exportButton({required String label, required String subtitle, required IconData icon, required VoidCallback onPressed}) => FilledButton(
        onPressed: _exporting ? null : onPressed,
        style: FilledButton.styleFrom(backgroundColor: Colors.white, foregroundColor: teal, elevation: 0, padding: const EdgeInsets.all(15), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: const BorderSide(color: Color(0xFFDDE9E5)))),
        child: Row(children: [
          Icon(icon, color: teal, size: 23),
          const SizedBox(width: 9),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(color: ink, fontSize: 12, fontWeight: FontWeight.w800)),
            Text(subtitle, style: const TextStyle(color: Colors.black45, fontSize: 10)),
          ])),
        ]),
      );

  Future<void> _pickAnchorDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked == null) return;
    setState(() => _selectedDate = picked);
    _loadSummary();
  }

  Future<void> _pickCustomDate({required bool isStart}) async {
    final current = isStart ? _customStart : _customEnd;
    final picked = await showDatePicker(context: context, initialDate: current, firstDate: DateTime(2020), lastDate: DateTime(2100));
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _customStart = picked;
        if (_customEnd.isBefore(_customStart)) _customEnd = picked;
      } else {
        _customEnd = picked;
        if (_customEnd.isBefore(_customStart)) _customStart = picked;
      }
    });
    _loadSummary();
  }

  Future<void> _export({required bool isPdf}) async {
    setState(() => _exporting = true);
    try {
      final path = isPdf
          ? await ReportService.exportPdf(start: _start, end: _end, label: _periodLabel)
          : await ReportService.exportCsv(start: _start, end: _end, label: _periodLabel);
      if (!mounted) return;
      await SharePlus.instance.share(ShareParams(
        files: [XFile(path)],
        subject: 'Coastal Pearl $_periodLabel',
        text: 'Coastal Pearl $_periodLabel · ${DateFormat('dd MMM yyyy').format(_start)} to ${DateFormat('dd MMM yyyy').format(_end)}',
      ));
    } catch (error) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export failed: $error'), backgroundColor: Colors.red.shade700));
    } finally {
      if (mounted) setState(() => _exporting = false);
    }
  }
}
