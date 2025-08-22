import 'package:flutter/material.dart';

class HorizontalChips extends StatelessWidget {
  final List<String> items;
  final void Function(String)? onTap;
  final EdgeInsets padding;

  const HorizontalChips({
    super.key,
    required this.items,
    this.onTap,
    this.padding = const EdgeInsets.symmetric(vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: padding,
      child: SizedBox(
        height: 40,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final label = items[index];
            return GestureDetector(
              onTap: () => onTap?.call(label),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: t.colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: t.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
