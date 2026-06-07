import '../widgets/animated_button.dart';
import '../models/product.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/sale_provider.dart';
import '../providers/customer_provider.dart';
import '../providers/utang_transaction_provider.dart';
import '../models/customer.dart';
import '../models/utang_transaction.dart';

class CheckoutScreen extends StatefulWidget {
  final Map<int, int> cart;

  const CheckoutScreen({super.key, required this.cart});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _cashController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isUtang = false;
  late AnimationController _animationController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() => setState(() {}));
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
      _animationController.forward();
    });
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
      if (product != null) {
        total += product.discountedPrice * quantity;
      }
    });
    return total;
  }

  double get _change {
    final cash = double.tryParse(_cashController.text) ?? 0;
    return cash - _total;
  }

  Future<void> _completeSale() async {
    if (widget.cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Wala pang items sa cart')),
      );
      return;
    }

    if (_isUtang && _selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pumili ng customer para sa utang')),
      );
      return;
    }

    final saleProvider = context.read<SaleProvider>();
    final utangProvider = context.read<UtangTransactionProvider>();
    final customerProvider = context.read<CustomerProvider>();
    bool allSuccess = true;

    final cashPaid = double.tryParse(_cashController.text) ?? 0;
    final changeGiven = _change;

    for (final entry in widget.cart.entries) {
      final product = context.read<ProductProvider>().getProductById(entry.key);
      if (product != null) {
        final success = await saleProvider.recordSale(
          entry.key,
          entry.value,
          product.sellPrice,
          amountPaid: _isUtang ? 0 : cashPaid,
          changeGiven: _isUtang ? 0 : changeGiven,
        );
        if (!success) allSuccess = false;
      }
    }

    if (_isUtang && _selectedCustomer != null && allSuccess) {
      final transaction = UtangTransaction(
        customerId: _selectedCustomer!.id!,
        amount: _total,
        type: 'credit',
        notes: 'Benta ng ${DateTime.now().toIso8601String()}',
        createdAt: DateTime.now().toIso8601String(),
      );
      await utangProvider.addUtangTransaction(transaction);
    }

    if (allSuccess && mounted) {
      context.read<ProductProvider>().loadProducts();
      if (_isUtang) await customerProvider.loadCustomers();
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isUtang ? 'Naitala na ang utang!' : 'Naitala na ang benta!')),
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
        title: const Text('Cart', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () => _showClearCartDialog(),
            tooltip: 'Burahin lahat',
          ),
        ],
      ),
      body: widget.cart.isEmpty
          ? _buildEmptyCart()
          : Column(
              children: [
                Expanded(child: _buildCartList()),
                _buildCheckoutPanel(),
              ],
            ),
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) => Transform.scale(
          scale: value,
          child: Opacity(opacity: value, child: child),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang items sa cart', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildCartList() {
    return ListView.builder(
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
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: InkWell(
              onTap: () => setState(() => _expandedIndex = _expandedIndex == index ? -1 : index),
              borderRadius: BorderRadius.circular(12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          child: Text('${entry.value}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('₱${product.sellPrice.toStringAsFixed(2)} each', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        Text('₱${(product.sellPrice * entry.value).toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline),
                          onPressed: () => _showRemoveQuantityDialog(product, entry.key, entry.value),
                        ),
                      ],
                    ),
                    if (_expandedIndex == index) ...[
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildInfoChip(Icons.receipt, 'Subtotal: ₱${(product.sellPrice * entry.value).toStringAsFixed(2)}'),
                          if (product.hasDiscount)
                            _buildInfoChip(Icons.local_offer, 'Discount: ${product.discountType == 'percentage' ? '${product.discountValue.toStringAsFixed(0)}%' : '₱${product.discountValue.toStringAsFixed(2)}'}'),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[700])),
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
              const Text('Kabuuan:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              TweenAnimationBuilder<double>(
                tween: Tween(begin: _total, end: _total),
                duration: const Duration(milliseconds: 300),
                builder: (context, value, child) => Text('₱${value.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFFC4793A))),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildUtangToggle(),
          if (_isUtang) _buildCustomerSelector(),
          if (!_isUtang) _buildPaymentFields(),
          const SizedBox(height: 16),
          AnimatedButton(
            onPressed: (_isUtang && _selectedCustomer == null) || (!_isUtang && _change < 0) ? null : _completeSale,
            label: _isUtang ? 'I-record ang Utang' : 'I-complete ang Benta',
            color: _isUtang ? const Color(0xFFC4793A) : const Color(0xFF1A6B8A),
          ),
        ],
      ),
    );
  }

  Widget _buildUtangToggle() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      child: SwitchListTile(
        title: const Text('Utang (Credit)', style: TextStyle(fontWeight: FontWeight.w500)),
        subtitle: const Text('I-record ang benta bilang utang'),
        value: _isUtang,
        onChanged: (value) => setState(() {
          _isUtang = value;
          if (!value) _selectedCustomer = null;
        }),
        activeColor: const Color(0xFFC4793A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildCustomerSelector() {
    return Consumer<CustomerProvider>(
      builder: (context, customerProvider, child) {
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: DropdownButtonFormField<Customer>(
            value: _selectedCustomer,
            decoration: InputDecoration(
              labelText: 'Pumili ng Customer',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              prefixIcon: const Icon(Icons.people),
            ),
            items: customerProvider.customers.map((customer) {
              return DropdownMenuItem(
                value: customer,
                child: Row(
                  children: [
                    Text(customer.name),
                    const SizedBox(width: 8),
                    Text('(₱${customer.currentBalance.toStringAsFixed(2)})',
                        style: TextStyle(fontSize: 12, color: customer.currentBalance > 0 ? Colors.orange : Colors.grey)),
                  ],
                ),
              );
            }).toList(),
            onChanged: (value) => setState(() => _selectedCustomer = value),
          ),
        );
      },
    );
  }

  Widget _buildPaymentFields() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      child: Row(
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
              controller: TextEditingController.fromValue(
                TextEditingValue(text: _change.toStringAsFixed(2)),
              ),
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
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context, false);
            },
            child: const Text('Burahin', style: TextStyle(color: Colors.red)),
          ),
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
        builder: (context, setDialogState) => _buildAnimatedDialog(
          title: 'Alisin ang ${product.name}',
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
                  IconButton(onPressed: quantityToRemove > 1 ? () => setDialogState(() => quantityToRemove--) : null, icon: const Icon(Icons.remove)),
                  Text('$quantityToRemove / $currentQuantity', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  IconButton(onPressed: quantityToRemove < currentQuantity ? () => setDialogState(() => quantityToRemove++) : null, icon: const Icon(Icons.add)),
                ],
              ),
            ],
          ),
          onConfirm: () {
            setState(() {
              if (quantityToRemove >= currentQuantity) widget.cart.remove(productId);
              else widget.cart[productId] = currentQuantity - quantityToRemove;
            });
            Navigator.pop(context);
          },
          confirmText: 'Alisin',
          confirmColor: Colors.red,
        ),
      ),
    );
  }

  Widget _buildAnimatedDialog({required String title, required Widget content, required VoidCallback onConfirm, String confirmText = 'Oo', Color confirmColor = Colors.red}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.elasticOut,
      builder: (context, value, child) => Transform.scale(scale: value, child: Opacity(opacity: value, child: child)),
      child: AlertDialog(
        title: Text(title),
        content: content,
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
          TextButton(onPressed: onConfirm, child: Text(confirmText, style: TextStyle(color: confirmColor))),
        ],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}

// Reusable animated button widget (same as in backup_restore_screen)
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final String label;
  final Color color;

  const AnimatedButton({super.key, this.onPressed, required this.label, required this.color});

  @override
  State<AnimatedButton> createState() => _AnimatedButtonState();
}

class _AnimatedButtonState extends State<AnimatedButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_isHovered && widget.onPressed != null ? 1.02 : 1.0),
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: widget.onPressed,
            style: ElevatedButton.styleFrom(
              backgroundColor: widget.color,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(widget.label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}