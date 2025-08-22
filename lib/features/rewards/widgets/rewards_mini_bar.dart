import 'package:flutter/material.dart';
import '../rewards_controller.dart';

class RewardsMiniBar extends StatefulWidget {
  const RewardsMiniBar({super.key});
  @override
  State<RewardsMiniBar> createState() => _RewardsMiniBarState();
}

class _RewardsMiniBarState extends State<RewardsMiniBar> {
  @override
  void initState() {
    super.initState();
    rewards.addListener(_onChange);
  }
  @override
  void dispose() {
    rewards.removeListener(_onChange);
    super.dispose();
  }
  void _onChange() { if (mounted) setState((){}); }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: t.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            _chip('Impr', rewards.impressions),
            const SizedBox(width: 8),
            _chip('Clicks', rewards.clicks),
            const Spacer(),
            FilledButton.icon(
              onPressed: rewards.spin,
              icon: const Icon(Icons.casino_outlined, size: 18),
              label: Text('Rewards ${rewards.rewards}'),
            )
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, int value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
      ),
      child: Row(children: [
        Text(label),
        const SizedBox(width: 6),
        Text('$value', style: const TextStyle(fontWeight: FontWeight.w600)),
      ]),
    );
  }
}
