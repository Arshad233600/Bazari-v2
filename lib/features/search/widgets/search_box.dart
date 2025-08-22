// lib/features/search/widgets/search_box.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:bazari_8656/data/products_repository.dart';
import 'package:bazari_8656/data/models.dart';
import 'package:bazari_8656/data/categories.dart' show flattenCategories;

/// دیباونسر ساده
class _Debouncer {
  _Debouncer(this.ms);
  final int ms;
  Timer? _t;
  void run(void Function() f) {
    _t?.cancel();
    _t = Timer(Duration(milliseconds: ms), f);
  }
  void dispose() => _t?.cancel();
}

/// مدل آیتم‌های پیشنهادی (عنوان + آیکن + شناسهٔ کتگوری در صورت وجود)
class _Suggestion {
  final String label;
  final IconData icon;
  final String? categoryId;
  _Suggestion(this.label, this.icon, {this.categoryId});
}

/// باکس جستجو با ساجست و آیکن دوربین.
/// [onCamera] اختیاری: اگر بدهی، به‌جای استاب داخلی اجرا می‌شود و
/// خروجی‌اش را به عنوان کوئری استفاده می‌کنیم.
class SearchBoxWithSuggestions extends StatefulWidget {
  const SearchBoxWithSuggestions({
    super.key,
    required this.controller,
    required this.onSubmit,
    this.onCamera,
  });

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;
  final Future<String?> Function()? onCamera;

  @override
  State<SearchBoxWithSuggestions> createState() => _SearchBoxWithSuggestionsState();
}

class _SearchBoxWithSuggestionsState extends State<SearchBoxWithSuggestions> {
  final _repo = const ProductsRepository();
  final _focus = FocusNode();
  final _deb = _Debouncer(220);

  final LayerLink _link = LayerLink();
  OverlayEntry? _overlay;

  bool _loading = false;
  List<_Suggestion> _items = <_Suggestion>[];

  @override
  void initState() {
    super.initState();
    _focus.addListener(_handleFocus);
    widget.controller.addListener(_scheduleQuery);
  }

  @override
  void dispose() {
    _removeOverlay();
    _deb.dispose();
    _focus.removeListener(_handleFocus);
    _focus.dispose();
    widget.controller.removeListener(_scheduleQuery);
    super.dispose();
  }

  void _handleFocus() {
    if (_focus.hasFocus && widget.controller.text.trim().isNotEmpty) {
      _ensureOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _scheduleQuery() {
    _deb.run(() async {
      if (!mounted) return;
      final q = widget.controller.text.trim();
      if (q.isEmpty) {
        setState(() {
          _items = [];
          _loading = false;
        });
        _removeOverlay();
        return;
      }
      await _query(q);
    });
  }

  Future<void> _query(String q) async {
    setState(() => _loading = true);

    // 1) از محصولات: عنوان‌هایی که match می‌شوند (استفاده از searchSmart)
    final List<Product> found = await _repo.searchSmart(q);
    final titles = <String>{};
    for (final p in found) {
      final t = p.title.trim();
      if (t.toLowerCase().contains(q.toLowerCase())) titles.add(t);
      if (titles.length >= 8) break;
    }

    // 2) از کتگوری‌ها و زیرکتگوری‌ها
    final catMatches = flattenCategories()
        .where((c) => c.title.toLowerCase().contains(q.toLowerCase()))
        .take(8)
        .map((c) => _Suggestion(c.title, c.icon, categoryId: c.id));

    final list = <_Suggestion>[
      ...titles.map((t) => _Suggestion(t, Icons.search)),
      ...catMatches,
    ];

    if (!mounted) return;
    setState(() {
      _items = list;
      _loading = false;
    });

    if (_items.isNotEmpty && _focus.hasFocus) {
      _ensureOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _ensureOverlay() {
    if (_overlay != null) return;
    _overlay = OverlayEntry(
      builder: (_) => Positioned(
        width: _boxWidth(),
        child: CompositedTransformFollower(
          link: _link,
          offset: const Offset(0, 48),
          showWhenUnlinked: false,
          child: _SuggestionPanel(
            loading: _loading,
            items: _items,
            onTap: (s) {
              widget.controller.text = s.label;
              widget.onSubmit(s.label);
              _removeOverlay();
              _focus.unfocus();
            },
          ),
        ),
      ),
    );
    final overlay = Overlay.of(context);
    if (_overlay != null) {
      overlay.insert(_overlay!);
    }
  }

  void _removeOverlay() {
    _overlay?.remove();
    _overlay = null;
  }

  double _boxWidth() {
    final r = context.findRenderObject();
    if (r is RenderBox) return r.size.width;
    return MediaQuery.of(context).size.width - 24;
  }

  /* -------------------- دوربین: جستجو با عکس -------------------- */
  Future<void> _searchFromCamera() async {
    // اگر کال‌بک بیرونی بدهی (مثلاً VisionAi)، از همان استفاده می‌کنیم
    if (widget.onCamera != null) {
      final query = await widget.onCamera!.call();
      if (query != null && query.trim().isNotEmpty) {
        widget.controller.text = query.trim();
        widget.onSubmit(query.trim());
        _removeOverlay();
        _focus.unfocus();
      }
      return;
    }

    // استاب ساده برای دمو (بدون VisionAi)
    final ctl = TextEditingController();
    final ok = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('جستجو با عکس'),
        content: TextField(
          controller: ctl,
          decoration: const InputDecoration(
            hintText: 'مثلاً: iPhone 12 / MacBook / Samsung TV ...',
            labelText: 'برچسب تشخیص‌شده (دمو)',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('انصراف')),
          FilledButton(onPressed: () => Navigator.pop(c, ctl.text.trim()), child: const Text('جستجو')),
        ],
      ),
    );
    if (ok != null && ok.isNotEmpty) {
      widget.controller.text = ok;
      widget.onSubmit(ok);
      _removeOverlay();
      _focus.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _link,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: cs.surfaceVariant.withOpacity(0.6),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            const Icon(Icons.search, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focus,
                textInputAction: TextInputAction.search,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  hintText: 'جستجو...',
                ),
                onSubmitted: widget.onSubmit,
              ),
            ),
            IconButton(
              tooltip: 'جستجو با عکس',
              icon: const Icon(Icons.camera_alt_outlined),
              onPressed: _searchFromCamera,
            ),
            if (widget.controller.text.isNotEmpty)
              IconButton(
                tooltip: 'پاک‌کردن',
                icon: const Icon(Icons.clear, size: 18),
                onPressed: () {
                  widget.controller.clear();
                  _scheduleQuery();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _SuggestionPanel extends StatelessWidget {
  const _SuggestionPanel({
    required this.items,
    required this.onTap,
    required this.loading,
  });

  final List<_Suggestion> items;
  final bool loading;
  final ValueChanged<_Suggestion> onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Material(
      elevation: 6,
      color: cs.surface,
      borderRadius: BorderRadius.circular(12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxHeight: 320),
        child: loading
            ? const Padding(
          padding: EdgeInsets.all(16),
          child: Center(child: CircularProgressIndicator()),
        )
            : items.isEmpty
            ? Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: const [
              Icon(Icons.info_outline),
              SizedBox(width: 8),
              Expanded(child: Text('موردی یافت نشد — دسته‌بندی‌ها را امتحان کنید')),
            ],
          ),
        )
            : ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: items.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: cs.outlineVariant),
          itemBuilder: (c, i) {
            final s = items[i];
            return ListTile(
              leading: Icon(s.icon),
              title: Text(s.label, maxLines: 1, overflow: TextOverflow.ellipsis),
              onTap: () => onTap(s),
            );
          },
        ),
      ),
    );
  }
}
