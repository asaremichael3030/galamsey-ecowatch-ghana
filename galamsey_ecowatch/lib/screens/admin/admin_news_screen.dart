import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_service.dart';

class AdminNewsScreen extends StatefulWidget {
  const AdminNewsScreen({super.key});

  @override
  State<AdminNewsScreen> createState() => _AdminNewsScreenState();
}

class _AdminNewsScreenState extends State<AdminNewsScreen> {
  List<Map<String, dynamic>> _news = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final List<String> _categories = [
    'All', 'Government', 'Community', 'Technology', 'Environment', 'General'
  ];
  final ImagePicker _imagePicker = ImagePicker();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _loadNews();
  }

  Future<void> _loadNews() async {
    setState(() => _isLoading = true);

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.get('/news');

      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> newsData = response.data['data']['news'] ?? [];
        setState(() {
          _news = newsData.map((item) => {
            'id': item['id'],
            'title': item['title'] ?? 'Untitled',
            'content': item['content'] ?? '',
            'category': item['category'] ?? 'General',
            'image_url': item['image_url'],
            'published': item['published'] ?? false,
            'author_name': item['author_name'] ?? 'Unknown',
            'created_at': item['created_at'] != null
                ? DateTime.parse(item['created_at'])
                : DateTime.now(),
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading news: $e');
      setState(() {
        _news = [
          {
            'id': 1,
            'title': 'Government Launches New Environmental Protection Initiative',
            'content': 'The government has announced a new initiative...',
            'category': 'Government',
            'image_url': null,
            'published': true,
            'author_name': 'System Admin',
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
          },
        ];
      });
    }

    setState(() => _isLoading = false);
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 600,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _selectedImage = File(image.path));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _createNews() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String selectedCategory = 'General';
    bool published = false;
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) {
          return AlertDialog(
            title: const Text('Create News'),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title *',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Title is required' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: contentController,
                      maxLines: 5,
                      decoration: const InputDecoration(
                        labelText: 'Content *',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Content is required' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        'General',
                        'Government',
                        'Community',
                        'Technology',
                        'Environment'
                      ]
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (value) {
                        setStateDialog(() => selectedCategory = value!);
                      },
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                          borderRadius: BorderRadius.circular(8),
                          color: Colors.grey[50],
                        ),
                        child: _selectedImage != null
                            ? Stack(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.file(
                                      _selectedImage!,
                                      width: double.infinity,
                                      height: 120,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Positioned(
                                    top: 4,
                                    right: 4,
                                    child: GestureDetector(
                                      onTap: () => setStateDialog(
                                          () => _selectedImage = null),
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(Icons.close,
                                            color: Colors.white, size: 16),
                                      ),
                                    ),
                                  ),
                                ],
                              )
                            : Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.add_photo_alternate,
                                        size: 32, color: Colors.grey[400]),
                                    const SizedBox(height: 4),
                                    Text('Tap to upload image',
                                        style: TextStyle(
                                            color: Colors.grey[600],
                                            fontSize: 12)),
                                  ],
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Publish Immediately'),
                      value: published,
                      onChanged: (v) => setStateDialog(() => published = v),
                      activeColor: const Color(0xFF2E7D32),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (!formKey.currentState!.validate()) return;

                  Navigator.pop(context);

                  try {
                    final apiService = context.read<AuthProvider>().apiService;

                    // NOTE: image upload to Cloudinary is not yet wired for
                    // news articles. Leave image_url null for now.
                    String? imageUrl;
                    if (_selectedImage != null) {
                      imageUrl = null; // TODO: upload via Cloudinary
                    }

                    final response = await apiService.post('/news', data: {
                      'title': titleController.text.trim(),
                      'content': contentController.text.trim(),
                      'category': selectedCategory,
                      'image_url': imageUrl,
                      'published': published,
                    });

                    if (response.statusCode == 201 &&
                        response.data['success'] == true) {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('News created successfully'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      _loadNews();
                    } else {
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(response.data['message'] ??
                              'Failed to create news'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Network error. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                ),
                child: const Text('Create News'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _togglePublish(int newsId, bool currentPublished) async {
    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.put('/news/$newsId', data: {
        'published': !currentPublished,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text('News ${currentPublished ? 'unpublished' : 'published'}'),
            backgroundColor: Colors.green,
          ),
        );
        _loadNews();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _deleteNews(int newsId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete News'),
        content: const Text('Are you sure you want to delete this news item?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final apiService = context.read<AuthProvider>().apiService;
        final response = await apiService.delete('/news/$newsId');

        if (response.statusCode == 200 && response.data['success'] == true) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('News deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
          _loadNews();
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Network error. Please try again.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  List<Map<String, dynamic>> _getFilteredNews() {
    if (_selectedCategory == 'All') return _news;
    return _news.where((item) => item['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredNews = _getFilteredNews();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Manage News'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _createNews,
            tooltip: 'Create News',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNews,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _categories.map((category) {
                        final isSelected = _selectedCategory == category;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(category),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedCategory =
                                    selected ? category : 'All';
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor:
                                const Color(0xFF2E7D32).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? const Color(0xFF2E7D32)
                                  : Colors.grey[600],
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredNews.length} news items found',
                      style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                    ),
                  ),
                ),
                Expanded(
                  child: filteredNews.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.article_outlined,
                                  size: 64, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text('No news found',
                                  style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600])),
                              const SizedBox(height: 8),
                              Text(
                                  'Create news articles to keep users informed',
                                  style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[400])),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: _createNews,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF2E7D32),
                                ),
                                child: const Text('Create News'),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredNews.length,
                          itemBuilder: (context, index) {
                            final item = filteredNews[index];
                            return _buildNewsCard(item);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildNewsCard(Map<String, dynamic> news) {
    final published = news['published'] ?? false;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    news['title'],
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: published
                        ? Colors.green.withOpacity(0.1)
                        : Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    published ? 'Published' : 'Draft',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: published ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              news['content'],
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _buildInfoChip(Icons.category, news['category']),
                _buildInfoChip(Icons.person, news['author_name']),
                _buildInfoChip(
                  Icons.calendar_today,
                  '${news['created_at'].day}/${news['created_at'].month}/${news['created_at'].year}',
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _togglePublish(news['id'], published),
                  style: TextButton.styleFrom(
                    foregroundColor:
                        published ? Colors.orange : Colors.green,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: Text(
                    published ? 'Unpublish' : 'Publish',
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit news coming soon'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Edit',
                      style: TextStyle(fontSize: 12)),
                ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _deleteNews(news['id']),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text('Delete',
                      style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[500]),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}