import '../database/database_helper.dart';
import '../models/utang_transaction.dart';

class UtangTransactionRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addUtangTransaction(UtangTransaction transaction) async {
    return await _dbHelper.createUtangTransaction(transaction.toMap());
  }

  Future<List<UtangTransaction>> getUtangTransactionsByCustomerId(int customerId) async {
    final transactionMaps = await _dbHelper.getUtangTransactionsByCustomerId(customerId);
    return transactionMaps.map((map) => UtangTransaction.fromMap(map)).toList();
  }

  Future<List<UtangTransaction>> getAllUtangTransactions() async {
    final transactionMaps = await _dbHelper.getAllUtangTransactions();
    return transactionMaps.map((map) => UtangTransaction.fromMap(map)).toList();
  }
}
