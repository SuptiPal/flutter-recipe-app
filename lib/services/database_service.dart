import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/recipe_model.dart';

class DatabaseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<List<Recipe>> fetchRecipes() async {
    final snapshot = await _db.collection('recipes').get();
    return snapshot.docs.map((doc) => Recipe.fromMap(doc.id, doc.data())).toList();
  }
}
