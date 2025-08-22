class Product {
  final String id;
  final String title;
  final double price;
  final String currency;
  final String imageUrl;
  final DateTime createdAt;
  final String sellerId;
  final String sellerName;
  final String sellerAvatarUrl;
  final String categoryId;

  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.currency,
    required this.imageUrl,
    required this.createdAt,
    required this.sellerId,
    required this.sellerName,
    required this.sellerAvatarUrl,
    required this.categoryId,
  });

  bool get isNew => DateTime.now().difference(createdAt).inDays <= 7;
}
class CategorySpec{
  final String id; final String label; final String emoji;
  const CategorySpec({required this.id, required this.label, required this.emoji});
}
