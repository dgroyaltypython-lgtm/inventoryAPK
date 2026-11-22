import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

const Color ink = Color(0xFF15373A);
const Color teal = Color(0xFF0B7773);
const Color gold = Color(0xFFE5AD4C);
const Color canvas = Color(0xFFF4F7F6);

String qtyText(num value) => NumberFormat('#,##0.###').format(value);
String moneyText(num value) => NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0).format(value);

class PageHeader extends StatelessWidget {
  const PageHeader({required this.eyebrow, required this.title, this.subtitle, super.key});
  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(eyebrow.toUpperCase(), style: Theme.of(context).textTheme.labelSmall?.copyWith(color: teal, letterSpacing: 1.3, fontWeight: FontWeight.w800)),
          const SizedBox(height: 5),
          Text(title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: ink, fontWeight: FontWeight.w800)),
          if (subtitle != null) ...[
            const SizedBox(height: 5),
            Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.black54)),
          ],
        ]),
      );
}

class MetricCard extends StatelessWidget {
  const MetricCard({required this.label, required this.value, required this.icon, this.tint = teal, this.helper, super.key});
  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final String? helper;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE7EEEC)),
          boxShadow: [BoxShadow(color: ink.withValues(alpha: 0.035), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            height: 36,
            width: 36,
            decoration: BoxDecoration(color: tint.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: tint, size: 19),
          ),
          const SizedBox(height: 14),
          Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800)),
          const SizedBox(height: 3),
          Text(label, style: Theme.of(context).textTheme.labelMedium?.copyWith(color: Colors.black54, fontWeight: FontWeight.w600)),
          if (helper != null) ...[
            const SizedBox(height: 4),
            Text(helper!, style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black45)),
          ],
        ]),
      );
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {this.action, this.onAction, super.key});
  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
        child: Row(children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(color: ink, fontWeight: FontWeight.w800))),
          if (action != null)
            TextButton(onPressed: onAction, child: Text(action!, style: const TextStyle(color: teal, fontWeight: FontWeight.w700))),
        ]),
      );
}

class StockStatus extends StatelessWidget {
  const StockStatus({required this.low, super.key});
  final bool low;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
        decoration: BoxDecoration(
          color: low ? const Color(0xFFFFF1E8) : const Color(0xFFE8F5EF),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(low ? 'REORDER' : 'IN STOCK', style: TextStyle(color: low ? const Color(0xFFB45309) : const Color(0xFF17744E), fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.35)),
      );
}

class EmptyState extends StatelessWidget {
  const EmptyState({required this.title, required this.message, this.icon = Icons.inventory_2_outlined, super.key});
  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(icon, size: 42, color: teal.withValues(alpha: 0.5)),
          const SizedBox(height: 12),
          Text(title, style: const TextStyle(color: ink, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 5),
          Text(message, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        ]),
      );
}
