// lib/features/product/models/product.dart
import 'package:flutter/foundation.dart';

@immutable
class Product {
  final String id;
  final String title;
  final double price;
  final String currency;

  /// لیست تصاویر (کاور، گالری و ...). اگر خالی باشد یعنی تصویری نداریم.
  final List<String> images;

  /// اطلاعات فروشنده
  final String? sellerId;
  final String? sellerName;
  final String? sellerAvatarUrl;

  /// دسته‌بندی
  final String? categoryId;

  /// توضیحات و ویژگی‌ها (اختیاری)
  final String? description;
  final Map<String, dynamic>? attributes;

  /// زمان ایجاد (اختیاری – برای مرتب‌سازی/نمایش)
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    this.images = const <String>[],
    this.sellerId,
    this.sellerName,
    this.sellerAvatarUrl,
    this.categoryId,
    this.description,
    this.attributes,
    this.createdAt,
  });

  /// راحت‌ترین دسترسی به کاور (اولین عکس)
  String? get cover =>
      images.isNotEmpty ? images.first : null;

  Product copyWith({
    String? id,
    String? title,
    double? price,
    String? currency,
    List<String>? images,
    String? sellerId,
    String? sellerName,
    String? sellerAvatarUrl,
    String? categoryId,
    String? description,
    Map<String, dynamic>? attributes,
    DateTime? createdAt,
  }) {
    return Product(
      id: id ?? this.id,
      title: title ?? this.title,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      images: images ?? this.images,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatarUrl: sellerAvatarUrl ?? this.sellerAvatarUrl,
      categoryId: categoryId ?? this.categoryId,
      description: description ?? this.description,
      attributes: attributes ?? this.attributes,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    final imgs = <String>[];
    final mImgs = map['images'];
    if (mImgs is List) {
      for (final x in mImgs) {
        final s = '$x'.trim();
        if (s.isNotEmpty) imgs.add(s);
      }
    } else if (map['imageUrl'] != null) {
      final s = '${map['imageUrl']}'.trim();
      if (s.isNotEmpty) imgs.add(s);
    }

    DateTime? created;
    final cr = map['createdAt'];
    if (cr is DateTime) {
      created = cr;
    } else if (cr is String && cr.isNotEmpty) {
      created = DateTime.tryParse(cr);
    } else if (cr is int) {
      // میلی‌ثانیه یونیکس
      created = DateTime.fromMillisecondsSinceEpoch(cr, isUtc: false);
    }

    return Product(
      id: '${map['id']}',
      title: '${map['title']}',
      price: (map['price'] is num)
          ? (map['price'] as num).toDouble()
          : double.tryParse('${map['price']}') ?? 0,
      currency: (map['currency'] ?? 'CHF').toString(),
      images: imgs,
      sellerId: _optStr(map['sellerId']),
      sellerName: _optStr(map['sellerName']),
      sellerAvatarUrl: _optStr(map['sellerAvatarUrl']),
      categoryId: _optStr(map['categoryId']),
      description: _optStr(map['description']),
      attributes: (map['attributes'] is Map<String, dynamic>)
          ? (map['attributes'] as Map<String, dynamic>)
          : null,
      createdAt: created,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'price': price,
        'currency': currency,
        'images': images,
        'sellerId': sellerId,
        'sellerName': sellerName,
        'sellerAvatarUrl': sellerAvatarUrl,
        'categoryId': categoryId,
        'description': description,
        'attributes': attributes,
        'createdAt': createdAt?.toIso8601String(),
      };
}

String? _optStr(Object? x) {
  if (x == null) return null;
  final s = x.toString().trim();
  return s.isEmpty || s == 'null' ? null : s;
}
