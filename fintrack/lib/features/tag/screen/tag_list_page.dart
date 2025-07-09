import 'package:flutter/material.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/tag/data/datasource/tag_remote_datasource.dart';
import 'package:fintrack/features/tag/data/models/response/tag_item_model.dart';



class TagListPage extends StatefulWidget {
  const TagListPage({super.key});

  @override
  State<TagListPage> createState() => _TagListPageState();
}

class _TagListPageState extends State<TagListPage> {
  final TagRemoteDatasource _tagDatasource = TagRemoteDatasource();
  List<TagItemModel> _tags = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchTags();
  }

  Future<void> _fetchTags() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result =
        await _tagDatasource.getTags(); 
    result.fold(
      (error) {
        print('Error fetching tags: $error');
        if (mounted) {
          setState(() {
            _errorMessage = 'Failed to load tags: $error';
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error loading tags: $error'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      (data) {
        // 'data' adalah ListTagResponseModel
        if (mounted) {
          setState(() {
            _tags = data.results ?? []; // Mengakses properti 'results'
            _isLoading = false;
          });
          print('Tags loaded: ${_tags.length} items');
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Tags',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: ColorsApp.primary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading:
            false, 
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: ColorsApp.primary),
            onPressed: () {
            
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Add New Tag functionality coming soon!'),
                ),
              );
            
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
        
            child:
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _errorMessage != null
                    ? Center(child: Text('Error: $_errorMessage'))
                    : _tags.isEmpty
                    ? const Center(
                      child: Text(
                        'No tags found. Tap "+" to add one!',
                        style: TextStyle(color: Colors.grey),
                      ),
                    )
                    : ListView.separated(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16.0,
                        vertical: 8.0,
                      ),
                      itemCount: _tags.length,
                      itemBuilder: (context, index) {
                        final tag = _tags[index];
                        return Card(
                          margin: EdgeInsets.zero,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: InkWell(
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Tapped on ${tag.name}'),
                                ),
                              );
                              // Navigasi ke halaman Edit Tag
                            },
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Row(
                                children: [
                              
                                  const CircleAvatar(
                                    backgroundColor:
                                        Colors.blueGrey, 
                                    radius: 20,
                                    child: Icon(
                                      Icons.label,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 15),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tag.name ?? 'N/A',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.black87,
                                          ),
                                        ),
                                        Text(
                                          'ID: ${tag.id ?? 'N/A'}', 
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey,
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
