import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';
import '../services/map_service.dart';
import 'report_detail_screen.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<Report> _mapReports = [];
  bool _isLoading = true;
  String? _selectedFilter;
  GoogleMapController? _mapController;
  LatLng _currentPosition = const LatLng(6.6756, -1.5705); // Kumasi, Ghana
  final Set<Marker> _markers = {};
  bool _isMapReady = false;

  @override
  void initState() {
    super.initState();
    _loadMapReports();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await MapService.getCurrentLocation();
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
        _isMapReady = true;
      });
      _moveToCurrentLocation();
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _isMapReady = true;
      });
    }
  }

  Future<void> _loadMapReports() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final reportProvider = context.read<ReportProvider>();
      await reportProvider.loadReports();
      
      setState(() {
        _mapReports = reportProvider.reports;
        _isLoading = false;
        _updateMarkers();
      });
    } catch (e) {
      print('Error loading map reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateMarkers() {
    final filteredReports = _getFilteredReports();
    final markers = <Marker>{};

    for (int i = 0; i < filteredReports.length; i++) {
      final report = filteredReports[i];
      if (report.latitude != null && report.longitude != null) {
        final marker = Marker(
          markerId: MarkerId('report_${report.id}'),
          position: LatLng(report.latitude!, report.longitude!),
          infoWindow: InfoWindow(
            title: report.title,
            snippet: '${report.statusDisplayText} - ${report.region ?? 'Unknown'}',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ReportDetailScreen(reportId: report.id),
                ),
              );
            },
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            _getMarkerHue(report.statusColor),
          ),
        );
        markers.add(marker);
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
          CameraPosition(
            target: _currentPosition,
            zoom: 14,
          ),
        ),
      );
    }
  }

  List<Report> _getFilteredReports() {
    if (_selectedFilter == null || _selectedFilter == 'All') {
      return _mapReports;
    }
    return _mapReports.where((report) {
      return report.status == _selectedFilter;
    }).toList();
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
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedFilter = value == 'All' ? null : value;
                _updateMarkers();
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'All',
                child: Text('All Reports'),
              ),
              const PopupMenuItem(
                value: 'pending',
                child: Text('Pending'),
              ),
              const PopupMenuItem(
                value: 'under_review',
                child: Text('Under Review'),
              ),
              const PopupMenuItem(
                value: 'verified',
                child: Text('Verified'),
              ),
              const PopupMenuItem(
                value: 'resolved',
                child: Text('Resolved'),
              ),
              const PopupMenuItem(
                value: 'rejected',
                child: Text('Rejected'),
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMapReports,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Google Map
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: GoogleMap(
                        initialCameraPosition: CameraPosition(
                          target: _currentPosition,
                          zoom: 12,
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
                
                // Report list below map
                Expanded(
                  flex: 2,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
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
                            if (_selectedFilter != null)
                              TextButton(
                                onPressed: () {
                                  setState(() {
                                    _selectedFilter = null;
                                    _updateMarkers();
                                  });
                                },
                                child: const Text(
                                  'Clear Filter',
                                  style: TextStyle(
                                    color: Color(0xFF2E7D32),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: filteredReports.isEmpty
                              ? Center(
                                  child: Text(
                                    'No reports found',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                )
                              : ListView.builder(
                                  itemCount: filteredReports.length > 5 ? 5 : filteredReports.length,
                                  itemBuilder: (context, index) {
                                    final report = filteredReports[index];
                                    return _buildReportListItem(report);
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

  Widget _buildReportListItem(Report report) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ReportDetailScreen(reportId: report.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                color: report.statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    report.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    report.region ?? 'Unknown location',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: report.severityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                report.severity,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: report.severityColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}