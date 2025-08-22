import 'package:flutter/material.dart';
import 'package:bazari_8656/data/models.dart';
import 'package:bazari_8656/features/product/pages/product_view_page.dart' as pv;

class SellerProfilePage extends StatefulWidget {
  const SellerProfilePage({super.key});
  @override
  State<SellerProfilePage> createState() => _SellerProfilePageState();
}

class _SellerProfilePageState extends State<SellerProfilePage> {
  final List<Product> _items = <Product>[];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('فروشنده')),
      body: ListView.builder(
        itemCount: _items.length,
        itemBuilder: (_, i) {
          final p = _items[i];
          return ListTile(
            title: Text(p.title),
            trailing: Text('${p.price} ${p.currency}'),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => pv.ProductViewPage(p: p)),
            ),
          );
        },
      ),
    );
  }
}
