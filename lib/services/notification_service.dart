import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../database/database_helper.dart';
import '../models/product.dart';
import '../models/purchase_order.dart';
import '../repositories/purchase_order_repository.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();
  final PurchaseOrderRepository _purchaseOrderRepository = PurchaseOrderRepository();

  NotificationService._init();

  Future<void> initialize() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const InitializationSettings initializationSettings =
        InitializationSettings(android: initializationSettingsAndroid);

    await _notificationsPlugin.initialize(initializationSettings);

    // Request permission (for Android 13+)
    await _notificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> checkLowStockAndNotify() async {
    final dbHelper = DatabaseHelper.instance;
    final lowStockProducts = await dbHelper.getLowStockProducts();

    if (lowStockProducts.isEmpty) return;

    for (final product in lowStockProducts) {
      await _showLowStockNotification(product);
    }
  }

  Future<void> _showLowStockNotification(Product product) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'low_stock_channel',
      'Low Stock Alerts',
      channelDescription: 'Notifications for low stock items',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      product.id!,
      'Alerto: Mababa na ang stock',
      '${product.name} - mababa na ang stock! Stock: ${product.quantity}',
      platformChannelSpecifics,
    );
  }

  Future<void> scheduleDailyLowStockSummary() async {
    // This would schedule a daily notification at 8 AM
    // For simplicity, we'll just show it immediately when called
    final dbHelper = DatabaseHelper.instance;
    final lowStockProducts = await dbHelper.getLowStockProducts();

    if (lowStockProducts.isEmpty) return;

    final productNames = lowStockProducts.map((p) => p.name).join(', ');

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'daily_summary_channel',
      'Daily Stock Summary',
      channelDescription: 'Daily summary of low stock items',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    await _notificationsPlugin.show(
      999,
      'Daily Low Stock Summary',
      'Mababa na ang stock: $productNames',
      platformChannelSpecifics,
    );
  }

  // Schedule delivery notification for a purchase order
  Future<int?> scheduleDeliveryNotification(PurchaseOrder order) async {
    if (!order.hasDeliveryDate || order.isDelivered || order.isCancelled) {
      return null;
    }

    final deliveryDate = DateTime.parse(order.deliveryDate!);
    final notificationDate = deliveryDate.subtract(const Duration(days: 1));
    final now = DateTime.now();

    // Only schedule if notification date is in the future
    if (notificationDate.isBefore(now)) {
      return null;
    }

    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'delivery_channel',
      'Delivery Reminders',
      channelDescription: 'Notifications for purchase order deliveries',
      importance: Importance.high,
      priority: Priority.high,
    );

    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);

    final notificationId = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    await _notificationsPlugin.zonedSchedule(
      notificationId,
      'Delivery Reminder',
      'Ang order mo ay dadating bukas! Product ID: ${order.productId}',
      tz.TZDateTime.from(notificationDate, tz.local),
      platformChannelSpecifics,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
    );

    return notificationId;
  }

  // Check for upcoming deliveries and schedule notifications
  Future<void> checkUpcomingDeliveries() async {
    final upcomingDeliveries = await _purchaseOrderRepository.getUpcomingDeliveries();

    for (final order in upcomingDeliveries) {
      if (order.notificationId == null) {
        final notificationId = await scheduleDeliveryNotification(order);
        if (notificationId != null) {
          // Update the order with the notification ID
          await _purchaseOrderRepository.updatePurchaseOrder(
            order.copyWith(notificationId: notificationId),
          );
        }
      }
    }
  }

  // Cancel notification for a specific purchase order
  Future<void> cancelDeliveryNotification(int? notificationId) async {
    if (notificationId != null) {
      await _notificationsPlugin.cancel(notificationId);
    }
  }

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
