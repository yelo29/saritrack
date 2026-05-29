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

class _ResellScreenState extends State<ResellScreen> {
  final Map<int, int> _cart = {};
  final Map<int, List<Refund>> _refundReasons = {};
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  int get _itemCount => _cart.values.fold(0, (sum, qty) => sum + qty);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRefundReasons();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRefundReasons() async {
    final productProvider = context.read<ProductProvider>();
    final refundProvider = context.read<RefundProvider>();

    if (productProvider.products.isEmpty) {
      await productProvider.loadProducts();
    }

    for (final product in productProvider.products) {
      if (product.refundedStock > 0 && product.id != null) {
        final refunds = await refundProvider.getRefundsByProductId(product.id!);
        if (refunds.isNotEmpty) {
          setState(() {
            _refundReasons[product.id!] = refunds;
          });
        }
      }
    }
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

  void _addToCart(Product product) {
    if (product.id == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Product ID is null')),
      );
      return;
    }

    final currentInCart = _cart[product.id!] ?? 0;
    final maxQuantity = product.refundedStock - currentInCart;

    if (maxQuantity <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sobra na ang quantity sa refunded stock')),
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
              Text('Refunded Stock available: ${product.refundedStock}'),
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

  void _navigateToCheckout() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ResellCheckoutScreen(cart: _cart),
      ),
    ).then((result) {
      if (result == true && mounted) {
        setState(() {
          _cart.clear();
        });
      } else if (mounted) {
        setState(() {});
      }
    });
  }

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
                'Gabay sa Re-Sell',
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
                    const TextSpan(text: 'Paano gamitin ang Re-Sell Tab?\n\n'),
                    const TextSpan(text: '1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Ang screen na ito ay para lamang sa mga produktong may '),
                    const TextSpan(text: 'Refunded Stock (Ref)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const TextSpan(text: ' o mga sinauling aytem na maaari pang ibenta muli.\n\n'),
                    const TextSpan(text: '2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'I-tap ang card ng produkto para '),
                    const TextSpan(text: 'idagdag ito sa Re-Sell cart', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '. Hindi ka maaaring mag-add nang higit sa dami ng refunded stock nito.\n\n'),
                    const TextSpan(text: '3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'I-tap ang maliit na '),
                    const TextSpan(text: 'asul na info icon (i)', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: ' sa card upang makita ang detalye, halaga, at dahilan kung bakit ito binalik dati.\n\n'),
                    const TextSpan(text: '4. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Kung nais mong tuluyang burahin o bawasan ang refunded stock nang hindi ibinebenta, i-tap ang '),
                    const TextSpan(text: 'trash icon', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const TextSpan(text: ' sa kanang itaas ng card upang mamili kung ilang units ang aalisin.\n\n'),
                    const TextSpan(text: '5. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'I-tap ang '),
                    const TextSpan(text: 'Shopping Cart button', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const TextSpan(text: ' sa ibaba para pumunta sa Re-Sell Cart screen, ilagay ang bayad, at kumpletuhin ang muling pagbebenta.'),
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
              _loadRefundReasons();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang products')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
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

          final productsWithRefundedStock = productProvider.products
              .where((p) => p.refundedStock > 0 && p.name.toLowerCase().contains(_searchQuery))
              .toList();

          if (productsWithRefundedStock.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.refresh,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wala pang refunded stock',
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
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: productsWithRefundedStock.length,
            itemBuilder: (context, index) {
              final product = productsWithRefundedStock[index];
              return _buildProductCard(product);
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

  Widget _buildProductCard(Product product) {
    final inCart = _cart[product.id!] ?? 0;

    return Card(
      child: Stack(
        children: [
          InkWell(
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
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '₱${product.sellPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[700],
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Ref: ${product.refundedStock}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.orange[700],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_refundReasons[product.id] != null && _refundReasons[product.id]!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => _showRefundReasonsDialog(product),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 10,
                              color: Colors.blue.shade700,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              '${_refundReasons[product.id]!.length}',
                              style: TextStyle(
                                fontSize: 9,
                                color: Colors.blue.shade700,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  if (inCart > 0) ...[
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        'In Cart: $inCart',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: () => _showDeleteDialog(product),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ),
        ],
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselahin'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showRefundedStockPicker(product);
            },
            child: const Text('Burahin', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showRefundedStockPicker(Product product) {
    int quantityToRemove = 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Alisin ang Refunded Stock - ${product.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Max: ${product.refundedStock}'),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: quantityToRemove > 1
                        ? () => setDialogState(() => quantityToRemove--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    quantityToRemove.toString(),
                    style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: quantityToRemove < product.refundedStock
                        ? () => setDialogState(() => quantityToRemove++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setDialogState(() => quantityToRemove = product.refundedStock),
                child: const Text('Lahat', style: TextStyle(color: Colors.orange)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Kanselahin'),
            ),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await _processRefundedStockRemoval(product, quantityToRemove);
              },
              child: const Text('Alisin', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _processRefundedStockRemoval(Product product, int quantityToRemove) async {
    try {
      await context.read<ProductProvider>().deductRefundedStock(product.id!, quantityToRemove);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Naalis na ang $quantityToRemove unit(s) ng refunded stock')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showRefundReasonsDialog(Product product) {
    final refunds = _refundReasons[product.id] ?? [];
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
                      Text(
                        '₱${refund.amount.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        refund.reason,
                        style: const TextStyle(fontSize: 14),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(refund.refundedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Sarado'),
          ),
        ],
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

class ResellCheckoutScreen extends StatefulWidget {
  final Map<int, int> cart;

  const ResellCheckoutScreen({super.key, required this.cart});

  @override
  State<ResellCheckoutScreen> createState() => _ResellCheckoutScreenState();
}

class _ResellCheckoutScreenState extends State<ResellCheckoutScreen> {
  final TextEditingController _cashController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _cashController.dispose();
    super.dispose();
  }

  double get _total {
    final productProvider = context.read<ProductProvider>();
    double total = 0;
    widget.cart.forEach((productId, quantity) {
      final product = productProvider.getProductById(productId);
      if (product != null) {
        total += product.sellPrice * quantity;
      }
    });
    return total;
  }

  double get _change {
    final cash = double.tryParse(_cashController.text) ?? 0;
    return cash - _total;
  }

  Future<void> _completeResale() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wala pang items sa cart')),
      );
      return;
    }

    final saleProvider = context.read<SaleProvider>();
    bool allSuccess = true;

    final cashPaid = double.tryParse(_cashController.text) ?? 0;
    final changeGiven = _change;

    for (final entry in widget.cart.entries) {
      final product = context.read<ProductProvider>().getProductById(entry.key);
      if (product != null) {
        final success = await saleProvider.recordResale(
          entry.key,
          entry.value,
          product.sellPrice,
          amountPaid: cashPaid,
          changeGiven: changeGiven,
        );
        if (!success) allSuccess = false;
      }
    }

    if (allSuccess && mounted) {
      context.read<ProductProvider>().loadProducts();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Naitala na ang re-sale!')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('May mga items na hindi maibenta')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Re-Sell Cart'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Burahin lahat'),
                  content: const Text('Sigurado ka bang gusto mong burahin lahat ng items sa cart?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Kanselahin'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.pop(context, false);
                      },
                      child: const Text('Burahin', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
            },
            tooltip: 'Burahin lahat',
          ),
        ],
      ),
      body: widget.cart.isEmpty
          ? Center(
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
                    'Wala pang items sa cart',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: widget.cart.length,
                    itemBuilder: (context, index) {
                      final entry = widget.cart.entries.elementAt(index);
                      final product = context.read<ProductProvider>().getProductById(entry.key);
                      if (product == null) return const SizedBox.shrink();

                      return Card(
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text(
                              '${entry.value}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          title: Text(product.name),
                          subtitle: Text('₱${product.sellPrice.toStringAsFixed(2)} each'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '₱${(product.sellPrice * entry.value).toStringAsFixed(2)}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.remove_circle_outline),
                                onPressed: () {
                                  final currentQuantity = entry.value;
                                  int quantityToRemove = 1;

                                  showDialog(
                                    context: context,
                                    builder: (context) => StatefulBuilder(
                                      builder: (context, setDialogState) => AlertDialog(
                                        title: Text('Alisin ang ${product.name}'),
                                        content: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('In Cart: $currentQuantity'),
                                            const SizedBox(height: 16),
                                            const Text(
                                              'Ilang units ang aalisin?',
                                              style: TextStyle(fontWeight: FontWeight.bold),
                                            ),
                                            const SizedBox(height: 8),
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.center,
                                              children: [
                                                IconButton(
                                                  onPressed: quantityToRemove > 1
                                                      ? () => setDialogState(() => quantityToRemove--)
                                                      : null,
                                                  icon: const Icon(Icons.remove),
                                                ),
                                                Text(
                                                  '$quantityToRemove / $currentQuantity',
                                                  style: const TextStyle(
                                                    fontSize: 20,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                                IconButton(
                                                  onPressed: quantityToRemove < currentQuantity
                                                      ? () => setDialogState(() => quantityToRemove++)
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
                                                if (quantityToRemove >= currentQuantity) {
                                                  widget.cart.remove(entry.key);
                                                } else {
                                                  widget.cart[entry.key] = currentQuantity - quantityToRemove;
                                                }
                                              });
                                            },
                                            child: const Text('Alisin', style: TextStyle(color: Colors.red)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                                tooltip: 'Alisin',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.3),
                        spreadRadius: 1,
                        blurRadius: 5,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Kabuuan:',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '₱${_total.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
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
                              decoration: const InputDecoration(
                                labelText: 'Bayad (₱)',
                                border: OutlineInputBorder(),
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
                                border: const OutlineInputBorder(),
                                errorText: _change < 0 ? 'Kulang' : null,
                              ),
                              controller: TextEditingController.fromValue(
                                TextEditingValue(
                                  text: _change.toStringAsFixed(2),
                                  selection: TextSelection.collapsed(offset: _change.toStringAsFixed(2).length),
                                ),
                              ),
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
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.orange,
                          ),
                          child: const Text(
                            'I-complete ang Re-Sell',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}