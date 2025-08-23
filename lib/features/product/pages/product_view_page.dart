// lib/features/product/pages/product_view_page.dart
import 'package:flutter/material.dart';
import '../models/product.dart'; // Product, Seller
import 'package:bazari_8656/features/chat/pages/chat_room_page.dart';

class ProductViewPage extends StatefulWidget {
  const ProductViewPage({
    super.key,
    required this.p,
    required this.currentUserId,
  });

  final Product p;
  final String currentUserId;

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  late final PageController _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  String _firstImage(Product p) {
    final imgs = p.images;
    if (imgs.isNotEmpty) return imgs.first.trim();
    return 'https://picsum.photos/seed/${p.id}/1200/900';
  }

  Seller _resolveSeller(Product p) {
    // مدل جدید: seller ممکن است null باشد
    if (p.seller != null) return p.seller!;
    // اگر seller نداشت، یک seller پیش‌فرض می‌سازیم
    return const Seller(id: 'unknown', name: 'فروشنده');
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final seller = _resolveSeller(p);
    final th = Theme.of(context);
    final cs = th.colorScheme;

    final images = p.images.isEmpty ? <String>[_firstImage(p)] : p.images;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: ListView(
        children: [
          // --- گالری با قابلیت Zoom ---
          AspectRatio(
            aspectRatio: 1,
            child: Stack(
              children: [
                PageView.builder(
                  controller: _page,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemCount: images.length,
                  itemBuilder: (_, i) {
                    final url = images[i].trim();
                    return InteractiveViewer(
                      maxScale: 4,
                      minScale: 1,
                      child: Hero(
                        tag: 'pimg_${p.id}_$i',
                        child: DecoratedBox(
                          decoration: BoxDecoration(color: cs.surfaceVariant),
                          child: url.isEmpty
                              ? const Icon(Icons.image_not_supported_outlined, size: 48)
                              : Image.network(url, fit: BoxFit.contain),
                        ),
                      ),
                    );
                  },
                ),
                if (images.length > 1)
                  Positioned(
                    bottom: 8,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.35),
                          borderRadius: BorderRadius.circular(100),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '${_index + 1}/${images.length}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // --- عنوان و قیمت ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    p.title,
                    style: th.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${p.price.toStringAsFixed(2)} ${p.currency}',
                  style: th.textTheme.titleMedium?.copyWith(
                    color: cs.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          // --- فروشنده + دکمهٔ چت ---
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: cs.surfaceVariant,
                  backgroundImage: (seller.avatarUrl != null &&
                          seller.avatarUrl!.trim().isNotEmpty)
                      ? NetworkImage(seller.avatarUrl!.trim())
                      : null,
                  child: (seller.avatarUrl == null ||
                          seller.avatarUrl!.trim().isEmpty)
                      ? Text(
                          seller.name.characters.first.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    seller.name,
                    style: th.textTheme.titleMedium,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () {
                    // ⚠️ توجه: سازندهٔ ChatRoomPage «currentUserId» ندارد.
                    // فقط پارامترهای موجود را می‌فرستیم تا ارور «No named parameter…» رفع شود.
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ChatRoomPage(
                          chatId: seller.id,
                          peerTitle: seller.name,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: const Text('گفتگو'),
                ),
              ],
            ),
          ),

          // --- توضیحات ---
          if ((p.description?.trim().isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Text(
                p.description!.trim(),
                style: th.textTheme.bodyMedium,
              ),
            ),

          // --- کلمات کلیدی ---
          if ((p.keywords?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: p.keywords!
                    .where((k) => k.trim().isNotEmpty)
                    .map((k) => Chip(label: Text(k.trim())))
                    .toList(),
              ),
            ),

          // --- جزییات (key/value) ---
          if ((p.details?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _DetailsSimple(
                categoryId: p.categoryId,
                details: Map<String, dynamic>.from(p.details!),
              ),
            ),

          // --- مشابه‌ها ---
          if ((p.similar?.isNotEmpty ?? false))
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Text('کالاهای مشابه', style: th.textTheme.titleMedium),
            ),
          if ((p.similar?.isNotEmpty ?? false))
            SizedBox(
              height: 210,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: p.similar!.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (_, i) {
                  final sp = p.similar![i];
                  final img = sp.images.isNotEmpty
                      ? sp.images.first.trim()
                      : 'https://picsum.photos/seed/${sp.id}/400/300';

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ProductViewPage(
                            p: sp,
                            currentUserId: widget.currentUserId,
                          ),
                        ),
                      );
                    },
                    child: SizedBox(
                      width: 160,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AspectRatio(
                            aspectRatio: 1.2,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(img, fit: BoxFit.cover),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            sp.title,
                            style: th.textTheme.bodyMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${sp.price.toStringAsFixed(2)} ${sp.currency}',
                            style: th.textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/* ------------------------- جزییات ساده (key → value) ------------------------- */

class _DetailsSimple extends StatelessWidget {
  const _DetailsSimple({
    required this.categoryId,
    required this.details,
  });

  final String categoryId;
  final Map<String, dynamic> details;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final entries = details.entries
        .where((e) => (e.key.toString().trim().isNotEmpty))
        .toList();

    if (entries.isEmpty) return const SizedBox.shrink();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: th.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++)
            _DetailRow(
              label: entries[i].key.toString(),
              value: (entries[i].value ?? '').toString(),
              last: i == entries.length - 1,
            ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
    required this.last,
  });

  final String label;
  final String value;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final cs = th.colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(color: cs.outlineVariant),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 38,
            child: Text(
              label,
              style: th.textTheme.bodyMedium?.copyWith(
                color: cs.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            flex: 62,
            child: Text(
              value,
              style: th.textTheme.bodyMedium,
              textAlign: TextAlign.start,
            ),
          ),
        ],
      ),
    );
  }
}
