import '../models/refund.dart';
import '../database/database_helper.dart';

class RefundRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addRefund(Refund refund) async {
    final db = await _dbHelper.database;
    return await db.insert('refunds', refund.toMap());
  }

  Future<List<Refund>> getAllRefunds() async {
    final db = await _dbHelper.database;
    final result = await db.query('refunds', orderBy: 'refunded_at DESC');
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<List<Refund>> getRefundsBySaleId(int saleId) async {
    final db = await _dbHelper.database;
    final result = await db.query(
      'refunds',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'refunded_at DESC',
    );
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<int> deleteRefund(int id) async {
    final db = await _dbHelper.database;
    return await db.delete(
      'refunds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Refund>> getRefundsByProductId(int productId) async {
    final db = await _dbHelper.database;
    final result = await db.rawQuery('''
      SELECT r.* FROM refunds r
      JOIN sales s ON r.sale_id = s.id
      WHERE s.product_id = ?
      ORDER BY r.refunded_at DESC
    ''', [productId]);
    return result.map((map) => Refund.fromMap(map)).toList();
  }
}
