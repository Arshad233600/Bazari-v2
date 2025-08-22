import 'package:flutter/material.dart';
import 'package:bazari_8656/data/mock_data.dart';

typedef OnCategoryTap = void Function(CategorySpec? cat);

class CategoryChipBar extends StatelessWidget {
  final OnCategoryTap onTap;
  final String? selectedId;
  const CategoryChipBar({super.key, required this.onTap, required this.selectedId});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          ChoiceChip(
            label: const Text('All'),
            selected: selectedId == null,
            onSelected: (_) => onTap(null),
          ),
          const SizedBox(width: 8),
          for (final c in kCategories24) ...[
            ChoiceChip(
              label: Text('${c.emoji} ${c.label}'),
              selected: selectedId == c.id,
              onSelected: (_) => onTap(c),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
