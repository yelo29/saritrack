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

class _CheckoutScreenState extends State<CheckoutScreen> {
  final TextEditingController _cashController = TextEditingController();
  Customer? _selectedCustomer;
  bool _isUtang = false;

  @override
  void initState() {
    super.initState();
    _cashController.addListener(() {
      setState(() {}); // Rebuild to update sukli calculation
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
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

    // Calculate total cash paid and change
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
        if (!success) {
          allSuccess = false;
        }
      }
    }

    // Create utang transaction if enabled
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
      // Refresh product list to update stock in Inventory tab
      context.read<ProductProvider>().loadProducts();
      // Refresh customer list to update balance
      if (_isUtang) {
        await customerProvider.loadCustomers();
      }
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
        title: const Text('Cart'),
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
                        Navigator.pop(context, false); // Return false to clear cart
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
                            backgroundColor: Theme.of(context).colorScheme.primary,
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
                      // Utang toggle
                      Consumer<CustomerProvider>(
                        builder: (context, customerProvider, child) {
                          return SwitchListTile(
                            title: const Text('Utang (Credit)'),
                            subtitle: const Text('I-record ang benta bilang utang'),
                            value: _isUtang,
                            onChanged: (value) {
                              setState(() {
                                _isUtang = value;
                                if (!value) {
                                  _selectedCustomer = null;
                                }
                              });
                            },
                          );
                        },
                      ),
                      // Customer selector (only shown when utang is enabled)
                      if (_isUtang)
                        Consumer<CustomerProvider>(
                          builder: (context, customerProvider, child) {
                            return DropdownButtonFormField<Customer>(
                              value: _selectedCustomer,
                              decoration: const InputDecoration(
                                labelText: 'Pumili ng Customer',
                                border: OutlineInputBorder(),
                              ),
                              items: customerProvider.customers.map((customer) {
                                return DropdownMenuItem<Customer>(
                                  value: customer,
                                  child: Row(
                                    children: [
                                      Text(customer.name),
                                      const SizedBox(width: 8),
                                      Text(
                                        '(₱${customer.currentBalance.toStringAsFixed(2)})',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: customer.currentBalance > 0 ? Colors.orange : Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCustomer = value;
                                });
                              },
                            );
                          },
                        ),
                      // Payment fields (only shown when utang is disabled)
                      if (!_isUtang) ...[
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
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_isUtang && _selectedCustomer == null) || (!_isUtang && _change < 0) ? null : _completeSale,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: _isUtang ? Colors.orange : null,
                          ),
                          child: Text(
                            _isUtang ? 'I-record ang Utang' : 'I-complete ang Benta',
                            style: const TextStyle(fontSize: 16),
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
