import 'package:flutter/material.dart';

class Report {
  final int id;
  final String reportCode;
  final String title;
  final String description;
  final int? categoryId;
  final String? categoryName;
  final String severity;
  final DateTime? observedAt;
  final double? latitude;
  final double? longitude;
  final String? region;
  final String? district;
  final String? community;
  final bool anonymous;
  final String status;
  final int? userId;
  final String? reporterName;
  final int? assignedTo;
  final String? assignedOfficerName;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? distance;

  Report({
    required this.id,
    required this.reportCode,
    required this.title,
    required this.description,
    this.categoryId,
    this.categoryName,
    required this.severity,
    this.observedAt,
    this.latitude,
    this.longitude,
    this.region,
    this.district,
    this.community,
    this.anonymous = false,
    required this.status,
    this.userId,
    this.reporterName,
    this.assignedTo,
    this.assignedOfficerName,
    required this.createdAt,
    this.updatedAt,
    this.distance,
  });

  factory Report.fromJson(Map<String, dynamic> json) {
    return Report(
      id: json['id'] ?? 0,
      reportCode: json['report_code'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      categoryId: json['category_id'],
      categoryName: json['category_name'],
      severity: json['severity'] ?? 'Medium',
      observedAt: json['observed_at'] != null 
          ? DateTime.parse(json['observed_at']) 
          : null,
      latitude: json['latitude'] != null 
          ? double.tryParse(json['latitude'].toString()) 
          : null,
      longitude: json['longitude'] != null 
          ? double.tryParse(json['longitude'].toString()) 
          : null,
      region: json['region'],
      district: json['district'],
      community: json['community'],
      anonymous: json['anonymous'] ?? false,
      status: json['status'] ?? 'pending',
      userId: json['user_id'],
      reporterName: json['reporter_name'],
      assignedTo: json['assigned_to'],
      assignedOfficerName: json['assigned_officer_name'],
      createdAt: json['created_at'] != null 
          ? DateTime.parse(json['created_at']) 
          : DateTime.now(),
      updatedAt: json['updated_at'] != null 
          ? DateTime.parse(json['updated_at']) 
          : null,
      distance: json['distance'] != null 
          ? '${json['distance']} km away' 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'report_code': reportCode,
      'title': title,
      'description': description,
      'category_id': categoryId,
      'category_name': categoryName,
      'severity': severity,
      'observed_at': observedAt?.toIso8601String(),
      'latitude': latitude,
      'longitude': longitude,
      'region': region,
      'district': district,
      'community': community,
      'anonymous': anonymous,
      'status': status,
      'user_id': userId,
      'reporter_name': reporterName,
      'assigned_to': assignedTo,
      'assigned_officer_name': assignedOfficerName,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  // Helper to get status color
  Color get statusColor {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'under_review':
        return Colors.blue;
      case 'verified':
        return Colors.green;
      case 'under_investigation':
        return Colors.purple;
      case 'resolved':
        return const Color(0xFF2E7D32);
      case 'rejected':
        return Colors.red;
      case 'closed':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Helper to get status display text
  String get statusDisplayText {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  // Helper to get severity color
  Color get severityColor {
    switch (severity.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.red;
      case 'critical':
        return Colors.deepPurple;
      default:
        return Colors.grey;
    }
  }
}