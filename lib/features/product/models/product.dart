// lib/features/product/models/product.dart
import 'package:flutter/foundation.dart';

@immutable
class Seller {
  final String id;
  final String name;
  final String? avatarUrl;

  const Seller({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  Seller copyWith({String? id, String? name, String? avatarUrl}) => Seller(
        id: id ?? this.id,
        name: name ?? this.name,
        avatarUrl: avatarUrl ?? this.avatarUrl,
      );
}

@immutable
class Product {
  final String id;
  final String title;
  final double price;
  final String currency;

  /// گالری تصاویر (کاور = اولین)
  final List<String> images;

  /// توضیحات متنی (غیرنالی برای جلوگیری از خطای trim)
  final String description;

  /// برچسب‌ها/کلمات کلیدی
  final List<String> keywords;

  /// جزئیات پویا برای نمایش در بخش Details
  final Map<String, dynamic> details;

  /// فروشنده (غیرنالی برای راحتی UI)
  final Seller seller;

  /// محصولات مشابه
  final List<Product> similar;

  /// دسته‌بندی
  final String categoryId;

  /// زمان ایجاد (اختیاری)
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    this.images = const <String>[],
    this.description = '',
    this.keywords = const <String>[],
    this.details = const <String, dynamic>{},
    this.seller = const Seller(id: 'unknown', name: 'Seller'),
    this.similar = const <Product>[],
    this.categoryId = 'misc',
    this.createdAt,
  });

  /// راحت‌ترین دسترسی به کاور
  String? get cover => images.isNotEmpty ? images.first : null;

  Product copyWith({
    String? id,
    String? title,
    double? price,
    String? currency,
    List<String>? images,
    String? description,
    List<String>? keywords,
    Map<String, dynamic>? details,
    Seller? seller,
    List<Product>? similar,
    String? categoryId,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      description: description ?? this.description,
      keywords: keywords ?? this.keywords,
      details: details ?? this.details,
      seller: seller ?? this.seller,
      similar: similar ?? this.similar,
      categoryId: categoryId ?? this.categoryId,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
