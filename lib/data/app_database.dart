import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../models/inventory_item.dart';

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  Future<Database> get database async => _db ??= await _open();

  Future<Database> _open() async {
    final base = await getDatabasesPath();
    final filePath = p.join(base, 'coastal_pearl_inventory.db');
    return openDatabase(
      filePath,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE inventory (
            code TEXT PRIMARY KEY,
            department TEXT NOT NULL,
            category TEXT NOT NULL,
            name_en TEXT NOT NULL,
            name_mr TEXT NOT NULL,
            unit TEXT NOT NULL,
            opening_stock REAL NOT NULL DEFAULT 0,
            minimum_stock REAL,
            supplier TEXT,
            notes TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE stock_entries (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            entry_date TEXT NOT NULL,
            entry_type TEXT NOT NULL,
            item_code TEXT NOT NULL,
            quantity REAL NOT NULL,
            rate REAL,
            amount REAL NOT NULL DEFAULT 0,
            supplier TEXT,
            bill_ref TEXT,
            payment_mode TEXT,
            staff TEXT,
            notes TEXT,
            FOREIGN KEY(item_code) REFERENCES inventory(code)
          )
        ''');
        await db.execute(
          'CREATE INDEX idx_stock_entries_date ON stock_entries(entry_date)',
        );
        await db.execute(
          'CREATE INDEX idx_stock_entries_item ON stock_entries(item_code)',
        );
        await _seed(db);
      },
      onOpen: _seed,
    );
  }

  Future<void> _seed(Database db) async {
    final raw = await rootBundle.loadString('assets/inventory_seed.json');
    final items = jsonDecode(raw) as List<dynamic>;
    final batch = db.batch();
    for (final row in items.cast<Map<String, dynamic>>()) {
      batch.insert(
        'inventory',
        {
          'code': row['code'],
          'department': row['department'] ?? 'Kitchen',
          'category': row['category'] ?? 'Other',
          'name_en': row['nameEn'] ?? '',
          'name_mr': row['nameMr'] ?? '',
          'unit': row['unit'] ?? 'pcs',
          'opening_stock': (row['openingStock'] as num?)?.toDouble() ?? 0,
          'minimum_stock': (row['minimumStock'] as num?)?.toDouble(),
          'supplier': row['supplier'],
          'notes': row['notes'],
        },
        conflictAlgorithm: ConflictAlgorithm.ignore,
      );
    }
    await batch.commit(noResult: true);
  }

  String _inventoryQuery({required bool includeCurrentStock}) {
    final stockExpression = '''
      COALESCE(i.opening_stock, 0) + COALESCE(SUM(
        CASE
          WHEN e.entry_type = 'Purchase' THEN e.quantity
          WHEN e.entry_type IN ('Used', 'Wastage') THEN -e.quantity
          ELSE 0
        END
      ), 0)
    ''';
    return '''
      SELECT i.*${includeCurrentStock ? ', $stockExpression AS current_stock' : ', i.opening_stock AS current_stock'}
      FROM inventory i
      LEFT JOIN stock_entries e ON e.item_code = i.code
    ''';
  }

  Future<List<InventoryItem>> getInventory({
    String search = '',
    String? category,
  }) async {
    final db = await database;
    final where = <String>[];
    final args = <Object?>[];
    if (category != null && category != 'All') {
      where.add('i.category = ?');
      args.add(category);
    }
    if (search.trim().isNotEmpty) {
      where.add('(i.name_en LIKE ? OR i.name_mr LIKE ? OR i.code LIKE ?)');
      final query = '%${search.trim()}%';
      args.addAll([query, query, query]);
    }
    final sql = '''
      ${_inventoryQuery(includeCurrentStock: true)}
      ${where.isEmpty ? '' : 'WHERE ${where.join(' AND ')}'}
      GROUP BY i.code
      ORDER BY i.category COLLATE NOCASE, i.name_en COLLATE NOCASE
    ''';
    final rows = await db.rawQuery(sql, args);
    return rows.map(InventoryItem.fromMap).toList();
  }

  Future<List<String>> getCategories() async {
    final db = await database;
    final rows = await db.rawQuery(
      'SELECT DISTINCT category FROM inventory ORDER BY category COLLATE NOCASE',
    );
    return rows.map((row) => row['category'] as String).toList();
  }

  Future<List<InventoryItem>> getReorderItems() async {
    final all = await getInventory();
    return all.where((item) => item.needsReorder).toList();
  }

  Future<void> addEntry({
    required DateTime date,
    required String type,
    required String itemCode,
    required double quantity,
    double? rate,
    String? supplier,
    String? billRef,
    String? paymentMode,
    String? staff,
    String? notes,
  }) async {
    if (quantity <= 0) throw ArgumentError('Quantity must be greater than zero.');
    final db = await database;
    await db.insert('stock_entries', {
      'entry_date': DateFormat('yyyy-MM-dd').format(date),
      'entry_type': type,
      'item_code': itemCode,
      'quantity': quantity,
      'rate': rate,
      'amount': type == 'Purchase' && rate != null ? quantity * rate : 0,
      'supplier': _nullIfBlank(supplier),
      'bill_ref': _nullIfBlank(billRef),
      'payment_mode': _nullIfBlank(paymentMode),
      'staff': _nullIfBlank(staff),
      'notes': _nullIfBlank(notes),
    });
  }

  Future<void> updateMinimumStock(String code, double? minimum) async {
    final db = await database;
    await db.update(
      'inventory',
      {'minimum_stock': minimum},
      where: 'code = ?',
      whereArgs: [code],
    );
  }

  Future<void> addCustomItem({
    required String nameEn,
    required String nameMr,
    required String category,
    required String unit,
    required double openingStock,
    double? minimumStock,
  }) async {
    final db = await database;
    final code = 'USR-${DateTime.now().microsecondsSinceEpoch}';
    await db.insert('inventory', {
      'code': code,
      'department': 'Kitchen',
      'category': category,
      'name_en': nameEn.trim(),
      'name_mr': nameMr.trim(),
      'unit': unit,
      'opening_stock': openingStock,
      'minimum_stock': minimumStock,
    });
  }

  Future<List<Map<String, Object?>>> getEntries({
    required DateTime start,
    required DateTime end,
  }) async {
    final db = await database;
    final startText = DateFormat('yyyy-MM-dd').format(start);
    final endText = DateFormat('yyyy-MM-dd').format(end);
    return db.rawQuery('''
      SELECT e.*, i.name_en, i.name_mr, i.category, i.unit
      FROM stock_entries e
      INNER JOIN inventory i ON i.code = e.item_code
      WHERE e.entry_date >= ? AND e.entry_date <= ?
      ORDER BY e.entry_date DESC, e.id DESC
    ''', [startText, endText]);
  }

  Future<List<Map<String, Object?>>> getRecentEntries({int limit = 8}) async {
    final db = await database;
    return db.rawQuery('''
      SELECT e.*, i.name_en, i.name_mr, i.category, i.unit
      FROM stock_entries e
      INNER JOIN inventory i ON i.code = e.item_code
      ORDER BY e.entry_date DESC, e.id DESC
      LIMIT ?
    ''', [limit]);
  }

  Future<Map<String, Object>> getDashboardStats() async {
    final all = await getInventory();
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final db = await database;
    final money = await db.rawQuery('''
      SELECT
        COALESCE(SUM(CASE WHEN entry_type = 'Purchase' THEN amount ELSE 0 END), 0) AS purchases,
        COALESCE(SUM(CASE WHEN entry_type = 'Used' THEN quantity ELSE 0 END), 0) AS used_qty,
        COUNT(*) AS entries
      FROM stock_entries WHERE entry_date = ?
    ''', [today]);
    final result = money.first;
    return {
      'items': all.length,
      'lowStock': all.where((item) => item.needsReorder).length,
      'purchases': (result['purchases'] as num).toDouble(),
      'usedQty': (result['used_qty'] as num).toDouble(),
      'entries': (result['entries'] as num).toInt(),
    };
  }

  String? _nullIfBlank(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value.trim();
  }
}
