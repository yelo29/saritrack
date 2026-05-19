import 'package:flutter/foundation.dart';
import '../models/supplier.dart';
import '../repositories/supplier_repository.dart';

class SupplierProvider with ChangeNotifier {
  final SupplierRepository _repository = SupplierRepository();
  
  List<Supplier> _suppliers = [];
  List<Supplier> get suppliers => _suppliers;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  Future<void> loadSuppliers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _suppliers = await _repository.getAllSuppliers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSupplier(Supplier supplier) async {
    try {
      await _repository.addSupplier(supplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSupplier(Supplier supplier) async {
    try {
      await _repository.updateSupplier(supplier);
      await loadSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSupplier(int id) async {
    try {
      await _repository.deleteSupplier(id);
      await loadSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateLastRestockDate(int supplierId) async {
    try {
      await _repository.updateLastRestockDate(supplierId);
      await loadSuppliers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Supplier? getSupplierById(int id) {
    try {
      return _suppliers.firstWhere((s) => s.id == id);
    } catch (e) {
      return null;
    }
  }
}
