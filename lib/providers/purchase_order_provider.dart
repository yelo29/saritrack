import 'package:flutter/foundation.dart';
import '../models/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';
import '../services/notification_service.dart';

class PurchaseOrderProvider with ChangeNotifier {
  final PurchaseOrderRepository _repository = PurchaseOrderRepository();
  
  List<PurchaseOrder> _purchaseOrders = [];
  List<PurchaseOrder> get purchaseOrders => _purchaseOrders;
  
  bool _isLoading = false;
  bool get isLoading => _isLoading;
  
  String? _error;
  String? get error => _error;

  Future<void> loadPurchaseOrders() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _purchaseOrders = await _repository.getAllPurchaseOrders();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addPurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      await _repository.addPurchaseOrder(purchaseOrder);
      
      // Schedule delivery notification if delivery date is set
      if (purchaseOrder.hasDeliveryDate) {
        final notificationId = await NotificationService.instance.scheduleDeliveryNotification(purchaseOrder);
        if (notificationId != null) {
          await _repository.updatePurchaseOrder(
            purchaseOrder.copyWith(notificationId: notificationId),
          );
        }
      }
      
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updatePurchaseOrder(PurchaseOrder purchaseOrder) async {
    try {
      await _repository.updatePurchaseOrder(purchaseOrder);
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deletePurchaseOrder(int id) async {
    try {
      final order = await _repository.getPurchaseOrder(id);
      if (order != null) {
        // Cancel delivery notification
        await NotificationService.instance.cancelDeliveryNotification(order.notificationId);
      }
      
      await _repository.deletePurchaseOrder(id);
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsDelivered(int id) async {
    try {
      final order = await _repository.getPurchaseOrder(id);
      if (order != null) {
        // Cancel delivery notification
        await NotificationService.instance.cancelDeliveryNotification(order.notificationId);
        
        final updatedOrder = order.copyWith(status: 'delivered');
        await _repository.updatePurchaseOrder(updatedOrder);
        await loadPurchaseOrders();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> markAsCancelled(int id) async {
    try {
      final order = await _repository.getPurchaseOrder(id);
      if (order != null) {
        // Cancel delivery notification
        await NotificationService.instance.cancelDeliveryNotification(order.notificationId);
        
        final updatedOrder = order.copyWith(status: 'cancelled');
        await _repository.updatePurchaseOrder(updatedOrder);
        await loadPurchaseOrders();
        return true;
      }
      return false;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<List<PurchaseOrder>> getPendingOrders() async {
    return await _repository.getPurchaseOrdersByStatus('pending');
  }

  Future<List<PurchaseOrder>> getDeliveredOrders() async {
    return await _repository.getPurchaseOrdersByStatus('delivered');
  }

  Future<List<PurchaseOrder>> getCancelledOrders() async {
    return await _repository.getPurchaseOrdersByStatus('cancelled');
  }

  Future<List<PurchaseOrder>> getUpcomingDeliveries() async {
    return await _repository.getUpcomingDeliveries();
  }

  Future<List<PurchaseOrder>> getOverdueDeliveries() async {
    return await _repository.getOverdueDeliveries();
  }

  Future<bool> deleteAllPurchaseOrders() async {
    try {
      await _repository.deleteAllPurchaseOrders();
      await loadPurchaseOrders();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
