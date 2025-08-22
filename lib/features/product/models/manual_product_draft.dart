// lib/features/product/models/manual_product_draft.dart
import 'package:flutter/foundation.dart';

@immutable
class ManualProductDraft {
  final String? title;
  final String? description;
  final double? price;
  final String? categoryId;
  final String? subcategoryId;

  const ManualProductDraft({
    this.title,
    this.description,
    this.price,
    this.categoryId,
    this.subcategoryId,
  });

  ManualProductDraft copyWith({
    String? title,
    String? description,
    double? price,
    String? categoryId,
    String? subcategoryId,
  }) {
    return ManualProductDraft(
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      subcategoryId: subcategoryId ?? this.subcategoryId,
    );
  }
}
