import '../database/database_helper.dart';
import '../models/expense.dart';

class ExpenseRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addExpense(Expense expense) async {
    return await _dbHelper.createExpense(expense.toMap());
  }

  Future<List<Expense>> getAllExpenses() async {
    final expenseMaps = await _dbHelper.getAllExpenses();
    return expenseMaps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<List<Expense>> getExpensesByDateRange(String startDate, String endDate) async {
    final expenseMaps = await _dbHelper.getExpensesByDateRange(startDate, endDate);
    return expenseMaps.map((map) => Expense.fromMap(map)).toList();
  }

  Future<int> updateExpense(Expense expense) async {
    return await _dbHelper.updateExpense(expense.id!, expense.toMap());
  }

  Future<int> deleteExpense(int id) async {
    return await _dbHelper.deleteExpense(id);
  }

  Future<double> getTotalExpensesByDateRange(String startDate, String endDate) async {
    return await _dbHelper.getTotalExpensesByDateRange(startDate, endDate);
  }
}
