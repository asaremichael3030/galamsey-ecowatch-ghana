import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class EducationScreen extends StatefulWidget {
  const EducationScreen({super.key});

  @override
  State<EducationScreen> createState() => _EducationScreenState();
}

class _EducationScreenState extends State<EducationScreen> {
  List<Map<String, dynamic>> _articles = [];
  bool _isLoading = true;
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Mining', 'Environment', 'Action', 'General'];

  @override
  void initState() {
    super.initState();
    _loadArticles();
  }

  Future<void> _loadArticles() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.get('/education');
      
      if (response.statusCode == 200 && response.data['success'] == true) {
        final List<dynamic> articlesData = response.data['data']['articles'] ?? [];
        setState(() {
          _articles = articlesData.map((article) => {
            'id': article['id'],
            'title': article['title'] ?? 'Untitled',
            'description': article['description'] ?? '',
            'content': article['content'] ?? '',
            'category': article['category'] ?? 'General',
            'image_url': article['image_url'],
            'published': article['published'] ?? false,
            'author_name': article['author_name'] ?? 'Unknown',
            'created_at': article['created_at'] != null ? DateTime.parse(article['created_at']) : DateTime.now(),
          }).toList();
        });
      }
    } catch (e) {
      print('Error loading education articles: $e');
      // Fallback sample data
      setState(() {
        _articles = [
          {
            'id': 1,
            'title': 'What is Galamsey?',
            'description': 'Understanding illegal mining in Ghana',
            'content': 'Galamsey is the local term for illegal small-scale gold mining in Ghana. It involves the extraction of gold from the earth using rudimentary methods, often causing significant environmental damage including water pollution, deforestation, and land degradation. The practice has become a major environmental concern in Ghana, affecting water bodies and agricultural lands across the country.',
            'category': 'Mining',
            'image_url': null,
            'published': true,
            'author_name': 'EcoWatch Team',
            'created_at': DateTime.now().subtract(const Duration(days: 5)),
          },
          {
            'id': 2,
            'title': 'Effects of Illegal Mining on Rivers',
            'description': 'How galamsey destroys our water bodies',
            'content': 'Illegal mining activities have devastating effects on Ghana\'s rivers. The use of heavy machinery and chemicals like mercury and cyanide pollutes water sources, killing aquatic life and making water unsafe for human consumption. The sedimentation caused by mining activities also affects river flow and can lead to flooding in surrounding communities.',
            'category': 'Environment',
            'image_url': null,
            'published': true,
            'author_name': 'EcoWatch Team',
            'created_at': DateTime.now().subtract(const Duration(days: 3)),
          },
          {
            'id': 3,
            'title': 'How You Can Help Protect the Environment',
            'description': 'Simple steps to make a difference',
            'content': 'Everyone can contribute to protecting Ghana\'s environment. Report illegal mining activities through the EcoWatch platform, educate others about the dangers of galamsey, support sustainable mining practices, and participate in community clean-up exercises. Together, we can make a difference in preserving our natural resources for future generations.',
            'category': 'Action',
            'image_url': null,
            'published': true,
            'author_name': 'EcoWatch Team',
            'created_at': DateTime.now().subtract(const Duration(days: 1)),
          },
        ];
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  List<Map<String, dynamic>> _getFilteredArticles() {
    if (_selectedCategory == 'All') return _articles;
    return _articles.where((article) => article['category'] == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredArticles = _getFilteredArticles();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Education'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadArticles,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Category filter
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
                                _selectedCategory = selected ? category : 'All';
                              });
                            },
                            backgroundColor: Colors.white,
                            selectedColor: const Color(0xFF2E7D32).withOpacity(0.2),
                            labelStyle: TextStyle(
                              color: isSelected ? const Color(0xFF2E7D32) : Colors.grey[600],
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
                
                // Article count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredArticles.length} articles found',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                ),
                
                // Articles list
                Expanded(
                  child: filteredArticles.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.school_outlined,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'No articles found',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Check back later for educational content',
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[400],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredArticles.length,
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];
                            return _buildArticleCard(article);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildArticleCard(Map<String, dynamic> article) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ArticleDetailScreen(article: article),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image if available
            if (article['image_url'] != null)
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: Image.network(
                  article['image_url'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 180,
                      width: double.infinity,
                      color: Colors.green[50],
                      child: const Center(
                        child: Icon(
                          Icons.image,
                          size: 48,
                          color: Colors.grey,
                        ),
                      ),
                    );
                  },
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Category chip
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2E7D32).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      article['category'] ?? 'General',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF2E7D32),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    article['title'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article['description'],
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        article['author_name'] ?? 'Unknown',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(width: 16),
                      Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${article['created_at'].day}/${article['created_at'].month}/${article['created_at'].year}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Article Detail Screen
class ArticleDetailScreen extends StatelessWidget {
  final Map<String, dynamic> article;

  const ArticleDetailScreen({super.key, required this.article});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Article'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Category chip
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF2E7D32).withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                article['category'] ?? 'General',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF2E7D32),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              article['title'],
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  Icons.person_outline,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  article['author_name'] ?? 'Unknown',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
                const SizedBox(width: 16),
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: Colors.grey[500],
                ),
                const SizedBox(width: 4),
                Text(
                  '${article['created_at'].day}/${article['created_at'].month}/${article['created_at'].year}',
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 16),
            Text(
              article['content'],
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[800],
                height: 1.6,
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}