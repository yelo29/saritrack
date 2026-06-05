import '../database/database_helper.dart';
import '../models/purchase_order.dart';

class PurchaseOrderRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addPurchaseOrder(PurchaseOrder purchaseOrder) async {
    final db = await _dbHelper.database;
    return await db.insert('purchase_orders', purchaseOrder.toMap());
  }

  Future<List<PurchaseOrder>> getAllPurchaseOrders() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PurchaseOrder.fromMap(maps[i]));
  }

  Future<List<PurchaseOrder>> getPurchaseOrdersByStatus(String status) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'status = ?',
      whereArgs: [status],
      orderBy: 'delivery_date ASC',
    );
    return List.generate(maps.length, (i) => PurchaseOrder.fromMap(maps[i]));
  }

  Future<List<PurchaseOrder>> getPurchaseOrdersBySupplier(int supplierId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'supplier_id = ?',
      whereArgs: [supplierId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PurchaseOrder.fromMap(maps[i]));
  }

  Future<List<PurchaseOrder>> getPurchaseOrdersByProduct(int productId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return List.generate(maps.length, (i) => PurchaseOrder.fromMap(maps[i]));
  }

  Future<PurchaseOrder?> getPurchaseOrder(int id) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
    if (maps.isEmpty) return null;
    return PurchaseOrder.fromMap(maps.first);
  }

  Future<int> updatePurchaseOrder(PurchaseOrder purchaseOrder) async {
    final db = await _dbHelper.database;
    return await db.update(
      'purchase_orders',
      purchaseOrder.toMap(),
      where: 'id = ?',
      whereArgs: [purchaseOrder.id],
    );
  }

  Future<int> deletePurchaseOrder(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'purchase_orders',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteAllPurchaseOrders() async {
    final db = await _dbHelper.database;
    return await db.delete('purchase_orders');
  }

  Future<List<PurchaseOrder>> getUpcomingDeliveries() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    final twoDaysLater = DateTime.now().add(const Duration(days: 2)).toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'delivery_date BETWEEN ? AND ? AND status = ?',
      whereArgs: [now, twoDaysLater, 'pending'],
      orderBy: 'delivery_date ASC',
    );
    return List.generate(maps.length, (i) => PurchaseOrder.fromMap(maps[i]));
  }

  Future<List<PurchaseOrder>> getOverdueDeliveries() async {
    final db = await _dbHelper.database;
    final now = DateTime.now().toIso8601String();
    
    final List<Map<String, dynamic>> maps = await db.query(
      'purchase_orders',
      where: 'delivery_date < ? AND status = ?',
      whereArgs: [now, 'pending'],
      orderBy: 'delivery_date ASC',
    );
    return List.generate(maps.length, (i) => PurchaseOrder.fromMap(maps[i]));
  }
}
