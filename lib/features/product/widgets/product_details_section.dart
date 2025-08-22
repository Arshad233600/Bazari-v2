import 'package:flutter/material.dart';
import '../form/form_types.dart';

class ProductDetailsSection extends StatelessWidget {
  const ProductDetailsSection({
    super.key,
    required this.categoryId,
    required this.details,
  });

  final String categoryId;
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final schema = ProductSchemas.byId(categoryId);
    final th = Theme.of(context);

    List<Widget> rows = [];
    for (final f in schema.fields) {
      final v = details[f.key];
      if (v == null) continue;

      Widget valueWidget;
      switch (f.type) {
        case FieldType.toggle:
          valueWidget = Text(v == true ? 'بله' : 'خیر');
          break;
        case FieldType.multiselect:
          final list = List<String>.from(v);
          valueWidget = Wrap(
            spacing: 6,
            runSpacing: -6,
            children: list.map((e) => Chip(label: Text(e))).toList(),
          );
          break;
        case FieldType.repeater:
          final list = List<String>.from(v);
          valueWidget = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: list.map((e) => Row(
              children: [
                const Icon(Icons.check_circle_outline, size: 16),
                const SizedBox(width: 6),
                Expanded(child: Text(e)),
              ],
            )).toList(),
          );
          break;
        default:
          final text = (f.unit != null && v is num) ? '$v ${f.unit}' : v.toString();
          valueWidget = Text(text);
      }

      rows.add(Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: _KV(label: f.label, child: valueWidget),
      ));
    }

    if (rows.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: th.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('جزئیات ${schema.title}',
              style: th.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          ...rows,
        ],
      ),
    );
  }
}

class _KV extends StatelessWidget {
  const _KV({required this.label, required this.child});
  final String label;
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label,
              style: th.textTheme.bodyMedium?.copyWith(
                color: th.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              )),
        ),
        const SizedBox(width: 8),
        Expanded(child: child),
      ],
    );
  }
}
