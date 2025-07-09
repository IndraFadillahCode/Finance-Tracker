import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/category/data/datasource/category_remote_datasource.dart';

import 'package:fintrack/features/category/data/models/category_item_model.dart';
import 'add_edit_category_page.dart'; 

class CategoryListPage extends StatefulWidget {
  const CategoryListPage({super.key});

  @override
  State<CategoryListPage> createState() => _CategoryListPageState();
}

class _CategoryListPageState extends State<CategoryListPage> {
  final CategoryRemoteDatasource _categoryDatasource =
      CategoryRemoteDatasource();
  List<CategoryItemModel> _categories = [];
  bool _isLoading = true;
  String? _errorMessage;
  String _selectedCategoryType = 'expense'; 

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        _selectedCategoryType == 'expense'
            ? await _categoryDatasource.getExpenseCategories()
            : await _categoryDatasource.getIncomeCategories();
    result.fold(
      (error) {
        print('Error fetching categories: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load categories: $error';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading categories: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (data) {

        if (mounted) {
          setState(() {
            _categories = data;
            _isLoading = false;
          });
          print(
            'Categories loaded: ${_categories.length} items for $_selectedCategoryType',
          );
        }
      },
    );
  }

  Color _parseColorString(String? colorString) {
    if (colorString == null || colorString.isEmpty) {
      return Colors.grey; // Default fallback
    }

    String hexColor = colorString.replaceAll("#", "");
    if (hexColor.length == 6) {
      hexColor = "FF" + hexColor; // Tambahkan alpha jika hanya RGB
    }
    try {
      if (hexColor.length == 8) {
        // ARGB format (AARRGGBB)
        return Color(int.parse(hexColor, radix: 16));
      }
    } catch (_) {

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
      default:
        return Colors.grey; 
    }
  }


  IconData _getCategoryIcon(String? categoryName, String? categoryType) {
    if (categoryName == null) return Icons.category;
    switch (categoryName.toLowerCase()) {
      case 'food & drinks':
      case 'food':
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

 
  Color _getCategoryIconBgColor(
    String? categoryName,
    String? categoryType,
    String? customColor,
  ) {
    if (customColor != null && customColor.isNotEmpty) {
      return _parseColorString(
        customColor,
      ).withOpacity(0.1); 
    }
   
    if (categoryName == null) return Colors.grey.shade200;
    switch (categoryName.toLowerCase()) {
      case 'food & drinks':
      case 'food':
        return Colors.orange.shade100;
      case 'shopping':
        return Colors.purple.shade100;
      case 'transportation':
        return Colors.blue.shade100;
      case 'entertainment':
        return Colors.pink.shade100;
      case 'bills':
        return Colors.teal.shade100;
      case 'healthcare':
        return Colors.red.shade100;
      case 'education':
        return Colors.lightGreen.shade100;
      case 'salary':
      case 'income':
        return Colors.green.shade100;
      default:
        return categoryType == 'income'
            ? Colors.green.shade100
            : Colors.red.shade100;
    }
  }

  // Fungsi untuk mendapatkan warna ikon
  Color _getCategoryIconColor(
    String? categoryName,
    String? categoryType,
    String? customColor,
  ) {
    if (customColor != null && customColor.isNotEmpty) {
      return _parseColorString(customColor); // Gunakan customColor jika ada
    }
    // Fallback ke logika berdasarkan nama/tipe
    if (categoryName == null) return Colors.grey.shade700;
    switch (categoryName.toLowerCase()) {
      case 'food & drinks':
      case 'food':
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Categories',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorsApp.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false, // Karena ini top-level tab di MainNav
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: ColorsApp.primary), // Ikon Add
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    insetPadding:
                        EdgeInsets.zero, // Membuat dialog memenuhi lebar layar
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    backgroundColor: Colors.white,
                    content: SizedBox(
                      width:
                          MediaQuery.of(context).size.width *
                          0.9, 
                      height:
                          MediaQuery.of(context).size.height *
                          0.7, 
                      child: AddEditCategoryPage(
                  
                        addCategory: () {
                          _fetchCategories(); 
                        },
                      ),
                    ),

                    title: null,
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
     
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedCategoryType = 'expense';
                      });
                      _fetchCategories(); 
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedCategoryType == 'expense'
                              ? ColorsApp.primary
                              : Colors.grey.shade200,
                      foregroundColor:
                          _selectedCategoryType == 'expense'
                              ? Colors.white
                              : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Expense'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        _selectedCategoryType = 'income';
                      });
                      _fetchCategories(); // Refresh data berdasarkan tipe
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          _selectedCategoryType == 'income'
                              ? ColorsApp.primary
                              : Colors.grey.shade200,
                      foregroundColor:
                          _selectedCategoryType == 'income'
                              ? Colors.white
                              : Colors.black87,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Income'),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _categories.isEmpty
                    ? const Center(
                      child: Text(
                        'No categories found for this type.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: _categories.length,
                      itemBuilder: (context, index) {
                        final category = _categories[index];
                        return Card(
                          // Menggunakan Card untuk item list
                          margin:
                              EdgeInsets
                                  .zero, // Menghilangkan margin default Card
                          elevation: 0, // Menghilangkan shadow default Card
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            // Membuat card bisa di-tap
                            onTap: () {
                              // Panggil showDialog untuk detail/edit
                              showDialog(
                                context: context,
                                builder: (context) {
                                  return AlertDialog(
                                    insetPadding: EdgeInsets.zero,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    backgroundColor: Colors.white,
                                    content: SizedBox(
                                      width:
                                          MediaQuery.of(context).size.width *
                                          0.9,
                                      height:
                                          MediaQuery.of(context).size.height *
                                          0.7,
                                      child: AddEditCategoryPage(
                                        categoryToEdit:
                                            category, 
                                        addCategory: () {
                                          _fetchCategories(); 
                                        },
                                      ),
                                    ),
                                    title: Text(
                                      category.name ?? 'Category Detail',
                                    ), 
                                  );
                                },
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundColor: _getCategoryIconBgColor(
                                      category.name,
                                      category.type,
                                      category.color,
                                    ),
                                    radius: 25,
                                    child: Icon(
                                      _getCategoryIcon(
                                        category.name,
                                        category.type,
                                      ),
                                      color: _getCategoryIconColor(
                                        category.name,
                                        category.type,
                                        category.color,
                                      ),
                                      size: 24,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          category.name ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                      separatorBuilder:
                          (context, index) => const SizedBox(height: 10),
                    ),
          ),
        ],
      ),
    );
  }
}
