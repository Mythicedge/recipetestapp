import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../Data/recipe_model.dart';

class RecipeProvider with ChangeNotifier {
  List<Recipe> _recipes = [];
  List<Recipe> get recipes => _recipes;

RecipeProvider() {
    listenToRecipes();
  }

void listenToRecipes() {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) {
    FirebaseFirestore.instance
      .collection('users').doc(uid).collection('recipes')
      .snapshots().listen((snapshot) {
        _recipes = snapshot.docs.map((doc) => Recipe.fromMap({
          ...doc.data() as Map<String, dynamic>,
          'id': doc.id,
        })).toList();
        notifyListeners();
      }, onError: (error) {
        print("Error listening to recipe updates: $error");
      }).onDone(() {
        print("Listener has been closed");
      });
  } else {
    print("UID is null, stopping listener");
    // Perform any cleanup if necessary
  }
}


  // Fetch recipes from Firestore
  Future<void> fetchRecipes() async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    print("No UID found");
    return;
  }
  try {
    var collection = FirebaseFirestore.instance.collection('users').doc(uid).collection('recipes');
    var snapshot = await collection.get();
    _recipes = snapshot.docs.map((doc) {
      var data = doc.data() as Map<String, dynamic>;
      data['id'] = doc.id; // Add the document ID to the data map
      return Recipe.fromMap(data);
    }).toList();
    print("Fetched ${_recipes.length} recipes with IDs");
    notifyListeners();
  } catch (e) {
    print("Failed to fetch recipes: $e");
  }
}



  // Add a recipe to Firestore and local list
Future<void> addRecipe(Recipe recipe) async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) {
    print("User ID is not available.");
    return;
  }
  try {
    var collection = FirebaseFirestore.instance.collection('users').doc(uid).collection('recipes');
    var docRef = await collection.add(recipe.toMap()); // Firestore creates an ID
  
    // Create a new Recipe with the new ID
    Recipe newRecipe = Recipe(
      id: docRef.id,
      title: recipe.title,
      ingredients: recipe.ingredients,
      description: recipe.description,
      imageUrl: recipe.imageUrl,
    );

    _recipes.add(newRecipe);
    notifyListeners();
    await fetchRecipes(); // Fetch all recipes again to update the UI
  } catch (e) {
    print("Failed to add recipe: $e");
  }
}



  // Remove a recipe from Firestore and local list
  Future<void> removeRecipe(String recipeId) async {
  String? uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid != null) { //&& recipeId.isNotEmpty
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('recipes').doc(recipeId).delete();
    // Firestore deletion is enough since the listener updates the local list
  }
}

}