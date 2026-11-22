import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('catalogue contains the workbook items and expanded non-veg items', () async {
    final file = File('assets/inventory_seed.json');
    final entries = (jsonDecode(await file.readAsString()) as List)
        .cast<Map<String, dynamic>>();

    expect(entries, hasLength(359));
    final names = entries.map((entry) => entry['nameEn'] as String).toSet();
    expect(names, contains('Crab'));
    expect(names, contains('Eggs'));
    expect(names, contains('Saundala (local fish; verify name)'));
    expect(names, contains('Surmai / king fish'));
    expect(names, contains('Mackerel / bangda'));
    expect(names, contains('Pomfret'));
    expect(names, contains('Bombil / Bombay duck'));
    expect(names, contains('Tarli / Indian oil sardine'));
    expect(names, contains('Mutton / goat meat'));
  });
}
