import 'package:flutter/foundation.dart';
import '../models/customer.dart';
import '../repositories/customer_repository.dart';

class CustomerProvider with ChangeNotifier {
  final CustomerRepository _repository = CustomerRepository();

  List<Customer> _customers = [];
  List<Customer> get customers => _customers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadCustomers() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _customers = await _repository.getAllCustomers();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addCustomer(Customer customer) async {
    try {
      await _repository.addCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomer(Customer customer) async {
    try {
      await _repository.updateCustomer(customer);
      await loadCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteCustomer(int id) async {
    try {
      await _repository.deleteCustomer(id);
      await loadCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateCustomerBalance(int customerId, double newBalance) async {
    try {
      await _repository.updateCustomerBalance(customerId, newBalance);
      await loadCustomers();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Customer? getCustomerById(int id) {
    try {
      return _customers.firstWhere((c) => c.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<double> getCustomerBalance(int customerId) async {
    try {
      return await _repository.getCustomerBalance(customerId);
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return 0.0;
    }
  }
}
