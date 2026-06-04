import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../models/product.dart';
import 'checkout_screen.dart';

class QuickSaleScreen extends StatefulWidget {
  const QuickSaleScreen({super.key});

  @override
  State<QuickSaleScreen> createState() => _QuickSaleScreenState();
}

class _QuickSaleScreenState extends State<QuickSaleScreen> {
  final Map<int, int> _cart = {}; // productId -> quantity
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  double get _total {
    final productProvider = context.read<ProductProvider>();
    double total = 0;
    _cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) {
        total += product.sellPrice * quantity;
      }
    });
    return total;
  }

  int get _itemCount {
    return _cart.values.fold(0, (sum, quantity) => sum + quantity);
  }

  void _addToCart(Product product) {
    final currentInCart = _cart[product.id!] ?? 0;
    final maxQuantity = product.quantity - currentInCart;

    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${product.name} - wala nang stock')),
      );
      return;
    }

    int quantityToAdd = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Magdagdag ng ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Stock available: ${product.quantity}'),
              Text('In Cart: $currentInCart'),
              const SizedBox(height: 16),
              const Text(
                'Ilang units ang idadagdag?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantityToAdd > 1
                        ? () => setDialogState(() => quantityToAdd--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$quantityToAdd / $maxQuantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: quantityToAdd < maxQuantity
                        ? () => setDialogState(() => quantityToAdd++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselahin'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() {
                  _cart[product.id!] = currentInCart + quantityToAdd;
                });
              },
              child: const Text('Idagdag', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _navigateToCheckout() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CheckoutScreen(cart: _cart),
      ),
    );

    if (result == true && mounted) {
      // Sale completed - clear the cart
      setState(() {
        _cart.clear();
      });
    } else if (mounted) {
      // User cancelled or went back - just rebuild to show updated cart state
      setState(() {});
    }
  }

  // Tutorial Dialog para sa Sell Tab
  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.help_outline, color: Colors.blue),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Gabay sa Pagbebenta',
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
                    const TextSpan(text: 'Paano mag-benta gamit ang app?\n\n'),
                    const TextSpan(text: '1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'I-tap ang larawan o kahon ng produkto upang '),
                    const TextSpan(text: 'isama ito sa cart', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '. Mapapansin mo ang '),
                    const TextSpan(text: 'In Cart', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: ' indicator na nagpapakita kung ilan ang balak bilhin.\n\n'),
                    const TextSpan(text: '2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Maaari mo ring gamitin ang '),
                    const TextSpan(text: 'Search Bar', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' sa itaas upang mabilis na mahanap ang item na gustong bilhin ng customer.\n\n'),
                    const TextSpan(text: '3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Kapag may laman na ang iyong cart, lilitaw ang '),
                    const TextSpan(text: 'Shopping Cart button', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: ' sa ibabang kanang bahagi. Ipinapakita nito ang kabuuang dami ng items at kabuuang halaga (₱).\n\n'),
                    const TextSpan(text: '4. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'I-tap ang cart button na iyon upang tumuloy sa '),
                    const TextSpan(text: 'Checkout Screen', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' para makumpleto at ma-save ang transaksyon.\n\n'),
                    const TextSpan(text: 'Paalala sa Stock: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const TextSpan(text: 'Hindi ka maaaring magdagdag sa cart ng produktong may '),
                    const TextSpan(text: '0 stock o wala nang natitira', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '. Siguraduhing may sapat na stock muna sa Imbentaryo.'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Maghanap ng product...',
            hintStyle: TextStyle(color: Colors.white70),
            border: InputBorder.none,
          ),
          style: const TextStyle(color: Colors.white),
          onChanged: (value) {
            setState(() {
              _searchQuery = value.toLowerCase();
            });
          },
        ),
        actions: [
          IconButton(
            onPressed: () {
              _searchController.clear();
              setState(() {
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear),
          ),
          IconButton(
            onPressed: () {
              context.read<ProductProvider>().loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang products')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
          // Idinagdag na "Paano?" Button
          TextButton(
            onPressed: _showHelpDialog,
            child: const Text(
              'Paano?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Consumer<ProductProvider>(
        builder: (context, productProvider, child) {
          if (productProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final filteredProducts = productProvider.products
              .where((p) => p.name.toLowerCase().contains(_searchQuery))
              .toList()
            ..sort((a, b) {
              // Products with expiration dates come first
              if (a.expirationDate != null && b.expirationDate == null) {
                return -1;
              }
              if (a.expirationDate == null && b.expirationDate != null) {
                return 1;
              }
              if (a.expirationDate != null && b.expirationDate != null) {
                // Sort by expiration date (soonest first)
                return DateTime.parse(a.expirationDate!).compareTo(DateTime.parse(b.expirationDate!));
              }
              return 0;
            });

          if (filteredProducts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _searchQuery.isEmpty ? 'Wala pang products' : 'Walang nahanap',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          return GridView.builder(
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: filteredProducts.length,
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildProductTile(product);
            },
          );
        },
      ),
      floatingActionButton: _cart.isEmpty
          ? null
          : FloatingActionButton.extended(
              onPressed: _navigateToCheckout,
              icon: const Icon(Icons.shopping_cart),
              label: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('$_itemCount items'),
                  Text('₱${_total.toStringAsFixed(2)}'),
                ],
              ),
            ),
    );
  }

  Widget _buildProductTile(Product product) {
    final inCart = _cart[product.id!] ?? 0;

    return Card(
      child: InkWell(
        onTap: () => _addToCart(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 5,
                child: Container(
                  width: double.infinity,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: product.photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(product.photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(Icons.image, size: 48);
                            },
                          ),
                        )
                      : const Icon(Icons.image, size: 48, color: Colors.grey),
                ),
              ),
              Expanded(
                flex: 3,
                child: Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '₱${product.sellPrice.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[700],
                        ),
                      ),
                      Text(
                        'Stock: ${product.quantity}',
                        style: TextStyle(
                          fontSize: 12,
                          color: product.quantity <= product.reorderLevel
                              ? Colors.red
                              : Colors.grey[600],
                          fontWeight: product.quantity <= product.reorderLevel
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      if (product.isExpired)
                        const SizedBox(height: 4),
                      if (product.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'EXPIRED',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (product.isExpiringSoon && !product.isExpired)
                        const SizedBox(height: 4),
                      if (product.isExpiringSoon && !product.isExpired)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Colors.orange,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'EXPIRING SOON',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (inCart > 0)
                        const SizedBox(height: 4),
                      if (inCart > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            'In Cart: $inCart',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}