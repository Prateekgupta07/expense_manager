import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:intl/intl.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'expenses.db');
    return await openDatabase(
      path,
      onCreate: (db, version) {
        return db.execute(
          'CREATE TABLE expenses(id INTEGER PRIMARY KEY, amount REAL, category TEXT, date TEXT, payment_method TEXT)',
        );
      },
      version: 1, // Increment this version number if you modify the schema
    );
  }

  Future<void> insertExpense(double amount, String category, String paymentMethod) async {
    final db = await database;
    final now = DateTime.now();
    final formattedDate = DateFormat('yyyy-MM-dd').format(now);
    await db.insert(
      'expenses',
      {
        'amount': amount,
        'category': category,
        'date': formattedDate,
        'payment_method': paymentMethod,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await database;
    return await db.query('expenses', orderBy: 'date DESC');
  }
  // Original method to fetch expenses for predefined periods (weekly, monthly, yearly)
  Future<List<Map<String, dynamic>>> getExpensesForPeriod(String period) async {
    final db = await database;
    final now = DateTime.now();
    late DateTime startDate;
    if (period == 'weekly') {
      startDate = now.subtract(Duration(days: now.weekday - 1));
    } else if (period == 'monthly') {
      startDate = DateTime(now.year, now.month, 1);
    } else if (period == 'yearly') {
      startDate = DateTime(now.year, 1, 1);
    }
    final startDateStr = DateFormat('yyyy-MM-dd').format(startDate);
    final endDateStr = DateFormat('yyyy-MM-dd').format(now.add(Duration(days: 1))); // inclusive of today
    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDateStr, endDateStr],
    );
  }

  // New method to fetch expenses for a custom period defined by start and end dates
  Future<List<Map<String, dynamic>>> getExpensesForCustomPeriod(String startDate, String endDate) async {
    final db = await database;
    return await db.query(
      'expenses',
      where: 'date BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
    );
  }
}
