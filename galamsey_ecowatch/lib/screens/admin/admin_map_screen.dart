import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../providers/report_provider.dart';
import '../../models/report_model.dart';
import '../../services/map_service.dart';
import '../report_detail_screen.dart';

class AdminMapScreen extends StatefulWidget {
  const AdminMapScreen({super.key});

  @override
  State<AdminMapScreen> createState() => _AdminMapScreenState();
}

class _AdminMapScreenState extends State<AdminMapScreen> {
  List<Report> _mapReports = [];
  bool _isLoading = true;
  String _selectedStatus = 'All';
  String _selectedSeverity = 'All';
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(6.6756, -1.5705); // Kumasi, Ghana
  final Set<Marker> _markers = {};
  bool _isMapReady = false;

  final List<String> _statuses = [
    'All', 'pending', 'under_review', 'verified',
    'under_investigation', 'resolved', 'rejected', 'closed'
  ];
  final List<String> _severities = ['All', 'Low', 'Medium', 'High', 'Critical'];

  @override
  void initState() {
    super.initState();
    _loadReports();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await MapService.getCurrentLocation();
      if (!mounted) return;
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
      });
      _moveToCurrentLocation();
    } catch (e) {
      print('Location error: $e');
      if (!mounted) return;
      setState(() => _isMapReady = true);
    }
  }

  Future<void> _loadReports() async {
    setState(() => _isLoading = true);
    try {
      final reportProvider = context.read<ReportProvider>();
      await reportProvider.loadAdminReports();
      if (!mounted) return;
      setState(() {
        _mapReports = reportProvider.reports;
        _isLoading = false;
      });
      _updateMarkers();
    } catch (e) {
      print('Error loading admin reports: $e');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  List<Report> _getFilteredReports() {
    var filtered = _mapReports;
    if (_selectedStatus != 'All') {
      filtered = filtered.where((r) => r.status == _selectedStatus).toList();
    }
    if (_selectedSeverity != 'All') {
      filtered = filtered.where((r) => r.severity == _selectedSeverity).toList();
    }
    return filtered;
  }

  void _updateMarkers() {
    final filtered = _getFilteredReports();
    final markers = <Marker>{};

    for (final report in filtered) {
      // Only add markers for reports with valid coordinates
      if (report.latitude != null && report.longitude != null) {
        markers.add(
          Marker(
            markerId: MarkerId('admin_report_${report.id}'),
            position: LatLng(report.latitude!, report.longitude!),
            infoWindow: InfoWindow(
              title: report.title,
              snippet: '${report.statusDisplayText} • ${report.severity} • ${report.region ?? 'Unknown'}',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ReportDetailScreen(reportId: report.id),
                  ),
                );
              },
            ),
            icon: BitmapDescriptor.defaultMarkerWithHue(
              _getMarkerHue(report.statusColor),
            ),
          ),
        );
      }
    }

    setState(() {
      _markers.clear();
      _markers.addAll(markers);
    });
  }

  double _getMarkerHue(Color color) {
    if (color == Colors.green) return BitmapDescriptor.hueGreen;
    if (color == Colors.red) return BitmapDescriptor.hueRed;
    if (color == Colors.blue) return BitmapDescriptor.hueBlue;
    if (color == Colors.orange) return BitmapDescriptor.hueOrange;
    if (color == Colors.yellow) return BitmapDescriptor.hueYellow;
    if (color == Colors.purple) return BitmapDescriptor.hueViolet;
    return BitmapDescriptor.hueAzure;
  }

  void _moveToCurrentLocation() {
    if (_mapController != null && _isMapReady) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: _currentPosition, zoom: 12),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final filteredReports = _getFilteredReports();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Map View'),
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: const Color(0xFF2E7D32),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // ---------- Filters ----------
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedStatus,
                          decoration: InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8,
                            ),
                          ),
                          items: _statuses.map((status) {
                            return DropdownMenuItem(
                              value: status,
                              child: Text(
                                status == 'All'
                                    ? 'All Statuses'
                                    : status.split('_').map((w) =>
                                        w[0].toUpperCase() + w.substring(1),
                                      ).join(' '),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedStatus = value!);
                            _updateMarkers();
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: _selectedSeverity,
                          decoration: InputDecoration(
                            labelText: 'Severity',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8,
                            ),
                          ),
                          items: _severities.map((s) {
                            return DropdownMenuItem(
                              value: s,
                              child: Text(s == 'All' ? 'All Severities' : s),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSeverity = value!);
                            _updateMarkers();
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                // ---------- Google Map ----------
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition,
                          zoom: 11,
                        ),
                        markers: _markers,
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _moveToCurrentLocation();
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: false,
                        zoomControlsEnabled: true,
                        mapType: MapType.normal,
                      ),
                    ),
                  ),
                ),

                // ---------- Report List Below ----------
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Reports (${filteredReports.length})',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            if (_selectedStatus != 'All' || _selectedSeverity != 'All')
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedStatus = 'All';
                                    _selectedSeverity = 'All';
                                  });
                                  _updateMarkers();
                                },
                                child: const Text(
                                  'Clear Filters',
                                  style: TextStyle(color: Color(0xFF2E7D32)),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: filteredReports.isEmpty
                              ? Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.map_outlined,
                                          size: 48, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'No reports to display',
                                        style: TextStyle(color: Colors.grey[600]),
                                      ),
                                    ],
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredReports.length,
                                  itemBuilder: (context, index) {
                                    final report = filteredReports[index];
                                    return Card(
                                      margin: const EdgeInsets.only(bottom: 8),
                                      child: ListTile(
                                        leading: Container(
                                          width: 4,
                                          height: 40,
                                          decoration: BoxDecoration(
                                            color: report.statusColor,
                                            borderRadius: BorderRadius.circular(2),
                                          ),
                                        ),
                                        title: Text(
                                          report.title,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        subtitle: Text(
                                          report.region ?? 'Unknown location',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[500],
                                          ),
                                        ),
                                        trailing: Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: report.statusColor.withOpacity(0.15),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            report.statusDisplayText,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: report.statusColor,
                                            ),
                                          ),
                                        ),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => ReportDetailScreen(
                                                reportId: report.id,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}