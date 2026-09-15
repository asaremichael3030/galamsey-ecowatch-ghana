import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/report_provider.dart';

class CreateReportScreen extends StatefulWidget {
  const CreateReportScreen({super.key});

  @override
  State<CreateReportScreen> createState() => _CreateReportScreenState();
}

class _CreateReportScreenState extends State<CreateReportScreen> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _regionController = TextEditingController();
  final _districtController = TextEditingController();
  final _communityController = TextEditingController();

  // Selected values
  int? _selectedCategoryId;
  String? _selectedSeverity;
  DateTime? _observedDate;
  bool _anonymous = false;

  // Evidence (using XFile for cross-platform support — works on web + mobile)
  List<XFile> _evidenceFiles = [];

  bool _isSubmitting = false;
  bool _isSuccess = false;
  String _submittedReportCode = '';

  final List<String> _severityOptions = ['Low', 'Medium', 'High', 'Critical'];
  final List<Map<String, dynamic>> _categories = [
    {'id': 1, 'name': 'Illegal Excavation', 'icon': Icons.construction},
    {'id': 2, 'name': 'River Pollution', 'icon': Icons.water},
    {'id': 3, 'name': 'Forest Destruction', 'icon': Icons.park},
    {'id': 4, 'name': 'Land Degradation', 'icon': Icons.landscape},
    {'id': 5, 'name': 'Mercury Use', 'icon': Icons.warning_amber},
    {'id': 6, 'name': 'Other', 'icon': Icons.warning},
  ];

  final ImagePicker _imagePicker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _regionController.dispose();
    _districtController.dispose();
    _communityController.dispose();
    super.dispose();
  }

  // ---------- EVIDENCE PICKERS ----------
  Future<void> _pickImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _evidenceFiles.add(image));
      }
    } catch (e) {
      _showError('Error picking image: $e');
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );
      if (image != null) {
        setState(() => _evidenceFiles.add(image));
      }
    } catch (e) {
      _showError('Error taking photo: $e');
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library, color: Color(0xFF2E7D32)),
              title: const Text('Choose from Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage();
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Color(0xFF2E7D32)),
              title: const Text('Take a Photo'),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  // ---------- SUBMIT ----------
  Future<void> _submitReport() async {
    if (!_validateForm()) return;

    setState(() => _isSubmitting = true);

    try {
      final reportProvider = context.read<ReportProvider>();
      final result = await reportProvider.createReport(
        title: _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        categoryId: _selectedCategoryId!,
        severity: _selectedSeverity!,
        observedAt: _observedDate,
        region: _regionController.text.trim().isNotEmpty
            ? _regionController.text.trim()
            : null,
        district: _districtController.text.trim().isNotEmpty
            ? _districtController.text.trim()
            : null,
        community: _communityController.text.trim().isNotEmpty
            ? _communityController.text.trim()
            : null,
        anonymous: _anonymous,
        evidenceFiles: _evidenceFiles,
      );

      setState(() => _isSubmitting = false);
      if (!mounted) return;

      if (result['success'] == true) {
        final report = result['data'];
        setState(() {
          _isSuccess = true;
          _submittedReportCode = report?.reportCode ?? 'ECO-2024-000001';
        });
        context.read<ReportProvider>().loadReports();
        context.read<ReportProvider>().loadUserStats();
      } else {
        _showError(result['message'] ?? 'Failed to submit report');
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showError('Error: $e');
    }
  }

  bool _validateForm() {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a report title');
      return false;
    }
    if (_titleController.text.trim().length < 3) {
      _showError('Title must be at least 3 characters');
      return false;
    }
    if (_descriptionController.text.trim().isEmpty) {
      _showError('Please enter a description');
      return false;
    }
    if (_descriptionController.text.trim().length < 3) {
      _showError('Description must be at least 3 characters');
      return false;
    }
    if (_selectedCategoryId == null) {
      _showError('Please select a category');
      return false;
    }
    if (_selectedSeverity == null) {
      _showError('Please select severity');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    if (_isSuccess) return _buildSuccessScreen();

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Report'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Incident Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- TITLE ----------
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Report Title *',
                hintText: 'Enter a descriptive title (min 3 characters)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- DESCRIPTION ----------
            TextFormField(
              controller: _descriptionController,
              maxLines: 5,
              minLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description *',
                hintText: 'Describe what you observed (min 3 characters)',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),

            // ---------- CATEGORY ----------
            const Text(
              'Category *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _categories.map((category) {
                final isSelected = _selectedCategoryId == category['id'];
                return FilterChip(
                  label: Text(category['name']),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedCategoryId = selected ? category['id'] : null;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: const Color(0xFF2E7D32),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ---------- SEVERITY ----------
            const Text(
              'Severity *',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _severityOptions.map((severity) {
                final isSelected = _selectedSeverity == severity;
                return ChoiceChip(
                  label: Text(severity),
                  selected: isSelected,
                  onSelected: (selected) {
                    setState(() {
                      _selectedSeverity = selected ? severity : null;
                    });
                  },
                  backgroundColor: Colors.grey[200],
                  selectedColor: isSelected
                      ? Colors.green.withOpacity(0.3)
                      : null,
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // ---------- DATE ----------
            ListTile(
              title: const Text('Date Observed'),
              subtitle: Text(
                _observedDate != null
                    ? '${_observedDate!.day}/${_observedDate!.month}/${_observedDate!.year}'
                    : 'Select date',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _observedDate = date);
                }
              },
            ),
            const SizedBox(height: 16),

            // ---------- LOCATION ----------
            const Text(
              'Location',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _regionController,
              decoration: const InputDecoration(
                labelText: 'Region',
                hintText: 'e.g., Ashanti Region',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _districtController,
              decoration: const InputDecoration(
                labelText: 'District',
                hintText: 'e.g., Kumasi',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_city_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _communityController,
              decoration: const InputDecoration(
                labelText: 'Community',
                hintText: 'e.g., Otiinso',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.house_outlined),
              ),
            ),
            const SizedBox(height: 16),

            // ---------- EVIDENCE ----------
            const Text(
              'Add Evidence',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2E7D32),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Upload photos to support your report',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 12),

            InkWell(
              onTap: _showImageSourceDialog,
              child: Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!, width: 2),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[50],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      size: 32,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to add photos',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
            ),

            // Evidence preview list
            if (_evidenceFiles.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text(
                'Uploaded Photos:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 80,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _evidenceFiles.length,
                  itemBuilder: (context, index) {
                    return Stack(
                      children: [
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: FutureBuilder<Uint8List>(
                              future: _evidenceFiles[index].readAsBytes(),
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  return Image.memory(
                                    snapshot.data!,
                                    fit: BoxFit.cover,
                                  );
                                }
                                return const Center(
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        Positioned(
                          top: 0,
                          right: 8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _evidenceFiles.removeAt(index);
                              });
                            },
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.close,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ],

            const SizedBox(height: 16),

            // ---------- ANONYMOUS ----------
            SwitchListTile(
              title: const Text(
                'Report Anonymously',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Your name will not be shown publicly',
                style: TextStyle(color: Colors.grey),
              ),
              value: _anonymous,
              onChanged: (value) => setState(() => _anonymous = value),
              activeColor: const Color(0xFF2E7D32),
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 24),

            // ---------- SUBMIT BUTTON ----------
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E7D32),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Text(
                        'Submit Report',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ---------- SUCCESS SCREEN ----------
  Widget _buildSuccessScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.green[50],
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle,
                    size: 60,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Report Submitted!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your report has been submitted successfully.',
                  style: TextStyle(color: Colors.grey[600]),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Text(
                        'Report ID',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _submittedReportCode,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2E7D32),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E7D32),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Go to Home',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}