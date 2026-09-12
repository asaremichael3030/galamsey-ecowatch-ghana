import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/api_service.dart';
import '../../providers/auth_provider.dart';

class EditNewsDialog extends StatefulWidget {
  final Map<String, dynamic> news;
  final VoidCallback onUpdated;

  const EditNewsDialog({
    super.key,
    required this.news,
    required this.onUpdated,
  });

  @override
  State<EditNewsDialog> createState() => _EditNewsDialogState();
}

class _EditNewsDialogState extends State<EditNewsDialog> {
  late TextEditingController titleController;
  late TextEditingController contentController;
  late String selectedCategory;
  late bool published;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.news['title']);
    contentController = TextEditingController(text: widget.news['content']);
    selectedCategory = widget.news['category'] ?? 'General';
    published = widget.news['published'] ?? false;
  }

  @override
  void dispose() {
    titleController.dispose();
    contentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final apiService = context.read<AuthProvider>().apiService;
      final response = await apiService.put('/news/${widget.news['id']}', data: {
        'title': titleController.text.trim(),
        'content': contentController.text.trim(),
        'category': selectedCategory,
        'published': published,
      });

      if (response.statusCode == 200 && response.data['success'] == true) {
        if (!mounted) return;
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('News updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.data['message'] ?? 'Failed to update news'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Network error. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Edit News'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title *',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Title is required';
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Content is required';
                  return null;
                },
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: selectedCategory,
                decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                ),
                items: ['General', 'Government', 'Community', 'Technology', 'Environment'].map((category) {
                  return DropdownMenuItem(
                    value: category,
                    child: Text(category),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    selectedCategory = value!;
                  });
                },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Published'),
                value: published,
                onChanged: (value) {
                  setState(() {
                    published = value;
                  });
                },
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
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
          ),
          child: const Text('Save Changes'),
        ),
      ],
    );
  }
}