import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../services/api_service.dart';

enum CategoryState { idle, loading, loaded, error }

class CategoryProvider with ChangeNotifier {
  CategoryState        _state = CategoryState.idle;
  List<CategoryModel>  _categories = [];
  String?              _errorMessage;

  CategoryState       get state        => _state;
  List<CategoryModel> get categories   => _categories;
  String?             get errorMessage => _errorMessage;

  Future<void> fetchCategories() async {
    _state = CategoryState.loading; notifyListeners();
    try {
      final res   = await ApiService.getCategories();
      _categories = (res['data'] as List).map((e) => CategoryModel.fromJson(e)).toList();
      _state = CategoryState.loaded;
    } catch (e) {
      _state = CategoryState.error;
      _errorMessage = e.toString().replaceAll('Exception: ', '');
    }
    notifyListeners();
  }

  Future<void> createCategory(String name, String color) async {
    await ApiService.createCategory(name, color);
    await fetchCategories();
  }

  Future<void> updateCategory(int id, String name, String color) async {
    await ApiService.updateCategory(id, name, color);
    await fetchCategories();
  }

  Future<void> deleteCategory(int id) async {
    await ApiService.deleteCategory(id);
    _categories.removeWhere((c) => c.id == id);
    notifyListeners();
  }
}
