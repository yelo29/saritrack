import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/refund_provider.dart';
import '../models/product.dart';
import '../models/refund.dart';

class ResellScreen extends StatefulWidget {
  const ResellScreen({super.key});

  @override
  State<ResellScreen> createState() => _ResellScreenState();
}

class _ResellScreenState extends State<ResellScreen> with SingleTickerProviderStateMixin {
  final Map<int, int> _cart = {};
  final Map<int, List<Refund>> _refundReasons = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  int _selectedIndex = -1;
  int _expandedIndex = -1;

  int get _itemCount => _cart.values.fold(0, (sum, qty) => sum + qty);
  double get _total {
    final productProvider = context.read<ProductProvider>();
    double total = 0;
    _cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) total += product.discountedPrice * quantity;
    });
    return total;
  }

  double get _totalVat {
    final productProvider = context.read<ProductProvider>();
    double totalVat = 0;
    _cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) totalVat += product.vatAmount * quantity;
    });
    return totalVat;
  }

  double get _totalWithVat {
    return _total + _totalVat;
  }

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadRefundReasons());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadRefundReasons() async {
    final productProvider = context.read<ProductProvider>();
    final refundProvider = context.read<RefundProvider>();

    if (productProvider.products.isEmpty) await productProvider.loadProducts();

    for (final product in productProvider.products) {
      if (product.refundedStock > 0 && product.id != null) {
        final refunds = await refundProvider.getRefundsByProductId(product.id!);
        if (refunds.isNotEmpty) setState(() => _refundReasons[product.id!] = refunds);
      }
    }
  }

  void _addToCart(Product product) {
    if (product.id == null) return;

    final currentInCart = _cart[product.id!] ?? 0;
    final maxQuantity = product.refundedStock - currentInCart;

    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sobra na ang quantity sa refunded stock'), behavior: SnackBarBehavior.floating),
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
                    color: const Color(0xFFC4793A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text('Refunded Stock: ${product.refundedStock}', style: const TextStyle(fontWeight: FontWeight.bold)),
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
                        color: const Color(0xFFC4793A).withOpacity(0.1),
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

  void _navigateToCheckout() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ResellCheckoutScreen(cart: _cart))).then((result) {
      if (result == true && mounted) setState(() => _cart.clear());
      else if (mounted) setState(() {});
    });
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
          title: const Row(children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(child: Text('Gabay sa Re-Sell', style: TextStyle(fontWeight: FontWeight.bold))),
          ]),
          content: SingleChildScrollView(
            child: RichText(
              text: const TextSpan(
                style: TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  TextSpan(text: 'Paano gamitin ang Re-Sell Tab?\n\n'),
                  TextSpan(text: '1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'Para lamang ito sa mga refunded stock.\n\n'),
                  TextSpan(text: '2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'I-tap ang card para idagdag sa cart.\n\n'),
                  TextSpan(text: '3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'I-tap ang info icon para makita ang refund reason.\n\n'),
                  TextSpan(text: '4. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  TextSpan(text: 'I-tap ang trash icon para magbawas ng refunded stock.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Naintindihan ko', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
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
          IconButton(onPressed: () => setState(() => _searchQuery = ''), icon: const Icon(Icons.clear)),
          IconButton(
            onPressed: () {
              context.read<ProductProvider>().loadProducts();
              _loadRefundReasons();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang products'), behavior: SnackBarBehavior.floating),
              );
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

            final productsWithRefundedStock = productProvider.products
                .where((p) => p.refundedStock > 0 && p.name.toLowerCase().contains(_searchQuery))
                .toList();

            if (productsWithRefundedStock.isEmpty) {
              return _buildEmptyState();
            }

            return GridView.builder(
              padding: const EdgeInsets.all(12),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: productsWithRefundedStock.length,
              itemBuilder: (context, index) {
                final product = productsWithRefundedStock[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 50)),
                  builder: (context, value, child) => Transform.scale(scale: value, child: child),
                  child: _buildProductCard(product, index),
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
                    Text('₱${_totalWithVat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                backgroundColor: const Color(0xFFC4793A),
              ),
            ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.refresh, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang refunded stock', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mag-refund mula sa History tab', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    final inCart = _cart[product.id!] ?? 0;
    final isSelected = _selectedIndex == index;
    final isExpanded = _expandedIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _selectedIndex = index),
      onExit: (_) => setState(() => _selectedIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(isSelected ? 1.02 : 1.0),
        child: Card(
          elevation: isSelected ? 6 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Stack(
            children: [
              InkWell(
                onTap: () => _addToCart(product),
                onLongPress: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
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
                              Text(product.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold), maxLines: 1, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 4),
                              Text('₱${product.sellPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 14, color: const Color(0xFFC4793A), fontWeight: FontWeight.bold)),
                              Text('Ref: ${product.refundedStock}', style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.bold)),
                              if (product.isExpired)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.red, borderRadius: BorderRadius.circular(10)),
                                  child: const Text('EXPIRED', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              if (product.isExpiringSoon && !product.isExpired)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(10)),
                                  child: const Text('EXPIRING SOON', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                              if (inCart > 0)
                                Container(
                                  margin: const EdgeInsets.only(top: 4),
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(color: const Color(0xFFC4793A), borderRadius: BorderRadius.circular(10)),
                                  child: Text('In Cart: $inCart', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Row(
                  children: [
                    if (_refundReasons[product.id] != null && _refundReasons[product.id]!.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: GestureDetector(
                          onTap: () => _showRefundReasonsDialog(product),
                          child: Row(
                            children: [
                              const Icon(Icons.info_outline, size: 10, color: Colors.white),
                              const SizedBox(width: 2),
                              Text('${_refundReasons[product.id]!.length}', style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                      onPressed: () => _showDeleteDialog(product),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              if (isExpanded && _refundReasons[product.id] != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.8),
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                    ),
                    child: Text(
                      '${_refundReasons[product.id]!.first.reason}',
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Alisin ang Refunded Stock'),
        content: Text('Ilang units ng refunded stock ang aalis sa ${product.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRefundedStockPicker(product);
            },
            child: const Text('Burahin', style: TextStyle(color: Colors.red)),
          ),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  void _showRefundedStockPicker(Product product) {
    int quantityToRemove = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: AlertDialog(
            title: Text('Alisin ang Refunded Stock - ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Text('Max: ${product.refundedStock}', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantityToRemove > 1 ? () => setDialogState(() => quantityToRemove--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('$quantityToRemove', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: quantityToRemove < product.refundedStock ? () => setDialogState(() => quantityToRemove++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                TextButton(onPressed: () => setDialogState(() => quantityToRemove = product.refundedStock), child: const Text('Lahat', style: TextStyle(color: Colors.red))),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<ProductProvider>().deductRefundedStock(product.id!, quantityToRemove);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Naalis na ang $quantityToRemove unit(s) ng refunded stock')),
                    );
                  }
                },
                child: const Text('Alisin', style: TextStyle(color: Colors.red)),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  void _showRefundReasonsDialog(Product product) {
    final refunds = _refundReasons[product.id] ?? [];
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: Text('Refund Reasons - ${product.name}'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: refunds.length,
              itemBuilder: (context, index) {
                final refund = refunds[index];
                return Card(
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('₱${refund.amount.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC4793A))),
                        const SizedBox(height: 4),
                        Text(refund.reason, style: const TextStyle(fontSize: 14)),
                        const SizedBox(height: 4),
                        Text(_formatDate(refund.refundedAt), style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Sarado')),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateStr;
    }
  }
}

// ResellCheckoutScreen (simplified version)
class ResellCheckoutScreen extends StatefulWidget {
  final Map<int, int> cart;
  const ResellCheckoutScreen({super.key, required this.cart});

  @override
  State<ResellCheckoutScreen> createState() => _ResellCheckoutScreenState();
}

class _ResellCheckoutScreenState extends State<ResellCheckoutScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cashController = TextEditingController();
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() => setState(() {}));
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
  }

  @override
  void dispose() {
    _cashController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  double get _total {
    final productProvider = context.read<ProductProvider>();
    double total = 0;
    widget.cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) total += product.discountedPrice * quantity;
    });
    return total;
  }

  double get _totalVat {
    final productProvider = context.read<ProductProvider>();
    double totalVat = 0;
    widget.cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) totalVat += product.vatAmount * quantity;
    });
    return totalVat;
  }

  double get _totalWithVat {
    return _total + _totalVat;
  }

  double get _change => (double.tryParse(_cashController.text) ?? 0) - _totalWithVat;

  Future<void> _completeResale() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Wala pang items sa cart')));
      return;
    }

    final saleProvider = context.read<SaleProvider>();
    final cashPaid = double.tryParse(_cashController.text) ?? 0;
    final changeGiven = _change;
    bool allSuccess = true;

    for (final entry in widget.cart.entries) {
      final product = context.read<ProductProvider>().getProductById(entry.key);
      if (product != null) {
        final success = await saleProvider.recordResale(entry.key, entry.value, product.sellPrice, amountPaid: cashPaid, changeGiven: changeGiven);
        if (!success) allSuccess = false;
      }
    }

    if (allSuccess && mounted) {
      context.read<ProductProvider>().loadProducts();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Naitala na ang re-sale!')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Re-Sell Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearCartDialog(),
          ),
        ],
      ),
      body: widget.cart.isEmpty
          ? Center(
              child: FadeTransition(
                opacity: _animationController,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('Wala pang items sa cart', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
                  ],
                ),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final entry = widget.cart.entries.elementAt(index);
                      final product = context.read<ProductProvider>().getProductById(entry.key);
                      if (product == null) return const SizedBox.shrink();
                      return TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0.0, end: 1.0),
                        duration: Duration(milliseconds: 300 + (index * 50)),
                        builder: (context, value, child) => Transform.translate(
                          offset: Offset((1 - value) * 50, 0),
                          child: Opacity(opacity: value, child: child),
                        ),
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            leading: CircleAvatar(backgroundColor: const Color(0xFFC4793A), child: Text('${entry.value}')),
                            title: Text(product.name),
                            subtitle: Text('₱${product.discountedPrice.toStringAsFixed(2)} each'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('₱${(product.discountedPrice * entry.value).toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () => _showRemoveQuantityDialog(product, entry.key, entry.value),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                _buildCheckoutPanel(),
              ],
            ),
    );
  }

  Widget _buildCheckoutPanel() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, -5))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Subtotal:', style: TextStyle(fontSize: 14)),
              Text('₱${_total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
            ],
          ),
          if (_totalVat > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('VAT:', style: TextStyle(fontSize: 14)),
                Text('₱${_totalVat.toStringAsFixed(2)}', style: const TextStyle(fontSize: 14)),
              ],
            ),
          ],
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kabuuan:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: _totalWithVat),
                duration: const Duration(milliseconds: 600),
                builder: (context, value, child) => Text('₱${value.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC4793A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _cashController,
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Bayad (₱)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.money),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              SizedBox(
                width: 100,
                child: TextField(
                  enabled: false,
                  decoration: InputDecoration(
                    labelText: 'Sukli',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    errorText: _change < 0 ? 'Kulang' : null,
                  ),
                  controller: TextEditingController.fromValue(TextEditingValue(text: _change.toStringAsFixed(2))),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _change < 0 ? null : _completeResale,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFC4793A),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('I-complete ang Re-Sell', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  void _showClearCartDialog() {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('Burahin lahat'),
          content: const Text('Sigurado ka bang gusto mong burahin lahat ng items sa cart?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Burahin', style: TextStyle(color: Colors.red))),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showRemoveQuantityDialog(Product product, int productId, int currentQuantity) {
    int quantityToRemove = 1;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: AlertDialog(
            title: Text('Alisin ang ${product.name}'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('In Cart: $currentQuantity'),
                const SizedBox(height: 16),
                const Text('Ilang units ang aalisin?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: quantityToRemove > 1 ? () => setDialogState(() => quantityToRemove--) : null,
                      icon: const Icon(Icons.remove),
                    ),
                    Text('$quantityToRemove', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      onPressed: quantityToRemove < currentQuantity ? () => setDialogState(() => quantityToRemove++) : null,
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
              TextButton(
                onPressed: () {
                  setState(() {
                    if (quantityToRemove >= currentQuantity) widget.cart.remove(productId);
                    else widget.cart[productId] = currentQuantity - quantityToRemove;
                  });
                  Navigator.pop(context);
                },
                child: const Text('Alisin', style: TextStyle(color: Colors.red)),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}