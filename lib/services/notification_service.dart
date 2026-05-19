import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../database/database_helper.dart';
import '../models/product.dart';

class NotificationService {
  static final NotificationService instance = NotificationService._init();
  static final FlutterLocalNotificationsPlugin _notificationsPlugin =
      FlutterLocalNotificationsPlugin();

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

  Future<void> cancelAllNotifications() async {
    await _notificationsPlugin.cancelAll();
  }
}
