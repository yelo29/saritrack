import 'package:flutter/material.dart';
import 'product_catalog_screen.dart';
import 'quick_sale_screen.dart';
import 'profit_chart_screen.dart';
import 'supplier_list_screen.dart';
import 'refund_screen.dart' as refund;
import 'resell_screen.dart';
import 'sales_history_screen.dart';
import 'expense_screen.dart';
import 'customer_screen.dart';
import 'backup_restore_screen.dart';
import 'expiring_products_screen.dart';
import 'purchase_order_list_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _currentIndex = 0;

  final List<Widget> _screens = [
    ProductCatalogScreen(),
    QuickSaleScreen(),
    ResellScreen(),
    ReportsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Theme.of(context).colorScheme.surface,
              Theme.of(context).colorScheme.surfaceContainerHighest,
            ],
          ),
        ),
        child: SafeArea(
          child: IndexedStack(
            index: _currentIndex,
            children: _screens,
          ),
        ),
      ),
      bottomNavigationBar: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) {
          return Transform.translate(
            offset: Offset(0, (1 - value) * 50),
            child: Opacity(
              opacity: value,
              child: child,
            ),
          );
        },
        child: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.inventory_2_outlined),
              selectedIcon: Icon(Icons.inventory_2),
              label: 'Inventory',
            ),
            NavigationDestination(
              icon: Icon(Icons.point_of_sale_outlined),
              selectedIcon: Icon(Icons.point_of_sale),
              label: 'Sell',
            ),
            NavigationDestination(
              icon: Icon(Icons.refresh_outlined),
              selectedIcon: Icon(Icons.refresh),
              label: 'Re-Sell',
            ),
            NavigationDestination(
              icon: Icon(Icons.bar_chart_outlined),
              selectedIcon: Icon(Icons.bar_chart),
              label: 'Reports',
            ),
          ],
        ),
      ),
    );
  }
}

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final PageController _pageController = PageController();
  int _currentIndex = 0;

  final List<String> _tabNames = [
    'Profit Chart',
    'Suppliers',
    'Refunds',
    'Sales History',
    'Expenses',
    'Customers',
    'Expiring Products',
    'Purchase Orders',
    'Backup/Restore',
  ];

  final List<Widget> _tabScreens = [
    ProfitChartScreen(),
    SupplierListScreen(),
    refund.RefundScreen(),
    SalesHistoryScreen(),
    ExpenseScreen(),
    CustomerScreen(),
    ExpiringProductsScreen(),
    PurchaseOrderListScreen(),
    BackupRestoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabNames.length, vsync: this);
    
    // When TabController changes, update PageView
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        final newIndex = _tabController.index;
        if (_currentIndex != newIndex) {
          _pageController.animateToPage(
            newIndex,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOutCubic,
          );
          setState(() {
            _currentIndex = newIndex;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gabay sa mga Ulat',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              RichText(
                text: TextSpan(
                  style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                  children: [
                    const TextSpan(text: 'Paano ba basahin ang iyong mga ulat?\n\n'),
                    const TextSpan(text: '1. Profit Chart Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo makikita ang takbo ng iyong kita.\n\n'),
                    const TextSpan(text: '2. Suppliers Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Naglalaman ng listahan ng mga supplier.\n\n'),
                    const TextSpan(text: '3. Refunds Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito nakatala ang lahat ng mga aytem na binalik.\n\n'),
                    const TextSpan(text: '4. Sales History Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo makikita ang buong kasaysayan ng benta.\n\n'),
                    const TextSpan(text: '5. Expenses Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo matutunton ang lahat ng gastusin.\n\n'),
                    const TextSpan(text: '6. Customers Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo makikita ang listahan ng iyong mga regular na customer.\n\n'),
                    const TextSpan(text: '7. Expiring Products Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo makikita ang listahan ng mga products na a-expire na.\n\n'),
                    const TextSpan(text: '8. Backup/Restore Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo pwedeng i-backup ang iyong database.\n\n'),
                    const TextSpan(text: 'Paalala: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: 'Awtomatikong nag-a-update ang mga data na ito sa tuwing may transaksyon.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Naintindihan ko', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTermsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.gavel, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Terms & Policy',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: ListBody(
            children: [
              RichText(
                text: const TextSpan(
                  style: TextStyle(color: Colors.black87, fontSize: 13, height: 1.4),
                  children: [
                    TextSpan(text: 'Patakaran sa Paggamit ng System:\n\n'),
                    TextSpan(text: '1. Seguridad ng Data: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang lahat ng impormasyon ay lokal na nakasave sa iyong device.\n\n'),
                    TextSpan(text: '2. Katumpakan ng Ulat: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang kalkulasyon ay nakadepende sa tamang input ng presyo.\n\n'),
                    TextSpan(text: '3. Pagsasauli ng Aytem: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang bawat refund ay dapat na may wastong dahilan.\n\n'),
                    TextSpan(text: '4. Pagmamay-ari: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang application na ito ay para sa personal o micro-business use.'),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sarado', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tindahan Reports'),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.menu),
            tooltip: 'Mga tabs dito',
            onSelected: (index) {
              // Direct navigation when hamburger menu item is selected
              _pageController.animateToPage(
                index,
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
              );
            },
            itemBuilder: (context) => List.generate(
              _tabNames.length,
              (index) => PopupMenuItem<int>(
                value: index,
                child: Row(
                  children: [
                    if (_currentIndex == index)
                      const Icon(Icons.check, color: Colors.orange, size: 20),
                    const SizedBox(width: 8),
                    Text(_tabNames[index]),
                  ],
                ),
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showHelpDialog(context),
            child: const Text(
              'Paano?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          TextButton(
            onPressed: () => _showTermsDialog(context),
            child: const Text(
              'Policy',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          unselectedLabelStyle: const TextStyle(fontSize: 13),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          tabs: _tabNames.map((name) => Tab(text: name)).toList(),
        ),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
            _tabController.animateTo(index);
          });
        },
        children: _tabScreens,
      ),
    );
  }
}