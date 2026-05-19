import 'package:flutter/foundation.dart';
import '../models/refund.dart';
import '../repositories/refund_repository.dart';

class RefundProvider with ChangeNotifier {
  final RefundRepository _repository = RefundRepository();
  
  List<Refund> _refunds = [];
  List<Refund> get refunds => _refunds;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  Future<void> loadRefunds() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _refunds = await _repository.getAllRefunds();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addRefund(Refund refund) async {
    try {
      await _repository.addRefund(refund);
      await loadRefunds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteRefund(int id) async {
    try {
      await _repository.deleteRefund(id);
      await loadRefunds();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Check if a sale has been refunded
  bool isSaleRefunded(int saleId) {
    return _refunds.any((refund) => refund.saleId == saleId);
  }

  // Get refund by sale ID
  Refund? getRefundBySaleId(int saleId) {
    try {
      return _refunds.firstWhere((refund) => refund.saleId == saleId);
    } catch (e) {
      return null;
    }
  }

  // Get refunds by product ID
  Future<List<Refund>> getRefundsByProductId(int productId) async {
    return await _repository.getRefundsByProductId(productId);
  }

  // Get total refunded quantity for a sale
  int getTotalRefundedQuantity(int saleId) {
    return _refunds
        .where((refund) => refund.saleId == saleId)
        .fold(0, (sum, refund) => sum + refund.quantity);
  }
}
