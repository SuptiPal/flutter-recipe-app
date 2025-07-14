class Ingredient {
  final String name;
  final double amount;
  final String unit;

  Ingredient({
    required this.name,
    required this.amount,
    required this.unit,
  });

  factory Ingredient.fromMap(Map<String, dynamic> data) {
    return Ingredient(
      name: data['name'] ?? '',
      amount: (data['amount'] as num?)?.toDouble() ?? 0.0,
      unit: data['unit'] ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'name': name,
    'amount': amount,
    'unit': unit,
  };
}

class Recipe {
  final String id;
  final String title;
  final String imageUrl;
  final String category;
  final List<String> instructions;
  double rating;
  final List<dynamic> comments;
  final Map<String, dynamic> ratings;
  final List<Ingredient> ingredients;

  Recipe({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.category,
    required this.instructions,
    required this.rating,
    required this.comments,
    required this.ratings,
    required this.ingredients,
  });

  factory Recipe.fromMap(String id, Map<String, dynamic> data) {
    return Recipe(
      id: id,
      title: data['title'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? '',
      instructions: List<String>.from(data['instructions'] ?? []),
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      comments: List<dynamic>.from(data['comments'] ?? []),
      ratings: Map<String, dynamic>.from(data['ratings'] ?? {}),
      ingredients: (data['ingredients'] as List? ?? [])
          .map((item) => Ingredient.fromMap(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title,
    'imageUrl': imageUrl,
    'category': category,
    'instructions': instructions,
    'rating': rating,
    'comments': comments,
    'ratings': ratings,
    'ingredients': ingredients.map((i) => i.toMap()).toList(),
  };
}
