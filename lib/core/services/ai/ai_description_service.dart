class AiSuggestion {
  final String title;
  final String description;
  final double price;
  AiSuggestion({required this.title, required this.description, required this.price});
}

class AiDescriptionService {
  /// Offline mock: generates a reasonable suggestion from image URL.
  Future<AiSuggestion> generate(String imageUrl) async {
    // simple pseudo-random selection to silence warnings and provide content
    final adjectives = ['Premium', 'Stylish', 'Compact', 'Powerful', 'Elegant'];
    final nouns = ['Phone', 'Laptop', 'Headphones', 'Camera', 'Watch'];
    final idx = imageUrl.hashCode.abs();
    final adj = adjectives[idx % adjectives.length];
    final noun = nouns[(idx ~/ 7) % nouns.length];
    final model = (2020 + (idx % 5)).toString();

    final title = '$adj $noun $model';
    final description = 'Auto-generated description for $noun. '
        'High quality, reliable performance, and great value.';
    final price = 49.0 + (idx % 500);

    await Future.delayed(const Duration(milliseconds: 120));
    return AiSuggestion(title: title, description: description, price: price);
  }
}
