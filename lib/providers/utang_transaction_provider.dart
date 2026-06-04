import 'package:flutter/foundation.dart';
import '../models/utang_transaction.dart';
import '../repositories/utang_transaction_repository.dart';
import '../repositories/customer_repository.dart';

class UtangTransactionProvider with ChangeNotifier {
  final UtangTransactionRepository _repository = UtangTransactionRepository();
  final CustomerRepository _customerRepository = CustomerRepository();

  List<UtangTransaction> _transactions = [];
  List<UtangTransaction> get transactions => _transactions;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadTransactionsByCustomerId(int customerId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _repository.getUtangTransactionsByCustomerId(customerId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadAllTransactions() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _transactions = await _repository.getAllUtangTransactions();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addUtangTransaction(UtangTransaction transaction) async {
    try {
      await _repository.addUtangTransaction(transaction);

      // Update customer balance
      final currentBalance = await _customerRepository.getCustomerBalance(transaction.customerId);
      double newBalance = currentBalance;

      if (transaction.type == 'credit') {
        newBalance += transaction.amount;
      } else if (transaction.type == 'payment') {
        newBalance -= transaction.amount;
        if (newBalance < 0) newBalance = 0;
      }

      await _customerRepository.updateCustomerBalance(transaction.customerId, newBalance);

      await loadTransactionsByCustomerId(transaction.customerId);
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  double getCustomerCreditTotal(int customerId) {
    return _transactions
        .where((t) => t.customerId == customerId && t.type == 'credit')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getCustomerPaymentTotal(int customerId) {
    return _transactions
        .where((t) => t.customerId == customerId && t.type == 'payment')
        .fold(0.0, (sum, t) => sum + t.amount);
  }

  double getCustomerOutstandingBalance(int customerId) {
    return getCustomerCreditTotal(customerId) - getCustomerPaymentTotal(customerId);
  }
}
