// lib/features/product/pages/product_view_page.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:bazari_8656/app/i18n/i18n.dart';
import 'package:bazari_8656/core/services/auth_service.dart';
import 'package:bazari_8656/features/chat/pages/chat_room_page.dart';
import 'package:bazari_8656/features/product/models/product.dart';

class ProductViewPage extends StatefulWidget {
  const ProductViewPage({super.key, required this.p});

  final Product p;

  @override
  State<ProductViewPage> createState() => _ProductViewPageState();
}

class _ProductViewPageState extends State<ProductViewPage> {
  late PageController _galleryCtl;
  int _currentImage = 0;

  @override
  void initState() {
    super.initState();
    _galleryCtl = PageController();
  }

  @override
  void dispose() {
    _galleryCtl.dispose();
    super.dispose();
  }

  // 🔑 helper برای UID کاربر
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

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final t = AppLang.instance.t;
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(p.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: _buildGallery(p),
          ),
          SliverToBoxAdapter(
            child: _buildHeader(p, cs, t),
          ),
          if (p.description != null && p.description!.trim().isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  p.description!,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ),
            ),
          if (p.details != null && p.details!.isNotEmpty)
            SliverToBoxAdapter(
              child: _DetailsSimple(
                categoryId: p.categoryId,
                details: p.details!,
              ),
            ),
          if (p.similar.isNotEmpty)
            SliverToBoxAdapter(
              child: _SimilarProducts(similar: p.similar),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 120)),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(p, t, cs),
    );
  }
