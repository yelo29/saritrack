import '../database/database_helper.dart';
import '../models/supplier.dart';

class SupplierRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addSupplier(Supplier supplier) async {
    return await _dbHelper.createSupplier(supplier);
  }

  Future<Supplier?> getSupplierById(int id) async {
    return await _dbHelper.getSupplier(id);
  }

  Future<List<Supplier>> getAllSuppliers() async {
    return await _dbHelper.getAllSuppliers();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    return await _dbHelper.updateSupplier(supplier);
  }

  Future<int> deleteSupplier(int id) async {
    return await _dbHelper.deleteSupplier(id);
  }

  // Update last restock date for a supplier
  Future<int> updateLastRestockDate(int supplierId) async {
    final supplier = await getSupplierById(supplierId);
    if (supplier == null) return 0;

    final updatedSupplier = supplier.copyWith(
      lastRestockDate: DateTime.now().toIso8601String(),
    );

    return await updateSupplier(updatedSupplier);
  }
}
