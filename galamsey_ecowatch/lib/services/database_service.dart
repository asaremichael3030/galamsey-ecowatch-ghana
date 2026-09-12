import 'package:sqflite/sqflite.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart';
import 'dart:io';
import '../models/report_model.dart';
import '../models/notification_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    Directory documentsDirectory = await getApplicationDocumentsDirectory();
    String path = join(documentsDirectory.path, 'ecowatch.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: _onCreate,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Users table
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY,
        full_name TEXT,
        email TEXT,
        phone TEXT,
        role TEXT,
        region TEXT,
        district TEXT,
        profile_image TEXT,
        is_active INTEGER
      )
    ''');

    // Reports table
    await db.execute('''
      CREATE TABLE reports (
        id INTEGER PRIMARY KEY,
        report_code TEXT,
        title TEXT,
        description TEXT,
        category_id INTEGER,
        category_name TEXT,
        severity TEXT,
        status TEXT,
        region TEXT,
        district TEXT,
        community TEXT,
        latitude REAL,
        longitude REAL,
        anonymous INTEGER,
        reporter_name TEXT,
        observed_at TEXT,
        created_at TEXT,
        updated_at TEXT
      )
    ''');

    // Notifications table
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY,
        user_id INTEGER,
        title TEXT,
        message TEXT,
        type TEXT,
        related_id INTEGER,
        related_type TEXT,
        is_read INTEGER,
        created_at TEXT
      )
    ''');

    // Alerts table
    await db.execute('''
      CREATE TABLE alerts (
        id INTEGER PRIMARY KEY,
        title TEXT,
        description TEXT,
        category TEXT,
        severity TEXT,
        region TEXT,
        start_date TEXT,
        end_date TEXT,
        is_active INTEGER,
        created_at TEXT
      )
    ''');

    print('Database tables created successfully');
  }

  // ============ USER METHODS ============
  Future<void> saveUser(Map<String, dynamic> user) async {
    final db = await database;
    await db.insert(
      'users',
      user,
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<Map<String, dynamic>?> getUser() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('users', limit: 1);
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<void> deleteUser() async {
    final db = await database;
    await db.delete('users');
  }

  // ============ REPORT METHODS ============
  Future<void> saveReports(List<Report> reports) async {
    final db = await database;
    for (var report in reports) {
      await db.insert(
        'reports',
        {
          'id': report.id,
          'report_code': report.reportCode,
          'title': report.title,
          'description': report.description,
          'category_id': report.categoryId,
          'category_name': report.categoryName,
          'severity': report.severity,
          'status': report.status,
          'region': report.region,
          'district': report.district,
          'community': report.community,
          'latitude': report.latitude,
          'longitude': report.longitude,
          'anonymous': report.anonymous ? 1 : 0,
          'reporter_name': report.reporterName,
          'observed_at': report.observedAt?.toIso8601String(),
          'created_at': report.createdAt.toIso8601String(),
          'updated_at': report.updatedAt?.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Report>> getReports() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('reports');
    return results.map((map) => Report(
      id: map['id'],
      reportCode: map['report_code'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      categoryId: map['category_id'],
      categoryName: map['category_name'],
      severity: map['severity'] ?? 'Medium',
      status: map['status'] ?? 'pending',
      region: map['region'],
      district: map['district'],
      community: map['community'],
      latitude: map['latitude'],
      longitude: map['longitude'],
      anonymous: map['anonymous'] == 1,
      reporterName: map['reporter_name'],
      observedAt: map['observed_at'] != null ? DateTime.parse(map['observed_at']) : null,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
      updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
    )).toList();
  }

  Future<Report?> getReportById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'reports',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (results.isNotEmpty) {
      final map = results.first;
      return Report(
        id: map['id'],
        reportCode: map['report_code'] ?? '',
        title: map['title'] ?? '',
        description: map['description'] ?? '',
        categoryId: map['category_id'],
        categoryName: map['category_name'],
        severity: map['severity'] ?? 'Medium',
        status: map['status'] ?? 'pending',
        region: map['region'],
        district: map['district'],
        community: map['community'],
        latitude: map['latitude'],
        longitude: map['longitude'],
        anonymous: map['anonymous'] == 1,
        reporterName: map['reporter_name'],
        observedAt: map['observed_at'] != null ? DateTime.parse(map['observed_at']) : null,
        createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
        updatedAt: map['updated_at'] != null ? DateTime.parse(map['updated_at']) : null,
      );
    }
    return null;
  }

  Future<void> deleteReports() async {
    final db = await database;
    await db.delete('reports');
  }

  // ============ NOTIFICATION METHODS ============
  Future<void> saveNotifications(List<AppNotification> notifications) async {
    final db = await database;
    for (var notification in notifications) {
      await db.insert(
        'notifications',
        {
          'id': notification.id,
          'user_id': notification.userId,
          'title': notification.title,
          'message': notification.message,
          'type': notification.type,
          'related_id': notification.relatedId,
          'related_type': notification.relatedType,
          'is_read': notification.isRead ? 1 : 0,
          'created_at': notification.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<AppNotification>> getNotifications() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query(
      'notifications',
      orderBy: 'created_at DESC',
    );
    return results.map((map) => AppNotification(
      id: map['id'],
      userId: map['user_id'],
      title: map['title'] ?? '',
      message: map['message'] ?? '',
      type: map['type'] ?? 'general',
      relatedId: map['related_id'],
      relatedType: map['related_type'],
      isRead: map['is_read'] == 1,
      createdAt: map['created_at'] != null ? DateTime.parse(map['created_at']) : DateTime.now(),
    )).toList();
  }

  Future<void> deleteNotifications() async {
    final db = await database;
    await db.delete('notifications');
  }

  // ============ ALERT METHODS ============
  Future<void> saveAlerts(List<Map<String, dynamic>> alerts) async {
    final db = await database;
    for (var alert in alerts) {
      await db.insert(
        'alerts',
        alert,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
  }

  Future<List<Map<String, dynamic>>> getAlerts() async {
    final db = await database;
    return await db.query('alerts', orderBy: 'created_at DESC');
  }

  // ============ CLEAR ALL ============
  Future<void> clearAllData() async {
    final db = await database;
    await db.delete('users');
    await db.delete('reports');
    await db.delete('notifications');
    await db.delete('alerts');
  }

  // ============ CHECK CONNECTION ============
  Future<bool> hasData() async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.query('reports', limit: 1);
    return results.isNotEmpty;
  }
}