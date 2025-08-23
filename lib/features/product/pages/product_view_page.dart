// lib/features/product/pages/product_view_page.dart
import 'package:flutter/material.dart';
import 'package:bazari_8656/features/chat/pages/chat_room_page.dart';
import 'package:bazari_8656/features/product/models/product.dart' as fp;

const double _kMaxContentWidth = 1040;
const double _kGutter = 16;

class ProductViewPage extends StatefulWidget {
  const ProductViewPage({
    super.key,
    required this.p,
  });

  final fp.Product p;

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  int _current = 0;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final cs = th.colorScheme;
    final p = widget.p;

    final images = _imagesOf(p);
    final seller = _sellerOf(p);
    final details = _detailsOf(p);
    final keywords = _keywordsOf(p);
    final similar = _similarOf(p);

    final wide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'اشتراک‌گذاری',
            onPressed: () => _share(context, p),
            icon: const Icon(Icons.share_outlined),
          ),
          IconButton(
            tooltip: 'افزودن به علاقه‌مندی',
            onPressed: () {}, // TODO: وصل به wishlist
            icon: const Icon(Icons.favorite_border),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Align(
        alignment: Alignment.topCenter,
        child: SingleChildScrollView(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _kMaxContentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(_kGutter, 12, _kGutter, 24),
              child: wide
                  ? _buildWideLayout(p, images, seller, details, keywords, similar)
                  : _buildNarrowLayout(p, images, seller, details, keywords, similar),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _BottomActionBar(
        price: p.price,
        currency: p.currency,
        onChat: () {
          // ChatRoomPage دیگر پارامتر currentUserId ندارد.
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => ChatRoomPage(
                chatId: seller.id,
                peerTitle: seller.name,
              ),
            ),
          );
        },
        onBuy: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فعلاً خرید مستقیم فعال نیست.')),
          );
        },
      ),
    );
  }

  /* -------------------------- Layouts -------------------------- */

  Widget _buildWideLayout(
    fp.Product p,
    List<String> images,
    _SellerVM seller,
    Map<String, dynamic> details,
    List<String> keywords,
    List<fp.Product> similar,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 6,
          child: _Gallery(
            images: images,
            current: _current,
            onIndex: (i) => setState(() => _current = i),
          ),
        ),
        const SizedBox(width: _kGutter),
        Expanded(
          flex: 6,
          child: _InfoColumn(
            p: p,
            seller: seller,
            details: details,
            keywords: keywords,
            similar: similar,
          ),
        ),
      ],
    );
  }

  Widget _buildNarrowLayout(
    fp.Product p,
    List<String> images,
    _SellerVM seller,
    Map<String, dynamic> details,
    List<String> keywords,
    List<fp.Product> similar,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Gallery(
          images: images,
          current: _current,
          onIndex: (i) => setState(() => _current = i),
        ),
        const SizedBox(height: 16),
        _InfoColumn(
          p: p,
          seller: seller,
          details: details,
          keywords: keywords,
          similar: similar,
        ),
      ],
    );
  }

  /* -------------------------- Helpers -------------------------- */

  List<String> _imagesOf(fp.Product p) {
    // مدل جدید فقط images دارد
    final imgs = (p.images ?? const <String>[])
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (imgs.isNotEmpty) return imgs;

    // Placeholder اگر هیچ عکسی نبود
    return ['https://picsum.photos/seed/${p.id}/1200/1200'];
  }

  _SellerVM _sellerOf(fp.Product p) {
    if (p.seller != null) {
      return _SellerVM(
        id: p.seller!.id,
        name: p.seller!.name,
        avatarUrl: p.seller!.avatarUrl,
      );
    }
    // اگر seller در مدل نبود، مقادیر پیش‌فرض
    return _SellerVM(id: 'unknown', name: 'فروشنده', avatarUrl: null);
  }

  Map<String, dynamic> _detailsOf(fp.Product p) {
    final d = p.details;
    if (d == null) return const {};
    try {
      return Map<String, dynamic>.from(d);
    } catch (_) {
      return d.map((k, v) => MapEntry(k.toString(), v));
    }
  }

  List<String> _keywordsOf(fp.Product p) {
    final k = p.keywords;
    if (k == null) return const [];
    return k.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }

  List<fp.Product> _similarOf(fp.Product p) {
    return p.similar ?? const <fp.Product>[];
  }

  void _share(BuildContext context, fp.Product p) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('اشتراک‌گذاری: ${p.title}')),
    );
  }
}

/* ============================== Gallery ============================== */

class _Gallery extends StatefulWidget {
  const _Gallery({
    required this.images,
    required this.current,
    required this.onIndex,
  });

  final List<String> images;
  final int current;
  final ValueChanged<int> onIndex;

  @override
  State<_Gallery> createState() => _GalleryState();
}

class _GalleryState extends State<_Gallery> {
  late final PageController _page = PageController(initialPage: widget.current);

  @override
  void didUpdateWidget(covariant _Gallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.current != widget.current &&
        _page.hasClients &&
        _page.page?.round() != widget.current) {
      _page.jumpToPage(widget.current);
    }
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              color: cs.surfaceVariant.withOpacity(0.5),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  PageView.builder(
                    controller: _page,
                    onPageChanged: widget.onIndex,
                    itemCount: widget.images.length,
                    itemBuilder: (_, i) {
                      final url = widget.images[i];
                      return InkWell(
                        onTap: () => _openFullScreen(context, widget.images, i),
                        child: FittedBox(
                          fit: BoxFit.contain,
                          child: Image.network(
                            url,
                            errorBuilder: (_, __, ___) =>
                                const Icon(Icons.broken_image, size: 64),
                          ),
                        ),
                      );
                    },
                  ),
                  if (widget.images.length > 1)
                    Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: _Dots(
                        length: widget.images.length,
                        index: widget.current,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        if (widget.images.length > 1)
          SizedBox(
            height: 78,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) {
                final url = widget.images[i];
                final selected = i == widget.current;
                return InkWell(
                  onTap: () => widget.onIndex(i),
                  child: Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: FittedBox(
                        fit: BoxFit.cover,
                        child: Image.network(
                          url,
                          errorBuilder: (_, __, ___) =>
                              const Icon(Icons.broken_image),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  void _openFullScreen(BuildContext context, List<String> images, int start) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => _FullScreenGallery(images: images, initial: start),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.length, required this.index});
  final int length;
  final int index;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (i) {
        final active = i == index;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: active ? 18 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: active ? cs.primary : cs.onSurface.withOpacity(0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _FullScreenGallery extends StatefulWidget {
  const _FullScreenGallery({required this.images, required this.initial});

  final List<String> images;
  final int initial;

  @override
  State<_FullScreenGallery> createState() => _FullScreenGalleryState();
}

class _FullScreenGalleryState extends State<_FullScreenGallery> {
  late final PageController _pc = PageController(initialPage: widget.initial);

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.pop(context),
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: PageView.builder(
          controller: _pc,
          itemCount: widget.images.length,
          itemBuilder: (_, i) {
            final url = widget.images[i];
            return InteractiveViewer(
              boundaryMargin: const EdgeInsets.all(80),
              minScale: 0.5,
              maxScale: 4,
              child: Image.network(
                url,
                fit: BoxFit.contain,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.broken_image, color: Colors.white, size: 72),
              ),
            );
          },
        ),
      ),
    );
  }
}

/* ============================== Info Column ============================== */

class _InfoColumn extends StatelessWidget {
  const _InfoColumn({
    required this.p,
    required this.seller,
    required this.details,
    required this.keywords,
    required this.similar,
  });

  final fp.Product p;
  final _SellerVM seller;
  final Map<String, dynamic> details;
  final List<String> keywords;
  final List<fp.Product> similar;

  @override
  Widget build(BuildContext context) {
    final th = Theme.of(context);
    final cs = th.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                p.title,
                style: th.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 12),
            _PriceChip(price: p.price, currency: p.currency),
          ],
        ),

        const SizedBox(height: 8),

        if (keywords.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: keywords
                .map((k) => Chip(
                      label: Text(k),
                      backgroundColor: cs.surfaceVariant,
                    ))
                .toList(),
          ),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          color: cs.surface,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              (p.description ?? '').trim().isNotEmpty
                  ? p.description!.trim()
                  : 'توضیحات محصول ثبت نشده است.',
              style: th.textTheme.bodyMedium?.copyWith(
                color: (p.description ?? '').trim().isNotEmpty
                    ? null
                    : cs.onSurfaceVariant,
              ),
            ),
          ),
        ),

        const SizedBox(height: 12),

        if (details.isNotEmpty)
          Card(
            elevation: 0,
            color: cs.surface,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('جزئیات', style: th.textTheme.titleMedium),
                  const SizedBox(height: 12),
                  ...details.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 120,
                            child: Text(
                              e.key,
                              style: th.textTheme.bodyMedium?.copyWith(
                                color: cs.onSurfaceVariant,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text('${e.value}',
                                style: th.textTheme.bodyMedium),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 12),

        Card(
          elevation: 0,
          color: cs.surface,
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              radius: 22,
              backgroundColor: cs.surfaceVariant,
              backgroundImage: (seller.avatarUrl?.trim().isNotEmpty ?? false)
                  ? NetworkImage(seller.avatarUrl!)
                  : null,
              child: (seller.avatarUrl?.trim().isEmpty ?? true)
                  ? Text(
                      seller.name.isNotEmpty
                          ? seller.name.characters.first.toUpperCase()
                          : '؟',
                    )
                  : null,
            ),
            title: Text(seller.name),
            subtitle: Text('کد فروشنده: ${seller.id}',
                style:
                    th.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
            trailing: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ChatRoomPage(
                    chatId: seller.id,
                    peerTitle: seller.name,
                  ),
                ));
              },
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('چت'),
            ),
          ),
        ),

        const SizedBox(height: 20),

        if (similar.isNotEmpty) ...[
          Text('محصولات مشابه', style: th.textTheme.titleMedium),
          const SizedBox(height: 10),
          SizedBox(
            height: 230,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: similar.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final sp = similar[i];
                final simImgs = (sp.images ?? const <String>[])
                    .map((e) => e.trim())
                    .where((e) => e.isNotEmpty)
                    .toList();
                final img = simImgs.isNotEmpty
                    ? simImgs.first
                    : 'https://picsum.photos/seed/${sp.id}/600/600';

                return SizedBox(
                  width: 160,
                  child: Card(
                    clipBehavior: Clip.antiAlias,
                    child: InkWell(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProductViewPage(p: sp),
                        ));
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AspectRatio(
                            aspectRatio: 1,
                            child: FittedBox(
                              fit: BoxFit.cover,
                              child: Image.network(
                                img,
                                errorBuilder: (_, __, ___) =>
                                    const Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              sp.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

/* ============================== Widgets ============================== */

class _PriceChip extends StatelessWidget {
  const _PriceChip({required this.price, required this.currency});
  final double price;
  final String currency;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.primaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _formatPrice(price, currency),
        style: TextStyle(
          color: cs.onPrimaryContainer,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _formatPrice(double v, String curr) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    return '$s $curr';
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.price,
    required this.currency,
    required this.onChat,
    required this.onBuy,
  });

  final double price;
  final String currency;
  final VoidCallback onChat;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: BoxDecoration(
          color: cs.surface,
          border: Border(top: BorderSide(color: cs.outlineVariant)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                _formatPrice(price, currency),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
            ),
            OutlinedButton.icon(
              onPressed: onChat,
              icon: const Icon(Icons.chat_bubble_outline),
              label: const Text('چت'),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: onBuy,
              icon: const Icon(Icons.shopping_bag_outlined),
              label: const Text('خرید'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatPrice(double v, String curr) {
    final s = v.toStringAsFixed(v.truncateToDouble() == v ? 0 : 2);
    return '$s $curr';
  }
}

/* ============================== VMs ============================== */

class _SellerVM {
  final String id;
  final String name;
  final String? avatarUrl;
  _SellerVM({required this.id, required this.name, this.avatarUrl});
}
