import 'package:flutter/foundation.dart';
import '../models/sale.dart';
import '../repositories/sale_repository.dart';
import '../repositories/product_repository.dart';
import '../models/product.dart';
import '../services/notification_service.dart';
import '../repositories/refund_repository.dart';
import '../models/refund.dart';
import '../repositories/expense_repository.dart';

class SaleProvider with ChangeNotifier {
  final SaleRepository _repository = SaleRepository();
  final ProductRepository _productRepository = ProductRepository();
  final RefundRepository _refundRepository = RefundRepository();
  final ExpenseRepository _expenseRepository = ExpenseRepository();
  
  List<Sale> _sales = [];
  List<Sale> get sales => _sales;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  Future<void> loadSales() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _sales = await _repository.getAllSales();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSale(Sale sale) async {
    try {
      await _repository.addSale(sale);
      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Record a sale with stock deduction
  Future<bool> recordSale(int productId, int quantity, double sellPrice, {double? amountPaid, double? changeGiven, String? discountType, double discountValue = 0, double? originalPrice}) async {
    try {
      // Get the product to verify stock
      final product = await _productRepository.getProductById(productId);
      if (product == null) {
        _error = 'Product not found';
        notifyListeners();
        return false;
      }

      if (product.quantity < quantity) {
        _error = 'Insufficient stock';
        notifyListeners();
        return false;
      }

      // Deduct stock
      await _productRepository.deductStock(productId, quantity);

      // Calculate total with discount
      final discountedPrice = product.discountedPrice;
      final totalPrice = quantity * discountedPrice;

      // Create sale record
      final sale = Sale(
        productId: productId,
        qtySold: quantity,
        total: totalPrice,
        createdAt: DateTime.now().toIso8601String(),
        amountPaid: amountPaid,
        changeGiven: changeGiven,
        discountType: product.discountType,
        discountValue: product.discountValue,
        originalPrice: product.sellPrice,
      );

      await _repository.addSale(sale);
      await loadSales();

      // Check for low stock after sale
      await NotificationService.instance.checkLowStockAndNotify();

      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<Sale>> getSalesByDateRange(String startDate, String endDate) async {
    return await _repository.getSalesByDateRange(startDate, endDate);
  }

  Future<List<Sale>> getRecentSales(int days) async {
    return await _repository.getRecentSales(days);
  }

  // Calculate profit for a date range (excluding refunded items and subtracting expenses)
  Future<double> calculateProfit(String startDate, String endDate) async {
    final sales = await getSalesByDateRange(startDate, endDate);
    double totalProfit = 0;

    for (final sale in sales) {
      // Calculate total refunded quantity for this sale
      final refunds = await _refundRepository.getRefundsBySaleId(sale.id!);
      final totalRefundedQuantity = refunds.fold(0, (sum, refund) => sum + refund.quantity);

      // Calculate profit only for non-refunded items
      final nonRefundedQuantity = sale.qtySold - totalRefundedQuantity;

      if (nonRefundedQuantity <= 0) {
        continue; // Skip if fully refunded
      }

      final product = await _productRepository.getProductById(sale.productId);
      if (product != null) {
        final profit = (product.sellPrice - product.buyPrice) * nonRefundedQuantity;
        totalProfit += profit;
      }
    }

    // Subtract expenses from profit
    final totalExpenses = await _expenseRepository.getTotalExpensesByDateRange(startDate, endDate);
    totalProfit -= totalExpenses;

    return totalProfit;
  }

  // Get daily profit for the last N days (excluding refunded items)
  Future<Map<String, double>> getDailyProfit(int days) async {
    final Map<String, double> dailyProfit = {};
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final startDate = DateTime(date.year, date.month, date.day).toIso8601String();
      final endDate = DateTime(date.year, date.month, date.day, 23, 59, 59).toIso8601String();
      
      final profit = await calculateProfit(startDate, endDate);
      dailyProfit[startDate.split('T')[0]] = profit;
    }

    return dailyProfit;
  }

  // Process a refund: add to refunded stock and create refund record
  Future<bool> processRefund(int saleId, String reason, int quantity) async {
    try {
      // Get the sale
      final sale = await _repository.getSaleById(saleId);
      if (sale == null) {
        _error = 'Sale not found';
        notifyListeners();
        return false;
      }

      if (quantity > sale.qtySold) {
        _error = 'Refund quantity cannot exceed sold quantity';
        notifyListeners();
        return false;
      }

      // Calculate proportional refund amount
      final unitPrice = sale.total / sale.qtySold;
      final refundAmount = unitPrice * quantity;

      // Add to refunded stock, not original stock
      await _productRepository.addRefundedStock(sale.productId, quantity);

      // Create refund record
      final refund = Refund(
        saleId: saleId,
        reason: reason,
        refundedAt: DateTime.now().toIso8601String(),
        amount: refundAmount,
        quantity: quantity,
      );
      await _refundRepository.addRefund(refund);

      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Record a sale from refunded stock (Re-Sell)
  Future<bool> recordResale(int productId, int quantity, double sellPrice, {double? amountPaid, double? changeGiven}) async {
    try {
      // Get the product to verify refunded stock
      final product = await _productRepository.getProductById(productId);
      if (product == null) {
        _error = 'Product not found';
        notifyListeners();
        return false;
      }

      if (product.refundedStock < quantity) {
        _error = 'Insufficient refunded stock';
        notifyListeners();
        return false;
      }

      // Deduct from refunded stock
      await _productRepository.deductRefundedStock(productId, quantity);

      // Create sale record with isResold flag
      final sale = Sale(
        productId: productId,
        qtySold: quantity,
        total: quantity * product.discountedPrice,
        createdAt: DateTime.now().toIso8601String(),
        isResold: true,
        amountPaid: amountPaid,
        changeGiven: changeGiven,
        discountType: product.discountType,
        discountValue: product.discountValue,
        originalPrice: product.sellPrice,
      );

      await _repository.addSale(sale);

      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Delete all sales data
  Future<bool> deleteAllSales() async {
    try {
      await _repository.deleteAllSales();
      await loadSales();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
