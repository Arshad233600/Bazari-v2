// ادامه‌ی مدل Product در lib/features/product/models/product.dart

/// فروشنده به‌صورت یک آبجکت جدا
class Seller {
  final String id;
  final String name;
  final String? avatarUrl;

  const Seller({required this.id, required this.name, this.avatarUrl});
}

@immutable
class Product {
  final String id;
  final String title;
  final double price;
  final String currency;
  final List<String> images;

  // 🔹 این‌ها رو اضافه می‌کنیم:
  final List<String> keywords;
  final String? description;
  final Map<String, String>? details;
  final Seller? seller;
  final List<Product> similar;

  final String? categoryId;
  final DateTime? createdAt;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    this.images = const <String>[],
    this.keywords = const <String>[],
    this.description,
    this.details,
    this.seller,
    this.similar = const <Product>[],
    this.categoryId,
    this.createdAt,
  });
}
