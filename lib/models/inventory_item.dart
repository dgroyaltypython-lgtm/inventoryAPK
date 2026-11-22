class InventoryItem {
  const InventoryItem({
    required this.code,
    required this.department,
    required this.category,
    required this.nameEn,
    required this.nameMr,
    required this.unit,
    required this.openingStock,
    required this.minimumStock,
    required this.currentStock,
    this.supplier,
    this.notes,
  });

  final String code;
  final String department;
  final String category;
  final String nameEn;
  final String nameMr;
  final String unit;
  final double openingStock;
  final double? minimumStock;
  final double currentStock;
  final String? supplier;
  final String? notes;

  bool get needsReorder =>
      minimumStock != null && currentStock <= minimumStock!;

  double get suggestedOrder {
    if (minimumStock == null) return 0;
    final difference = minimumStock! - currentStock;
    return difference <= 0 ? (needsReorder ? 1 : 0) : difference;
  }

  factory InventoryItem.fromMap(Map<String, Object?> map) {
    return InventoryItem(
      code: map['code'] as String,
      department: (map['department'] as String?) ?? 'Kitchen',
      category: (map['category'] as String?) ?? 'Other',
      nameEn: (map['name_en'] as String?) ?? '',
      nameMr: (map['name_mr'] as String?) ?? '',
      unit: (map['unit'] as String?) ?? 'pcs',
      openingStock: ((map['opening_stock'] as num?) ?? 0).toDouble(),
      minimumStock: (map['minimum_stock'] as num?)?.toDouble(),
      currentStock: ((map['current_stock'] as num?) ??
              (map['opening_stock'] as num?) ??
              0)
          .toDouble(),
      supplier: map['supplier'] as String?,
      notes: map['notes'] as String?,
    );
  }
}
