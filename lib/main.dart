import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'providers/product_provider.dart';
import 'providers/sale_provider.dart';
import 'providers/supplier_provider.dart';
import 'providers/refund_provider.dart';
import 'providers/expense_provider.dart';
import 'providers/customer_provider.dart';
import 'providers/utang_transaction_provider.dart';
import 'providers/purchase_order_provider.dart';
import 'screens/home_screen.dart';
import 'services/seed_data_service.dart';
import 'services/notification_service.dart';
import 'database/database_helper.dart';
import 'theme/app_theme.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  tz.initializeTimeZones();
  await DatabaseHelper.instance.database;
  await NotificationService.instance.initialize();
  await SeedDataService.seedSampleData();
  await NotificationService.instance.checkLowStockAndNotify();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => SaleProvider()),
        ChangeNotifierProvider(create: (_) => SupplierProvider()),
        ChangeNotifierProvider(create: (_) => RefundProvider()),
        ChangeNotifierProvider(create: (_) => ExpenseProvider()),
        ChangeNotifierProvider(create: (_) => CustomerProvider()),
        ChangeNotifierProvider(create: (_) => UtangTransactionProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseOrderProvider()),
      ],
      child: MaterialApp(
        title: 'SariTrack',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.theme,
        home: const HomeScreen(),
      ),
    );
  }
}