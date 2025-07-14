import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../models/recipe_model.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  List<Recipe> _recipes = [];
  bool _loading = true;
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    final snapshot = await FirebaseFirestore.instance.collection('recipes').get();
    setState(() {
      _recipes = snapshot.docs.map((doc) => Recipe.fromMap(doc.id, doc.data())).toList();
      _loading = false;
    });
  }

  Future<void> _deleteRecipe(String recipeId) async {
    await FirebaseFirestore.instance.collection('recipes').doc(recipeId).delete();
    await _loadRecipes();
  }

  Future<void> _showRecipeForm({Recipe? recipe}) async {
    final titleController = TextEditingController(text: recipe?.title ?? '');
    final categoryController = TextEditingController(text: recipe?.category ?? '');
    final instructionController = TextEditingController(text: recipe?.instructions.join('\n') ?? '');
    final imageUrlController = TextEditingController(text: recipe?.imageUrl ?? '');
    _uploadedImageUrl = recipe?.imageUrl;

    List<Map<String, dynamic>> ingredients = recipe?.ingredients.map((i) => i.toMap()).toList() ?? [];

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(recipe == null ? 'Add Recipe' : 'Edit Recipe'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                TextField(
                  controller: imageUrlController,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  onChanged: (val) => _uploadedImageUrl = val.trim(),
                ),
                const SizedBox(height: 12),
                TextField(controller: titleController, decoration: const InputDecoration(labelText: 'Title')),
                TextField(controller: categoryController, decoration: const InputDecoration(labelText: 'Category')),
                TextField(
                  controller: instructionController,
                  maxLines: 4,
                  decoration: const InputDecoration(labelText: 'Instructions (each step in new line)'),
                ),
                const SizedBox(height: 12),
                const Text('Ingredients', style: TextStyle(fontWeight: FontWeight.bold)),
                ...ingredients.asMap().entries.map((entry) {
                  int i = entry.key;
                  var ing = entry.value;
                  return Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: ing['name'],
                          decoration: const InputDecoration(hintText: 'Name'),
                          onChanged: (val) => ing['name'] = val,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          initialValue: ing['amount']?.toString(),
                          decoration: const InputDecoration(hintText: 'Amount'),
                          keyboardType: TextInputType.number,
                          onChanged: (val) => ing['amount'] = double.tryParse(val) ?? 0,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: TextFormField(
                          initialValue: ing['unit'],
                          decoration: const InputDecoration(hintText: 'Unit'),
                          onChanged: (val) => ing['unit'] = val,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => setModalState(() => ingredients.removeAt(i)),
                      )
                    ],
                  );
                }),
                TextButton.icon(
                  icon: const Icon(Icons.add),
                  label: const Text('Add Ingredient'),
                  onPressed: () => setModalState(() => ingredients.add({'name': '', 'amount': 0, 'unit': ''})),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final data = {
                  'title': titleController.text.trim(),
                  'imageUrl': _uploadedImageUrl ?? '',
                  'category': categoryController.text.trim(),
                  'instructions': instructionController.text.trim().split('\n'),
                  'ingredients': ingredients,
                  'rating': recipe?.rating ?? 0.0,
                  'ratings': recipe?.ratings ?? {},
                  'comments': recipe?.comments ?? [],
                };

                final ref = FirebaseFirestore.instance.collection('recipes');
                if (recipe == null) {
                  await ref.add(data);
                } else {
                  await ref.doc(recipe.id).update(data);
                }

                if (context.mounted) Navigator.pop(context);
                await _loadRecipes();
              },
              child: Text(recipe == null ? 'Add' : 'Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Dashboard')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _recipes.isEmpty
          ? const Center(child: Text('No recipes found'))
          : ListView.builder(
        itemCount: _recipes.length,
        itemBuilder: (context, i) {
          final recipe = _recipes[i];
          return ListTile(
            leading: recipe.imageUrl.isNotEmpty
                ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                recipe.imageUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
              ),
            )
                : const Icon(Icons.image),
            title: Text(recipe.title),
            subtitle: Text(recipe.category),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.blue),
                  onPressed: () => _showRecipeForm(recipe: recipe),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _deleteRecipe(recipe.id),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showRecipeForm(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
