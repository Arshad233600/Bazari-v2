// lib/features/product/pages/product_view_page.dart
import 'package:flutter/material.dart';
import 'package:bazari_8656/features/product/models/product.dart';
import 'package:bazari_8656/features/chat/pages/chat_room_page.dart';
import 'package:bazari_8656/core/services/auth_service.dart';

class ProductViewPage extends StatefulWidget {
  const ProductViewPage({
    super.key,
    required this.p,
  });

  final Product p;

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  // 🆕 helper برای جایگزینی currentUserId
  String _resolveMeId() {
    try {
      final a = AuthService.instance as dynamic;
      if (a.currentUserId is String && a.currentUserId.isNotEmpty) {
        return a.currentUserId;
      }
      if (a.userId is String && a.userId.isNotEmpty) {
        return a.userId;
      }
      if (a.uid is String && a.uid.isNotEmpty) {
        return a.uid;
      }
      if (a.currentUser?.uid is String && a.currentUser!.uid.isNotEmpty) {
        return a.currentUser!.uid;
      }
    } catch (_) {}
    return 'guest';
  }

  int _currentImage = 0;

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final th = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          p.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            onPressed: () {
              // TODO: پیاده‌سازی اشتراک‌گذاری
            },
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border),
            onPressed: () {
              // TODO: افزودن به علاقه‌مندی
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // گالری تصاویر
            if (p.images.isNotEmpty)
              AspectRatio(
                aspectRatio: 1,
                child: PageView.builder(
                  itemCount: p.images.length,
                  controller: PageController(viewportFraction: 1),
                  onPageChanged: (i) => setState(() => _currentImage = i),
                  itemBuilder: (_, i) {
                    return Image.network(
                      p.images[i],
                      fit: BoxFit.cover,
                    );
                  },
                ),
              ),

            if (p.images.length > 1)
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  p.images.length,
                  (i) => Container(
                    margin: const EdgeInsets.all(4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _currentImage == i
                          ? th.colorScheme.primary
                          : th.colorScheme.onSurface.withOpacity(0.3),
                    ),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // عنوان
                  Text(
                    p.title,
                    style: th.textTheme.headlineSmall
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 8),

                  // قیمت
                  Text(
                    '${p.price} ${p.currency}',
                    style: th.textTheme.titleLarge
                        ?.copyWith(color: th.colorScheme.primary),
                  ),

                  const SizedBox(height: 16),

                  // توضیحات
                  if ((p.description ?? '').trim().isNotEmpty)
                    Text(
                      p.description!,
                      style: th.textTheme.bodyMedium,
                    ),

                  const Divider(height: 32),

                  // جزئیات
                  if (p.details != null && p.details!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: p.details!.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                flex: 2,
                                child: Text(
                                  e.key,
                                  style: th.textTheme.bodyMedium!
                                      .copyWith(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  e.value,
                                  style: th.textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const Divider(height: 32),

                  // فروشنده
                  ListTile(
                    leading: CircleAvatar(
                      backgroundImage: (p.seller?.avatarUrl != null &&
                              p.seller!.avatarUrl!.trim().isNotEmpty)
                          ? NetworkImage(p.seller!.avatarUrl!)
                          : null,
                      child: (p.seller?.avatarUrl == null ||
                              p.seller!.avatarUrl!.trim().isEmpty)
                          ? Text(
                              p.seller?.name.characters.first.toUpperCase() ??
                                  '?',
                            )
                          : null,
                    ),
                    title: Text(p.seller?.name ?? 'فروشنده'),
                    subtitle: const Text('مشاهده پروفایل'),
                    trailing: IconButton(
                      icon: const Icon(Icons.chat_outlined),
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ChatRoomPage(
                              chatId: p.seller?.id ?? 'unknown',
                              peerTitle: p.seller?.name ?? 'فروشنده',
                              meId: _resolveMeId(), // ✅ تغییر اصلی
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const Divider(height: 32),

                  // کلمات کلیدی
                  if (p.keywords != null && p.keywords!.isNotEmpty)
                    Wrap(
                      spacing: 8,
                      children: p.keywords!.map((k) {
                        return Chip(
                          label: Text(k),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: 32),

                  // محصولات مشابه
                  if (p.similar != null && p.similar!.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'محصولات مشابه',
                          style: th.textTheme.titleMedium,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 220,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: p.similar!.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (_, i) {
                              final sp = p.similar![i];
                              return SizedBox(
                                width: 160,
                                child: GestureDetector(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => ProductViewPage(p: sp),
                                      ),
                                    );
                                  },
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      AspectRatio(
                                        aspectRatio: 1,
                                        child: ClipRRect(
                                          borderRadius:
                                              BorderRadius.circular(12),
                                          child: (sp.images.isNotEmpty)
                                              ? Image.network(
                                                  sp.images.first,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                                  color: th.colorScheme
                                                      .surfaceVariant,
                                                  child: const Icon(Icons
                                                      .image_not_supported),
                                                ),
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        sp.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: th.textTheme.bodyMedium,
                                      ),
                                      Text(
                                        '${sp.price} ${sp.currency}',
                                        style: th.textTheme.bodySmall?.copyWith(
                                          color: th.colorScheme.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
