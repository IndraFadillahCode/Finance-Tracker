import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/category/data/datasource/category_remote_datasource.dart';
import 'package:fintrack/features/category/data/models/category_item_model.dart';
import 'package:fintrack/features/category/data/models/request/category_request_model.dart';

class AddEditCategoryPage extends StatefulWidget {
  final CategoryItemModel? categoryToEdit;
  final VoidCallback
  addCategory; 

  const AddEditCategoryPage({
    super.key,
    this.categoryToEdit,
    required this.addCategory,
  });

  @override
  State<AddEditCategoryPage> createState() => _AddEditCategoryPageState();
}

class _AddEditCategoryPageState extends State<AddEditCategoryPage> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _iconController = TextEditingController();
  final TextEditingController _colorController = TextEditingController();
  String _selectedType = 'expense'; 

  final CategoryRemoteDatasource _categoryDatasource =
      CategoryRemoteDatasource();
  bool _isSaving = false;
  bool _isDeleting = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeInOut);
    _animController.forward();
    if (widget.categoryToEdit != null) {
      _nameController.text = widget.categoryToEdit!.name ?? '';
      _iconController.text = widget.categoryToEdit!.icon ?? '';
      _colorController.text = widget.categoryToEdit!.color ?? '';
      _selectedType = widget.categoryToEdit!.type ?? 'expense';
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _iconController.dispose();
    _colorController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    if (_formKey.currentState?.validate() ?? false) {
      if (!mounted) return;
      setState(() {
        _isSaving = true;
      });

      final CategoryRequestModel requestModel = CategoryRequestModel(
        name: _nameController.text,
        type: _selectedType,
        icon: _iconController.text,
        color: _colorController.text,
      );

      final result =
          widget.categoryToEdit == null
              ? await _categoryDatasource.createCategory(requestModel)
              : await _categoryDatasource.updateCategory(
                requestModel,
                widget.categoryToEdit!.id!,
              );

      if (!mounted) return;
      setState(() {
        _isSaving = false;
      });

      result.fold(
        (error) {
          print('Error saving category: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save category: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (successMessage) {
          print('Category save success: $successMessage');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                successMessage,
              ), // <<< Tampilkan langsung successMessage
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); // Tutup dialog
          widget.addCategory(); // Panggil callback untuk refresh list
        },
      );
    }
  }

  // --- FUNGSI BARU: _deleteCategory ---
  Future<void> _deleteCategory() async {
    if (widget.categoryToEdit == null || widget.categoryToEdit!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Category ID is missing for deletion.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Tampilkan dialog konfirmasi
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Category'),
          content: Text(
            'Are you sure you want to delete "${widget.categoryToEdit!.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(false); // Tutup dialog, return false
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(
                  dialogContext,
                ).pop(true); // Tutup dialog, return true
              },
            ),
          ],
        );
      },
    );

    if (confirm == true) {
      if (!mounted) return;
      setState(() {
        _isDeleting = true;
      });

      final result = await _categoryDatasource.deleteCategory(
        widget.categoryToEdit!.id!,
      );

      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });

      result.fold(
        (error) {
          print('Error deleting category: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete category: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
         
          print('Category deleted successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Category deleted successfully!')),
          );
          Navigator.of(context).pop(); 
          widget
              .addCategory(); 
        },
      );
    }
  }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(_fadeAnim),
        child: Center(
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            color: Colors.white,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          widget.categoryToEdit == null
                              ? 'Add New Category'
                              : 'Edit Category',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.grey),
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        labelText: 'Category Name',
                        prefixIcon: Icon(Icons.label, color: ColorsApp.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter category name';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildTypePill('Expense', 'expense'),
                        const SizedBox(width: 10),
                        _buildTypePill('Income', 'income'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _iconController,
                      decoration: InputDecoration(
                        labelText: 'Icon Name (e.g., fastfood, shopping_cart)',
                        prefixIcon: Icon(Icons.category, color: ColorsApp.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _colorController,
                      decoration: InputDecoration(
                        labelText: 'Color (e.g., #FF5733 or purple)',
                        prefixIcon: Icon(Icons.color_lens, color: ColorsApp.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (widget.categoryToEdit != null)
                          Flexible(
                            child: AnimatedBuilder(
                              animation: _fadeAnim,
                              builder: (context, child) => Transform.scale(
                                scale: 0.95 + 0.05 * _fadeAnim.value,
                                child: Opacity(opacity: _fadeAnim.value, child: child),
                              ),
                              child: TextButton(
                                onPressed: _isDeleting ? null : _deleteCategory,
                                child: _isDeleting
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(
                                            Colors.red,
                                          ),
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text(
                                        'Delete',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        if (widget.categoryToEdit != null)
                          const SizedBox(width: 10),
                        Flexible(
                          child: AnimatedBuilder(
                            animation: _fadeAnim,
                            builder: (context, child) => Transform.scale(
                              scale: 0.95 + 0.05 * _fadeAnim.value,
                              child: Opacity(opacity: _fadeAnim.value, child: child),
                            ),
                            child: TextButton(
                              onPressed: _isSaving ? null : _saveCategory,
                              child: _isSaving
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(
                                          ColorsApp.primary,
                                        ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      widget.categoryToEdit == null
                                          ? 'Add Category'
                                          : 'Save Changes',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: ColorsApp.primary,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTypePill(String text, String type) {
    final bool selected = _selectedType == type;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: ChoiceChip(
          label: Text(text, style: TextStyle(fontWeight: FontWeight.bold, color: selected ? Colors.white : Colors.black)),
          selected: selected,
          selectedColor: ColorsApp.primary,
          backgroundColor: Colors.grey[200],
          onSelected: (val) {
            setState(() {
              _selectedType = type;
            });
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          labelPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        ),
      ),
    );
  }
}
