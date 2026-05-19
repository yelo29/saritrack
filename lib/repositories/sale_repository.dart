import '../models/sale.dart';
import '../database/database_helper.dart';

class SaleRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addSale(Sale sale) async {
    final db = await _dbHelper.database;
    return await db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getAllSales() async {
    final db = await _dbHelper.database;
    final result = await db.query('sales', orderBy: 'created_at DESC');
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByProductId(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(String startDate, String endDate) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'sales',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<int> deleteAllSales() async {
    final db = await _dbHelper.database;
    return await db.delete('sales');
  }

  Future<Sale?> getSaleById(int id) async {
    final db = await _dbHelper.database;
    final maps = await db.query(
      'sales',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Sale.fromMap(maps.first);
  }

  // Calculate total profit for a given date range
  Future<double> calculateProfit(String startDate, String endDate) async {
    final sales = await getSalesByDateRange(startDate, endDate);
    double totalProfit = 0;

    for (final sale in sales) {
      // This would need to be joined with products to get buy_price
      // For now, we'll need to fetch product data separately
      // This is a simplified version
      totalProfit += sale.total;
    }

    return totalProfit;
  }

  // Get sales for the last N days
  Future<List<Sale>> getRecentSales(int days) async {
    final now = DateTime.now();
    final startDate = now.subtract(Duration(days: days)).toIso8601String();
    final endDate = now.toIso8601String();
    
    return await getSalesByDateRange(startDate, endDate);
  }
}
