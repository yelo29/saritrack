import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../models/product.dart';
import 'checkout_screen.dart';
import 'barcode_scanner_screen.dart';

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> with SingleTickerProviderStateMixin {
  final Map<int, int> _cart = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  int _selectedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double get _total {
    final productProvider = context.read<ProductProvider>();
    double total = 0;
    _cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) total += product.discountedPrice * quantity;
    });
    return total;
  }

  int get _itemCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  void _addToCart(Product product) {
    final currentInCart = _cart[product.id!] ?? 0;
    final maxQuantity = product.quantity - currentInCart;

    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} - wala nang stock'), behavior: SnackBarBehavior.floating),
      );
      return;
    }

    int quantityToAdd = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: AlertDialog(
            title: Text('Magdagdag ng ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B8A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Stock available: ${product.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('In Cart: $currentInCart', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Ilang units ang idadagdag?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantityToAdd > 1 ? () => setDialogState(() => quantityToAdd--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A6B8A).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text('$quantityToAdd', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: quantityToAdd < maxQuantity ? () => setDialogState(() => quantityToAdd++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  setState(() => _cart[product.id!] = currentInCart + quantityToAdd);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC4793A)),
                child: const Text('Idagdag'),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  Future<void> _navigateToCheckout() async {
    final result = await Navigator.push(context, MaterialPageRoute(builder: (context) => CheckoutScreen(cart: _cart)));
    if (result == true && mounted) setState(() => _cart.clear());
    else if (mounted) setState(() {});
  }

  Future<void> _scanBarcode() async {
    final scannedBarcode = await Navigator.push<String>(context, MaterialPageRoute(builder: (context) => const BarcodeScannerScreen()));
    if (scannedBarcode != null && mounted) {
      final productProvider = context.read<ProductProvider>();
      final product = productProvider.products.firstWhere(
        (p) => p.barcode == scannedBarcode,
        orElse: () => productProvider.products.first,
      );
      if (product.barcode == scannedBarcode) _addToCart(product);
      else ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Walang product na may barcode na ito')));
    }
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Row(children: [Icon(Icons.help_outline, color: Colors.blue), SizedBox(width: 8), Expanded(child: Text('Gabay sa Pagbebenta', style: TextStyle(fontWeight: FontWeight.bold)))]),
          content: SingleChildScrollView(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: 'Paano mag-benta gamit ang app?\n\n'),
                  TextSpan(text: '1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'I-tap ang produkto para idagdag sa cart.\n\n'),
                  TextSpan(text: '2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Gamitin ang Search Bar para mabilis na mahanap ang item.\n\n'),
                  TextSpan(text: '3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'I-tap ang cart button para pumunta sa Checkout.\n\n'),
                  TextSpan(text: 'Paalala: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  TextSpan(text: 'Hindi ka maaaring magdagdag ng produktong 0 stock.'),
                ],
              ),
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Naintindihan ko', style: TextStyle(fontWeight: FontWeight.bold)))],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Maghanap ng product...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
            prefixIcon: Icon(Icons.search, color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
        ),
        actions: [
          IconButton(onPressed: _scanBarcode, icon: const Icon(Icons.qr_code_scanner), tooltip: 'Scan Barcode'),
          IconButton(onPressed: () => setState(() => _searchQuery = ''), icon: const Icon(Icons.clear)),
          IconButton(
            onPressed: () {
              context.read<ProductProvider>().loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Na-refresh na ang products'), behavior: SnackBarBehavior.floating));
            },
            icon: const Icon(Icons.refresh),
          ),
          TextButton(onPressed: _showHelpDialog, child: const Text('Paano?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Theme.of(context).colorScheme.surface, Theme.of(context).colorScheme.surfaceContainerHighest],
          ),
        ),
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            if (productProvider.isLoading) return const Center(child: CircularProgressIndicator());

            final filteredProducts = productProvider.products
                .where((p) => p.name.toLowerCase().contains(_searchQuery))
                .toList()
              ..sort((a, b) {
                if (a.expirationDate != null && b.expirationDate == null) return -1;
                if (a.expirationDate == null && b.expirationDate != null) return 1;
                if (a.expirationDate != null && b.expirationDate != null) {
                  return DateTime.parse(a.expirationDate!).compareTo(DateTime.parse(b.expirationDate!));
                }
                return 0;
              });

            if (filteredProducts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(_searchQuery.isEmpty ? 'Wala pang products' : 'Walang nahanap', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  ],
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: _buildProductTile(product, index),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 400),
              builder: (context, value, child) => Transform.scale(scale: value, child: child),
              child: FloatingActionButton.extended(
                onPressed: _navigateToCheckout,
                icon: const Icon(Icons.shopping_cart),
                label: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$_itemCount items', style: const TextStyle(fontSize: 12)),
                    Text('₱${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: const Color(0xFFC4793A),
              ),
            ),
    );
  }

  Widget _buildProductTile(Product product, int index) {
    final inCart = _cart[product.id!] ?? 0;
    final isSelected = _selectedIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _selectedIndex = index),
      onExit: (_) => setState(() => _selectedIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        child: Card(
          elevation: isSelected ? 6 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => _addToCart(product),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 5,
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey[200],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: product.photoPath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.file(File(product.photoPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48)),
                            )
                          : const Icon(Icons.image, size: 48, color: Colors.grey),
                    ),
                  ),
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          if (product.hasDiscount) ...[
                            Text('₱${product.discountedPrice.toStringAsFixed(2)}', style: const TextStyle(fontSize: 13, color: Colors.red, fontWeight: FontWeight.bold)),
                            Text('₱${product.sellPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 10, color: Colors.grey[500], decoration: TextDecoration.lineThrough)),
                          ] else
                            Text('₱${product.sellPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                          Row(
                            children: [
                              Text('Stock: ${product.quantity}', style: TextStyle(fontSize: 11, color: product.isLowStock ? Colors.red : Colors.grey[600], fontWeight: product.isLowStock ? FontWeight.bold : FontWeight.normal)),
                              if (inCart > 0)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFF1A6B8A), borderRadius: BorderRadius.circular(10)),
                                  child: Text('$inCart', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                          if (product.isExpired)
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                              child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}