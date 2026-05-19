import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../providers/refund_provider.dart';
import '../providers/product_provider.dart';
import '../models/sale.dart';

class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'luma', 'bago', 'quantity'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
      context.read<RefundProvider>().loadRefunds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('History'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Maghanap ng sale...',
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
          ),
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
              context.read<SaleProvider>().loadSales();
              context.read<RefundProvider>().loadRefunds();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer2<SaleProvider, RefundProvider>(
        builder: (context, saleProvider, refundProvider, child) {
          if (saleProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (saleProvider.sales.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wala pang sales',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            );
          }

          final filteredSales = saleProvider.sales.where((sale) {
            final product = context.read<ProductProvider>().getProductById(sale.productId);
            final matchesSearch = product?.name.toLowerCase().contains(_searchQuery) ?? false;
            final matchesFilter = _filterType == 'all' ||
                (_filterType == 'luma' && _isOldSale(sale.createdAt)) ||
                (_filterType == 'bago' && !_isOldSale(sale.createdAt)) ||
                (_filterType == 'quantity');
            return matchesSearch && matchesFilter;
          }).toList();

          if (_filterType == 'quantity') {
            filteredSales.sort((a, b) => b.qtySold.compareTo(a.qtySold));
          }

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Lahat'),
                        selected: _filterType == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _filterType = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Luma'),
                        selected: _filterType == 'luma',
                        onSelected: (selected) {
                          setState(() {
                            _filterType = 'luma';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Bago'),
                        selected: _filterType == 'bago',
                        onSelected: (selected) {
                          setState(() {
                            _filterType = 'bago';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Quantity'),
                        selected: _filterType == 'quantity',
                        onSelected: (selected) {
                          setState(() {
                            _filterType = 'quantity';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: filteredSales.isEmpty
                    ? Center(
                        child: Text(
                          _searchQuery.isEmpty && _filterType == 'all'
                              ? 'Wala pang sales'
                              : 'Walang nahanap',
                        ),
                      )
                    : ListView.builder(
                        itemCount: filteredSales.length,
                        itemBuilder: (context, index) {
                          final sale = filteredSales[index];
                          final totalRefunded = refundProvider.getTotalRefundedQuantity(sale.id!);
                          final isFullyRefunded = totalRefunded >= sale.qtySold;
                          return _buildSaleCard(sale, totalRefunded, isFullyRefunded, saleProvider, refundProvider);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSaleCard(
    Sale sale,
    int totalRefunded,
    bool isFullyRefunded,
    SaleProvider saleProvider,
    RefundProvider refundProvider,
  ) {
    final product = context.read<ProductProvider>().getProductById(sale.productId);
    final remainingQuantity = sale.qtySold - totalRefunded;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    product?.name ?? 'Unknown Product',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '₱${sale.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Quantity: ${sale.qtySold} | Refunded: $totalRefunded',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
            Text(
              'Date: ${_formatDate(sale.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            if (sale.amountPaid != null && sale.changeGiven != null) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    'Bayad: ₱${sale.amountPaid!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sukli: ₱${sale.changeGiven!.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.green[700],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                if (isFullyRefunded) ...[
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text(
                        'Na-refund na',
                        style: TextStyle(
                          color: Colors.red,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ] else ...[
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showRefundDialog(sale, saleProvider, remainingQuantity),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      child: const Text('I-refund'),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final hour = date.hour;
      final minute = date.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '${date.month}/${date.day}/${date.year} $displayHour:$minute $period';
    } catch (e) {
      return dateStr;
    }
  }

  bool _isOldSale(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final difference = now.difference(date);
      return difference.inDays > 7;
    } catch (e) {
      return false;
    }
  }

  void _showRefundDialog(Sale sale, SaleProvider saleProvider, int remainingQuantity) {
    final reasonController = TextEditingController();
    int refundQuantity = remainingQuantity; // Default to remaining quantity

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('I-refund ang Sale'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Total Amount: ₱${sale.total.toStringAsFixed(2)}'),
              Text('Quantity Sold: ${sale.qtySold}'),
              Text('Remaining to refund: $remainingQuantity'),
              const SizedBox(height: 16),
              const Text(
                'Ilang units ang ire-refund?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    onPressed: refundQuantity > 1
                        ? () => setDialogState(() => refundQuantity--)
                        : null,
                    icon: const Icon(Icons.remove),
                  ),
                  Text(
                    '$refundQuantity / $remainingQuantity',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: refundQuantity < remainingQuantity
                        ? () => setDialogState(() => refundQuantity++)
                        : null,
                    icon: const Icon(Icons.add),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setDialogState(() => refundQuantity = remainingQuantity),
                child: const Text('Lahat', style: TextStyle(color: Colors.orange)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                decoration: const InputDecoration(
                  labelText: 'Reason (e.g., Defective product)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
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
                if (reasonController.text.trim().isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Paki-ilagay ang reason')),
                  );
                  return;
                }

                final success = await saleProvider.processRefund(
                  sale.id!,
                  reasonController.text.trim(),
                  refundQuantity,
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Na-refund na ang sale')),
                  );
                  context.read<RefundProvider>().loadRefunds();
                  context.read<ProductProvider>().loadProducts();
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: ${saleProvider.error}')),
                  );
                }
              },
              child: const Text('I-refund', style: TextStyle(color: Colors.orange)),
            ),
          ],
        ),
      ),
    );
  }
}
