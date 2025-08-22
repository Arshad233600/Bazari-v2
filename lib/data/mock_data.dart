class CategorySpec {
  final String id;
  final String label;
  final String emoji;
  const CategorySpec({required this.id, required this.label, required this.emoji});
}

const List<CategorySpec> kCategories24 = [
  CategorySpec(id: 'phones',  label: 'Phones',   emoji: '📱'),
  CategorySpec(id: 'laptops', label: 'Laptops',  emoji: '💻'),
  CategorySpec(id: 'audio',   label: 'Audio',    emoji: '🎧'),
  CategorySpec(id: 'tv',      label: 'TV',       emoji: '📺'),
  CategorySpec(id: 'camera',  label: 'Camera',   emoji: '📷'),
  CategorySpec(id: 'gaming',  label: 'Gaming',   emoji: '🎮'),
  CategorySpec(id: 'smart',   label: 'Smart',    emoji: '⌚'),
  CategorySpec(id: 'home',    label: 'Home',     emoji: '🏠'),
  CategorySpec(id: 'kitchen', label: 'Kitchen',  emoji: '🍳'),
  CategorySpec(id: 'garden',  label: 'Garden',   emoji: '🌿'),
  CategorySpec(id: 'tools',   label: 'Tools',    emoji: '🧰'),
  CategorySpec(id: 'auto',    label: 'Auto',     emoji: '🚗'),
  CategorySpec(id: 'fashion', label: 'Fashion',  emoji: '👗'),
  CategorySpec(id: 'shoes',   label: 'Shoes',    emoji: '👟'),
  CategorySpec(id: 'beauty',  label: 'Beauty',   emoji: '💄'),
  CategorySpec(id: 'baby',    label: 'Baby',     emoji: '🍼'),
  CategorySpec(id: 'sports',  label: 'Sports',   emoji: '🏋️'),
  CategorySpec(id: 'books',   label: 'Books',    emoji: '📚'),
  CategorySpec(id: 'pets',    label: 'Pets',     emoji: '🐾'),
  CategorySpec(id: 'art',     label: 'Art',      emoji: '🎨'),
  CategorySpec(id: 'music',   label: 'Music',    emoji: '🎵'),
  CategorySpec(id: 'office',  label: 'Office',   emoji: '🗂️'),
  CategorySpec(id: 'health',  label: 'Health',   emoji: '🩺'),
  CategorySpec(id: 'other',   label: 'Other',    emoji: '✨'),
];
