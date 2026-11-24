import 'dart:io';

import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../data/app_database.dart';

class ReportService {
  static final _dateFormat = DateFormat('dd MMM yyyy');
  static final _moneyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static Future<List<Map<String, Object?>>> _matchingRows({
    required DateTime start,
    required DateTime end,
    required String search,
  }) async {
    final rows = await AppDatabase.instance.getEntries(start: start, end: end);
    final query = search.trim().toLowerCase();
    if (query.isEmpty) return rows;
    return rows.where((row) => '${row['name_en']} ${row['name_mr']} ${row['item_code']} ${row['category']} ${row['entry_type']} ${row['supplier']}'.toLowerCase().contains(query)).toList();
  }

  static Future<String> exportCsv({
    required DateTime start,
    required DateTime end,
    required String label,
    String search = '',
  }) async {
    final rows = await _matchingRows(start: start, end: end, search: search);
    final values = <List<Object?>>[
      [
        'Date', 'Entry Type', 'Item Code', 'Item Name', 'Marathi Name',
        'Category', 'Quantity', 'Unit', 'Rate (INR)', 'Amount (INR)',
        'Supplier', 'Bill / Ref No.', 'Payment Mode', 'Entered By', 'Notes'
      ],
    ];
    for (final row in rows) {
      values.add([
        row['entry_date'], row['entry_type'], row['item_code'], row['name_en'],
        row['name_mr'], row['category'], row['quantity'], row['unit'],
        row['rate'] ?? '', row['amount'], row['supplier'] ?? '',
        row['bill_ref'] ?? '', row['payment_mode'] ?? '', row['staff'] ?? '',
        row['notes'] ?? '',
      ]);
    }
    final csv = values.map((row) => row.map(_csvCell).join(',')).join('\r\n');
    final file = await _reportFile(start, end, label, 'csv');
    await file.writeAsString('\uFEFF$csv', flush: true);
    return file.path;
  }

  static Future<String> exportPdf({
    required DateTime start,
    required DateTime end,
    required String label,
    String search = '',
  }) async {
    final rows = await _matchingRows(start: start, end: end, search: search);
    final purchases = rows
        .where((row) => row['entry_type'] == 'Purchase')
        .fold<double>(0, (sum, row) => sum + ((row['amount'] as num?)?.toDouble() ?? 0));
    final used = rows
        .where((row) => row['entry_type'] == 'Used')
        .fold<double>(0, (sum, row) => sum + ((row['quantity'] as num?)?.toDouble() ?? 0));
    final wastage = rows
        .where((row) => row['entry_type'] == 'Wastage')
        .fold<double>(0, (sum, row) => sum + ((row['quantity'] as num?)?.toDouble() ?? 0));

    final document = pw.Document();
    document.addPage(
      pw.MultiPage(
        maxPages: 200,
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (context) => pw.Container(
          padding: const pw.EdgeInsets.only(bottom: 10),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
                pw.Text('COASTAL PEARL', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.Text('Kitchen & Restaurant Inventory Report', style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
              ]),
              pw.Text(label.toUpperCase(), style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.teal800)),
            ],
          ),
        ),
        footer: (context) => pw.Container(
          alignment: pw.Alignment.centerRight,
          margin: const pw.EdgeInsets.only(top: 10),
          child: pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ),
        build: (context) => [
          pw.Text('${_dateFormat.format(start)}  —  ${_dateFormat.format(end)}', style: const pw.TextStyle(fontSize: 9)),
          pw.SizedBox(height: 12),
          pw.Row(children: [
            _summaryTile('PURCHASE VALUE', _moneyFormat.format(purchases)),
            pw.SizedBox(width: 10),
            _summaryTile('TOTAL USED', '${_qty(used)} units'),
            pw.SizedBox(width: 10),
            _summaryTile('WASTAGE', '${_qty(wastage)} units'),
            pw.SizedBox(width: 10),
            _summaryTile('ENTRIES', '${rows.length}'),
          ]),
          pw.SizedBox(height: 16),
          if (rows.isEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.all(22),
              alignment: pw.Alignment.center,
              child: pw.Text('No stock transactions were recorded for this period.'),
            )
          else
            pw.TableHelper.fromTextArray(
              headers: const ['Date', 'Type', 'Item', 'Category', 'Quantity', 'Unit', 'Rate', 'Amount', 'Supplier'],
              data: rows.map((row) => [
                row['entry_date']?.toString() ?? '',
                row['entry_type']?.toString() ?? '',
                row['name_en']?.toString() ?? '',
                row['category']?.toString() ?? '',
                _qty((row['quantity'] as num?)?.toDouble() ?? 0),
                row['unit']?.toString() ?? '',
                row['rate'] == null ? '—' : _moneyFormat.format((row['rate'] as num).toDouble()),
                _moneyFormat.format(((row['amount'] as num?) ?? 0).toDouble()),
                row['supplier']?.toString() ?? '—',
              ]).toList(),
              headerStyle: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.white),
              headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
              cellStyle: const pw.TextStyle(fontSize: 7.5),
              cellPadding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
              border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.4),
            ),
          pw.SizedBox(height: 12),
          pw.Text('Generated from the Coastal Pearl Inventory app. PDF item labels use English for consistent display.', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
        ],
      ),
    );

    final file = await _reportFile(start, end, label, 'pdf');
    await file.writeAsBytes(await document.save(), flush: true);
    return file.path;
  }

  static pw.Widget _summaryTile(String label, String value) => pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(9),
          decoration: pw.BoxDecoration(
            color: PdfColors.teal50,
            border: pw.Border.all(color: PdfColors.teal100),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
            pw.Text(label, style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
            pw.SizedBox(height: 4),
            pw.Text(value, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
          ]),
        ),
      );

  static Future<File> _reportFile(
    DateTime start,
    DateTime end,
    String label,
    String extension,
  ) async {
    final directory = await getApplicationDocumentsDirectory();
    final reportDir = Directory(p.join(directory.path, 'CoastalPearlReports'));
    await reportDir.create(recursive: true);
    final stamp = '${DateFormat('yyyyMMdd').format(start)}_${DateFormat('yyyyMMdd').format(end)}';
    final safeLabel = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '_');
    return File(p.join(reportDir.path, 'coastal_pearl_${safeLabel}_$stamp.$extension'));
  }

  static String _csvCell(Object? value) {
    final text = value?.toString() ?? '';
    return '"${text.replaceAll('"', '""')}"';
  }

  static String _qty(double value) => NumberFormat('#,##0.###').format(value);
}
