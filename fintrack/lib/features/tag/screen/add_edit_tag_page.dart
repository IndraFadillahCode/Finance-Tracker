import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/tag/data/datasource/tag_remote_datasource.dart';
import 'package:fintrack/features/tag/data/models/request/tag_request_model.dart';
import 'package:fintrack/features/tag/data/models/response/tag_item_model.dart';
import 'package:dartz/dartz.dart' hide State; 

class AddEditTagPage extends StatefulWidget {
  final VoidCallback? addTag; 
  final TagItemModel? tagToEdit; 

  const AddEditTagPage({super.key, this.addTag, this.tagToEdit});

  @override
  State<AddEditTagPage> createState() => _AddEditTagPageState();
}

class _AddEditTagPageState extends State<AddEditTagPage> {
  final _formKey = GlobalKey<FormState>();
  final TagRemoteDatasource _tagDatasource = TagRemoteDatasource();

  final TextEditingController _nameController = TextEditingController();
  bool _isLoading = false;
  bool _isDeleting = false; 

  @override
  void initState() {
    super.initState();
    if (widget.tagToEdit != null) {
      _nameController.text = widget.tagToEdit!.name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _saveTag() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    final tagRequest = TagRequestModel(name: _nameController.text);

    Either<String, String> result;
    if (widget.tagToEdit == null) {
      
      result = await _tagDatasource.createTag(tagRequest);
    } else {
      
      result = await _tagDatasource.updateTag(
        widget.tagToEdit!.id!,
        tagRequest,
      );
    }

    result.fold(
      (error) {
        print('Tag save error: $error');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save tag: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (successMessage) {
        print('Tag save success: $successMessage');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(successMessage),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop(); 
          if (widget.addTag != null) {
            widget.addTag!(); 
          }
        }
      },
    );

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  


  Future<void> _deleteTag() async {
    if (widget.tagToEdit == null || widget.tagToEdit!.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tag ID is missing for deletion.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Delete Tag'),
          content: Text(
            'Are you sure you want to delete "${widget.tagToEdit!.name}"? This action cannot be undone.',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
            ),
            TextButton(
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
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

      final result = await _tagDatasource.deleteTag(widget.tagToEdit!.id!);

      if (!mounted) return;
      setState(() {
        _isDeleting = false;
      });

      result.fold(
        (error) {
          print('Error deleting tag: $error');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete tag: $error'),
              backgroundColor: Colors.red,
            ),
          );
        },
        (_) {
          print('Tag deleted successfully!');
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Tag deleted successfully!')),
          );
          Navigator.of(context).pop(); 
          if (widget.addTag != null) {
            widget.addTag!(); 
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: ColorsApp.bgColor,
      appBar: AppBar(
        title: Text(widget.tagToEdit == null ? 'Add New Tag' : 'Edit Tag'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        backgroundColor: ColorsApp.primary, 
        foregroundColor: Colors.white, 
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.all(16.0),
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Tag Name',
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Tag name cannot be empty';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 30),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          if (widget.tagToEdit != null)
                            Expanded(
                              child: ElevatedButton(
                                onPressed: _isDeleting ? null : _deleteTag,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 15,
                                  ),
                                ),
                                child:
                                    _isDeleting
                                        ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                            strokeWidth: 2,
                                          ),
                                        )
                                        : const Text(
                                          'Hapus',
                                          style: TextStyle(fontSize: 16),
                                        ),
                              ),
                            ),
                          if (widget.tagToEdit != null)
                            const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveTag,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorsApp.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 15,
                                ),
                              ),
                              child:
                                  _isLoading
                                      ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
                                          strokeWidth: 2,
                                        ),
                                      )
                                      : Text(
                                        widget.tagToEdit == null
                                            ? 'Add Tag'
                                            : 'Save Changes',
                                        style: const TextStyle(fontSize: 16),
                                      ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
      ),
    );
  }
}
