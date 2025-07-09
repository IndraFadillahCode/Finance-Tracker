
import 'package:flutter/material.dart';


Color parseColorString(String? colorString) {
  if (colorString == null || colorString.isEmpty) {
    return Colors.grey; 
  }

  String cleanedColorString = colorString.replaceAll("#", "");


  if (cleanedColorString.length == 6 || cleanedColorString.length == 8) {

    if (cleanedColorString.length == 6) {
      cleanedColorString = "FF" + cleanedColorString;
    }

    try {
      return Color(int.parse(cleanedColorString, radix: 16));
    } catch (_) {

    }
  }

 
  switch (colorString.toLowerCase()) {
   
    case 'red':
      return Colors.red;
    case 'pink':
      return Colors.pink;
    case 'purple':
      return Colors.purple;
    case 'deepPurple':
      return Colors.deepPurple;
    case 'indigo':
      return Colors.indigo;
    case 'blue':
      return Colors.blue;
    case 'lightBlue':
      return Colors.lightBlue;
    case 'cyan':
      return Colors.cyan;
    case 'teal':
      return Colors.teal;
    case 'green':
      return Colors.green;
    case 'lightGreen':
      return Colors.lightGreen;
    case 'lime':
      return Colors.lime;
    case 'yellow':
      return Colors.yellow;
    case 'amber':
      return Colors.amber;
    case 'orange':
      return Colors.orange;
    case 'deepOrange':
      return Colors.deepOrange;
    case 'brown':
      return Colors.brown;
    case 'grey':
      return Colors.grey;
    case 'bluegrey':
      return Colors.blueGrey;
    case 'black':
      return Colors.black;
    case 'white':
      return Colors.white;
  }

  
  return Colors.grey; 
}


class CategoryDisplayHelpers {
  static IconData getCategoryIcon(String? categoryName, String? categoryType) {
    if (categoryName == null) return Icons.category;
    switch (categoryName.toLowerCase()) {
      case 'food & drinks':
      case 'food':
      case 'foods and drink': 
        return Icons.fastfood;
      case 'shopping':
        return Icons.shopping_cart;
      case 'transportation':
        return Icons.directions_car;
      case 'entertainment':
        return Icons.movie;
      case 'bills':
        return Icons.receipt;
      case 'healthcare':
        return Icons.local_hospital;
      case 'education':
        return Icons.school;
      case 'salary':
      case 'income':
        return Icons.attach_money;
      default:
        return categoryType == 'income'
            ? Icons.add_circle
            : Icons.remove_circle;
    }
  }

  static Color _getBaseCategoryColor(
    String? categoryName,
    String? categoryType,
  ) {
    if (categoryName == null) return Colors.grey.shade700;
    switch (categoryName.toLowerCase()) {
      case 'food & drinks':
      case 'food':
      case 'foods and drink': 
        return Colors.orange.shade700;
      case 'shopping':
        return Colors.purple.shade700;
      case 'transportation':
        return Colors.blue.shade700;
      case 'entertainment':
        return Colors.pink.shade700;
      case 'bills':
        return Colors.teal.shade700;
      case 'healthcare':
        return Colors.red.shade700;
      case 'education':
        return Colors.lightGreen.shade700;
      case 'salary':
      case 'income':
        return Colors.green.shade700;
      default:
        return categoryType == 'income'
            ? Colors.green.shade700
            : Colors.red.shade700;
    }
  }

  static Color getCategoryIconColor(
    String? categoryName,
    String? categoryType,
    String? customColor,
  ) {
    if (customColor != null && customColor.isNotEmpty) {
      return parseColorString(customColor);
    }
    return _getBaseCategoryColor(categoryName, categoryType);
  }

  static Color getCategoryIconBgColor(
    String? categoryName,
    String? categoryType,
    String? customColor,
  ) {
    if (customColor != null && customColor.isNotEmpty) {
      return parseColorString(customColor).withOpacity(0.1);
    }
    return _getBaseCategoryColor(categoryName, categoryType).withOpacity(0.1);
  }
}
