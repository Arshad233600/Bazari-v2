import 'package:flutter/material.dart';
import 'package:bazari_8656/data/models.dart';

/// صفحه AI: کاربر فقط لینک عکس می‌دهد و توضیح/قیمت پیشنهادی به صورت خودکار ساخته می‌شود (mock).
class AiAddProductPage extends StatefulWidget {
  const AiAddProductPage({super.key});
  @override
  State<AiAddProductPage> createState() => _AiAddProductPageState();
}

class _AiAddProductPageState extends State<AiAddProductPage> {
  final _imageCtrl = TextEditingController();
  Product? _preview;

  @override
  void dispose() { _imageCtrl.dispose(); super.dispose(); }

  void _generateFromImage() {
    final url = _imageCtrl.text.trim();
    if (url.isEmpty) return;
    final now = DateTime.now();
    // الگوریتم ساده برای تولید عنوان/قیمت — بدون وابستگی خارجی
    final hash = url.hashCode.abs();
    final price = (20 + (hash % 980)).toDouble();
    final cat = ['phones','laptops','audio','tv','camera','fashion'][hash % 6];
    setState(() {
      _preview = Product(
        id: 'ai_${now.millisecondsSinceEpoch}',
        title: 'AI ${cat.toUpperCase()} Item',
        price: price,
        currency: 'CHF',
        imageUrl: url,
        createdAt: now,
        sellerName: 'You',
        sellerAvatarUrl: 'https://i.pravatar.cc/150?u=you',
        sellerId: 'you',
        categoryId: cat,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('AI Product Creator', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        TextField(
          controller: _imageCtrl,
          decoration: const InputDecoration(
            labelText: 'Image URL',
            hintText: 'https://...',
            prefixIcon: Icon(Icons.image_outlined),
          ),
          onSubmitted: (_)=> _generateFromImage(),
        ),
        const SizedBox(height: 8),
        FilledButton.icon(onPressed: _generateFromImage, icon: const Icon(Icons.auto_awesome), label: const Text('Generate')),
        const SizedBox(height: 16),
        if (_preview != null)
          Card(
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              AspectRatio(aspectRatio: 1.4, child: Image.network(_preview!.imageUrl, fit: BoxFit.cover)),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(_preview!.title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 6),
                  Text('${_preview!.price.toStringAsFixed(2)} ${_preview!.currency}'),
                  const SizedBox(height: 8),
                  Text('Auto description based on image colors and category (${_preview!.categoryId}).'),
                ]),
              ),
            ]),
          ),
      ],
    );
  }
}