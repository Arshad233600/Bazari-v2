import 'package:flutter/material.dart';
import 'package:bazari_8656/data/mock_data.dart';

/// SortMode فقط اینجاست تا تعارض نوع پیش نیاید.
enum SortMode { newest, priceLow, priceHigh, random }

class HomeFilterState {
  final String? query;
  final String? categoryId;
  final double? minPrice;
  final double? maxPrice;
  final SortMode sort;
  final bool onlyAvailable;

  const HomeFilterState({
    this.query,
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.sort = SortMode.newest,
    this.onlyAvailable = false,
  });

  HomeFilterState copyWith({
    String? query,
    String? categoryId,
    double? minPrice,
    double? maxPrice,
    SortMode? sort,
    bool? onlyAvailable,
  }) {
    return HomeFilterState(
      query: query ?? this.query,
      categoryId: categoryId ?? this.categoryId,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sort: sort ?? this.sort,
      onlyAvailable: onlyAvailable ?? this.onlyAvailable,
    );
  }
}

class HomeFilterSheet extends StatefulWidget {
  final HomeFilterState initial;
  const HomeFilterSheet({super.key, required this.initial});

  @override
  State<HomeFilterSheet> createState() => _HomeFilterSheetState();
}

class _HomeFilterSheetState extends State<HomeFilterSheet> {
  late TextEditingController _qCtl;
  String? _categoryId;
  String _min = '';
  String _max = '';
  SortMode _sort = SortMode.newest;
  bool _only = false;

  @override
  void initState() {
    super.initState();
    _qCtl = TextEditingController(text: widget.initial.query ?? '');
    _categoryId = widget.initial.categoryId;
    _min = widget.initial.minPrice?.toString() ?? '';
    _max = widget.initial.maxPrice?.toString() ?? '';
    _sort = widget.initial.sort;
    _only = widget.initial.onlyAvailable;
  }

  @override
  void dispose() {
    _qCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (c, scroll) {
        return SafeArea(
          child: Material(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            clipBehavior: Clip.antiAlias,
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Filter', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _qCtl,
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    labelText: 'Search',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Category'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('All'),
                      selected: _categoryId == null,
                      onSelected: (_) => setState(() => _categoryId = null),
                    ),
                    for (final c in kCategories24)
                      ChoiceChip(
                        label: Text('${c.emoji} ${c.label}'),
                        selected: _categoryId == c.id,
                        onSelected: (_) => setState(() => _categoryId = c.id),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Price'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Min',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _min = v,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Max',
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (v) => _max = v,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text('Sort'),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: [
                    ChoiceChip(label: const Text('Newest'),  selected: _sort==SortMode.newest,   onSelected: (_)=>setState(()=>_sort=SortMode.newest)),
                    ChoiceChip(label: const Text('Price ↑'), selected: _sort==SortMode.priceLow, onSelected: (_)=>setState(()=>_sort=SortMode.priceLow)),
                    ChoiceChip(label: const Text('Price ↓'), selected: _sort==SortMode.priceHigh,onSelected: (_)=>setState(()=>_sort=SortMode.priceHigh)),
                    ChoiceChip(label: const Text('Shuffle'), selected: _sort==SortMode.random,   onSelected: (_)=>setState(()=>_sort=SortMode.random)),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  value: _only,
                  onChanged: (v) => setState(()=> _only = v ?? false),
                  title: const Text('Only available'),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _qCtl.text = '';
                            _categoryId = null;
                            _min = '';
                            _max = '';
                            _sort = SortMode.newest;
                            _only = false;
                          });
                        },
                        child: const Text('Reset'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final min = double.tryParse(_min);
                          final max = double.tryParse(_max);
                          Navigator.pop(context, HomeFilterState(
                            query: _qCtl.text.trim(),
                            categoryId: _categoryId,
                            minPrice: min,
                            maxPrice: max,
                            sort: _sort,
                            onlyAvailable: _only,
                          ));
                        },
                        child: const Text('Apply'),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        );
      },
    );
  }
}
