import 'package:flutter/material.dart';
import 'package:bazari_8656/data/models.dart';
import 'package:bazari_8656/features/product/pages/product_view_page.dart' as pv;

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});
  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final List<Product> _results = <Product>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('جستجو')),
      body: ListView.builder(
        itemCount: _results.length,
        itemBuilder: (_, i) {
          final p = _results[i];
          return ListTile(
            title: Text(p.title),
            subtitle: Text('${p.price} ${p.currency}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => pv.ProductViewPage(p: p)),
            ),
          );
        },
      ),
    );
  }
}
