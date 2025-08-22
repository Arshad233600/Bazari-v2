class Product {
  final String id;
  final String title;
  final String description;
  final double price;
  final String currency;
  final List<String> images;

  /// دسته برای جزئیات پویا: 'house' | 'car' | 'phone' | 'job' ...
  final String categoryId;

  /// جزئیات پویا بر اساس دسته
  final Map<String, dynamic> details;

  /// کلمات کلیدی برای چیپ‌ها/جستجو
  final List<String> keywords;

  /// محصولات مشابه
  final List<Product> similar;

  /// فروشنده
  final Seller seller;

  Product({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.currency,
    required this.images,
    required this.categoryId,
    required this.seller,
    this.details = const {},
    this.keywords = const [],
    this.similar = const [],
  });
}

class Seller {
  final String id;
  final String name;
  final String? avatarUrl;

  Seller({required this.id, required this.name, this.avatarUrl});
}
