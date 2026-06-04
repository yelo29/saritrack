import '../database/database_helper.dart';
import '../models/customer.dart';

class CustomerRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addCustomer(Customer customer) async {
    return await _dbHelper.createCustomer(customer.toMap());
  }

  Future<List<Customer>> getAllCustomers() async {
    final customerMaps = await _dbHelper.getAllCustomers();
    return customerMaps.map((map) => Customer.fromMap(map)).toList();
  }

  Future<Customer?> getCustomerById(int id) async {
    final customerMap = await _dbHelper.getCustomer(id);
    if (customerMap == null) return null;
    return Customer.fromMap(customerMap);
  }

  Future<int> updateCustomer(Customer customer) async {
    return await _dbHelper.updateCustomer(customer.id!, customer.toMap());
  }

  Future<int> deleteCustomer(int id) async {
    return await _dbHelper.deleteCustomer(id);
  }

  Future<int> updateCustomerBalance(int customerId, double newBalance) async {
    return await _dbHelper.updateCustomerBalance(customerId, newBalance);
  }

  Future<double> getCustomerBalance(int customerId) async {
    return await _dbHelper.getCustomerBalance(customerId);
  }
}
