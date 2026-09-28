import 'package:flutter/material.dart';

class FoodData {
  final String name;
  final IconData icon;

  /// Typical refrigerated shelf life in days for expiry recommendations.
  final int typicalShelfLifeDays;

  /// Typical unit used to pre-select the unit dropdown.
  final String typicalUnit;

  /// Category used for the filter chips.
  final String category;

  const FoodData({
    required this.name,
    required this.icon,
    required this.typicalShelfLifeDays,
    required this.typicalUnit,
    required this.category,
  });
}

/// The filter chip names shown on the home page.
const List<String> foodCategories = [
  "Fruits",
  "Vegetables",
  "Meat & Fish",
  "Dairy & Eggs",
  "Other",
];

const List<FoodData> foodDatabase = [
  // Dairy & Eggs
  FoodData(
      name: "Milk",
      icon: Icons.local_drink,
      typicalShelfLifeDays: 5,
      typicalUnit: "L",
      category: "Dairy & Eggs"),
  FoodData(
      name: "Eggs",
      icon: Icons.egg,
      typicalShelfLifeDays: 21,
      typicalUnit: "pcs",
      category: "Dairy & Eggs"),
  FoodData(
      name: "Cheese",
      icon: Icons.local_pizza,
      typicalShelfLifeDays: 14,
      typicalUnit: "kg",
      category: "Dairy & Eggs"),
  FoodData(
      name: "Butter",
      icon: Icons.breakfast_dining,
      typicalShelfLifeDays: 30,
      typicalUnit: "g",
      category: "Dairy & Eggs"),
  FoodData(
      name: "Yogurt",
      icon: Icons.icecream,
      typicalShelfLifeDays: 7,
      typicalUnit: "g",
      category: "Dairy & Eggs"),
  FoodData(
      name: "Cream",
      icon: Icons.water_drop,
      typicalShelfLifeDays: 7,
      typicalUnit: "ml",
      category: "Dairy & Eggs"),

  // Meat & Fish 
  FoodData(
      name: "Chicken",
      icon: Icons.dinner_dining,
      typicalShelfLifeDays: 2,
      typicalUnit: "kg",
      category: "Meat & Fish"),
  FoodData(
      name: "Ground Beef",
      icon: Icons.lunch_dining,
      typicalShelfLifeDays: 2,
      typicalUnit: "kg",
      category: "Meat & Fish"),
  FoodData(
      name: "Fish",
      icon: Icons.set_meal,
      typicalShelfLifeDays: 2,
      typicalUnit: "kg",
      category: "Meat & Fish"),
  FoodData(
      name: "Sausage",
      icon: Icons.kebab_dining,
      typicalShelfLifeDays: 7,
      typicalUnit: "kg",
      category: "Meat & Fish"),
  FoodData(
      name: "Ham",
      icon: Icons.local_dining,
      typicalShelfLifeDays: 5,
      typicalUnit: "kg",
      category: "Meat & Fish"),

  //Vegetables
  FoodData(
      name: "Tomato",
      icon: Icons.grass,
      typicalShelfLifeDays: 7,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Cucumber",
      icon: Icons.spa,
      typicalShelfLifeDays: 7,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Bell Pepper",
      icon: Icons.spa,
      typicalShelfLifeDays: 7,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Lettuce",
      icon: Icons.grass,
      typicalShelfLifeDays: 5,
      typicalUnit: "pcs",
      category: "Vegetables"),
  FoodData(
      name: "Spinach",
      icon: Icons.eco,
      typicalShelfLifeDays: 5,
      typicalUnit: "g",
      category: "Vegetables"),
  FoodData(
      name: "Broccoli",
      icon: Icons.local_florist,
      typicalShelfLifeDays: 7,
      typicalUnit: "pcs",
      category: "Vegetables"),
  FoodData(
      name: "Mushroom",
      icon: Icons.forest,
      typicalShelfLifeDays: 5,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Carrot",
      icon: Icons.cruelty_free,
      typicalShelfLifeDays: 30,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Potato",
      icon: Icons.agriculture,
      typicalShelfLifeDays: 30,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Onion",
      icon: Icons.agriculture,
      typicalShelfLifeDays: 30,
      typicalUnit: "kg",
      category: "Vegetables"),
  FoodData(
      name: "Garlic",
      icon: Icons.grass,
      typicalShelfLifeDays: 30,
      typicalUnit: "pcs",
      category: "Vegetables"),

  // ---------- Fruits ----------
  FoodData(
      name: "Apple",
      icon: Icons.nature,
      typicalShelfLifeDays: 30,
      typicalUnit: "pcs",
      category: "Fruits"),
  FoodData(
      name: "Banana",
      icon: Icons.energy_savings_leaf,
      typicalShelfLifeDays: 5,
      typicalUnit: "pcs",
      category: "Fruits"),
  FoodData(
      name: "Orange",
      icon: Icons.park,
      typicalShelfLifeDays: 14,
      typicalUnit: "pcs",
      category: "Fruits"),
  FoodData(
      name: "Lemon",
      icon: Icons.eco,
      typicalShelfLifeDays: 21,
      typicalUnit: "pcs",
      category: "Fruits"),

  //Other
  FoodData(
      name: "Bread",
      icon: Icons.bakery_dining,
      typicalShelfLifeDays: 5,
      typicalUnit: "pcs",
      category: "Other"),
  FoodData(
      name: "Juice",
      icon: Icons.local_drink,
      typicalShelfLifeDays: 7,
      typicalUnit: "L",
      category: "Other"),
  FoodData(
      name: "Ketchup",
      icon: Icons.fastfood,
      typicalShelfLifeDays: 30,
      typicalUnit: "ml",
      category: "Other"),
  FoodData(
      name: "Leftovers",
      icon: Icons.restaurant,
      typicalShelfLifeDays: 4,
      typicalUnit: "pcs",
      category: "Other"),
];