import 'package:flutter/material.dart';
import 'product_catalog_screen.dart';
import 'quick_sale_screen.dart';
import 'profit_chart_screen.dart';
import 'supplier_list_screen.dart';
import 'refund_screen.dart';
import 'resell_screen.dart';
import 'sales_history_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const ProductCatalogScreen(),
    const QuickSaleScreen(),
    const ResellScreen(),
    const ReportsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: NavigationBar(
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
    );
  }
}

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  // Tutorial Dialog para sa Reports Tab
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
                    const TextSpan(text: 'Dito mo makikita ang takbo ng iyong kita. Ipinapakita nito ang tsart ng kabuuang benta kumpara sa puhunan upang malaman kung '),
                    const TextSpan(text: 'kumikita ba ang tindahan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' sa bawat araw o buwan.\n\n'),
                    const TextSpan(text: '2. Suppliers Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Naglalaman ng listahan ng mga supplier o pinagkunan mo ng mga produkto. Maaari mo silang kontakin para sa '),
                    const TextSpan(text: 'mabilisang re-order', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' ng mga paubos na stock.\n\n'),
                    const TextSpan(text: '3. Refunds Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito nakatala ang lahat ng mga aytem na binalik ng customer. Makikita mo ang dahilan ng pag-refund upang makatulong sa '),
                    const TextSpan(text: 'pagpapanatili ng kalidad', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' ng iyong mga paninda.\n\n'),
                    const TextSpan(text: '4. Sales History Tab: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Dito mo makikita ang buong kasaysayan ng benta. Maaari mong i-filter ayon sa petsa at hanapin ang mga produkto. Nakikita mo rin ang '),
                    const TextSpan(text: 'kabuuang benta', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' at bilang ng aytem na nabenta.\n\n'),
                    const TextSpan(text: 'Paalala: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: 'Awtomatikong nag-a-update ang mga data na ito sa tuwing may nakukumpletong transaksyon sa Sell o Re-Sell tab.'),
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

  // Terms and Policy Dialog
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
                    TextSpan(text: 'Ang lahat ng impormasyon ng produkto, benta, at supplier ay lokal na nakasave sa iyong device. Tiyaking ligtas ang iyong telepono.\n\n'),
                    TextSpan(text: '2. Katumpakan ng Ulat: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang kalkulasyon ng kita at pagbawas sa imbentaryo ay nakadepende sa tamang input ng presyo ng puhunan (cost price) at benta (selling price).\n\n'),
                    TextSpan(text: '3. Pagsasauli ng Aytem: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang bawat refund ay dapat na may wastong dahilan bago ilagay sa Re-Sell stock upang mapanatili ang integridad ng audit logs ng system.\n\n'),
                    TextSpan(text: '4. Pagmamay-ari: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextSpan(text: 'Ang application na ito ay dinisenyo para sa personal o micro-business inventory control at hindi pinapahintulutan ang ilegal na pamamahagi ng source code.'),
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
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Ulat'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [
            // Idinagdag na "Paano?" Button
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
            // Idinagdag na "Terms & Policy" Button
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Profit Chart'),
              Tab(text: 'Suppliers'),
              Tab(text: 'Refunds'),
              Tab(text: 'Sales History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            ProfitChartScreen(),
            SupplierListScreen(),
            RefundScreen(),
            SalesHistoryScreen(),
          ],
        ),
      ),
    );
  }
}