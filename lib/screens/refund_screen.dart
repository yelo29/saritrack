import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../providers/refund_provider.dart';
import '../providers/product_provider.dart';
import '../models/sale.dart';
import '../widgets/animated_button.dart';

class RefundScreen extends StatefulWidget {
  const RefundScreen({super.key});

  @override
  State<RefundScreen> createState() => _RefundScreenState();
}

class _RefundScreenState extends State<RefundScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';
  late AnimationController _animationController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
      context.read<RefundProvider>().loadRefunds();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: const Text('History', style: TextStyle(fontWeight: FontWeight.bold)),
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
                prefixIcon: Icon(Icons.search, color: Colors.white70),
              ),
              style: const TextStyle(color: Colors.white),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
        ),
        actions: [
          IconButton(onPressed: () => setState(() => _searchQuery = ''), icon: const Icon(Icons.clear)),
          IconButton(
            onPressed: () {
              context.read<SaleProvider>().loadSales();
              context.read<RefundProvider>().loadRefunds();
            },
            icon: const Icon(Icons.refresh),
          ),
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
        child: Consumer2<SaleProvider, RefundProvider>(
          builder: (context, saleProvider, refundProvider, child) {
            if (saleProvider.isLoading) return const Center(child: CircularProgressIndicator());

            if (saleProvider.sales.isEmpty) {
              return _buildEmptyState();
            }

            final filteredSales = saleProvider.sales.where((sale) {
              final product = context.read<ProductProvider>().getProductById(sale.productId);
              final matchesSearch = product?.name.toLowerCase().contains(_searchQuery) ?? false;
              final matchesFilter = _filterType == 'all' ||
                  (_filterType == 'luma' && _isOldSale(sale.createdAt)) ||
                  (_filterType == 'bago' && !_isOldSale(sale.createdAt));
              return matchesSearch && matchesFilter;
            }).toList();

            if (_filterType == 'quantity') filteredSales.sort((a, b) => b.qtySold.compareTo(a.qtySold));

            return Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: filteredSales.isEmpty
                      ? Center(child: Text('Walang nahanap', style: TextStyle(color: Colors.grey[600])))
                      : ListView.builder(
                          padding: const EdgeInsets.all(12),
                          itemCount: filteredSales.length,
                          itemBuilder: (context, index) {
                            final sale = filteredSales[index];
                            final totalRefunded = refundProvider.getTotalRefundedQuantity(sale.id!);
                            final isFullyRefunded = totalRefunded >= sale.qtySold;
                            return TweenAnimationBuilder<double>(
                              tween: Tween(begin: 0.0, end: 1.0),
                              duration: Duration(milliseconds: 300 + (index * 50)),
                              builder: (context, value, child) => Transform.translate(
                                offset: Offset((1 - value) * 50, 0),
                                child: Opacity(opacity: value, child: child),
                              ),
                              child: _buildSaleCard(sale, totalRefunded, isFullyRefunded, saleProvider, refundProvider, index),
                            );
                          },
                        ),
                ),
              ],
            );
          },
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
            Icon(Icons.history, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang sales', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * -20),
        child: Opacity(opacity: value, child: child),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildFilterChip('Lahat', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Luma (>7 days)', 'luma'),
            const SizedBox(width: 8),
            _buildFilterChip('Bago', 'bago'),
            const SizedBox(width: 8),
            _buildFilterChip('Pinakamarami', 'quantity'),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterType == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterType = value),
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFFC4793A),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
    );
  }

  Widget _buildSaleCard(Sale sale, int totalRefunded, bool isFullyRefunded, SaleProvider saleProvider, RefundProvider refundProvider, int index) {
    final product = context.read<ProductProvider>().getProductById(sale.productId);
    final remainingQuantity = sale.qtySold - totalRefunded;
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: isExpanded ? 4 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: isFullyRefunded
                            ? LinearGradient(colors: [Colors.red[400]!, Colors.red[700]!])
                            : const LinearGradient(colors: [Color(0xFF2D9D6E), Color(0xFF002117)]),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(isFullyRefunded ? Icons.check_circle : Icons.shopping_cart, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product?.name ?? 'Unknown', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('${sale.qtySold} pcs • ${_formatDate(sale.createdAt)}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('₱${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D9D6E))),
                        if (totalRefunded > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                            child: Text('Refunded: $totalRefunded', style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.bold)),
                          ),
                      ],
                    ),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400]),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  if (sale.hasDiscount)
                    _buildDetailRow(Icons.local_offer, 'Discount:', '${sale.discountType == 'percentage' ? '${sale.discountValue.toStringAsFixed(0)}%' : '₱${sale.discountValue.toStringAsFixed(2)}'} (Original: ₱${sale.originalPrice.toStringAsFixed(2)})'),
                  if (sale.amountPaid != null && sale.changeGiven != null) ...[
                    _buildDetailRow(Icons.payment, 'Bayad:', '₱${sale.amountPaid!.toStringAsFixed(2)}'),
                    _buildDetailRow(Icons.money_off, 'Sukli:', '₱${sale.changeGiven!.toStringAsFixed(2)}'),
                  ],
                  _buildDetailRow(Icons.inventory, 'Remaining:', '$remainingQuantity units'),
                  const SizedBox(height: 12),
                  if (!isFullyRefunded)
                    AnimatedButton(
                      onPressed: () => _showRefundDialog(sale, saleProvider, remainingQuantity),
                      icon: Icons.refresh,
                      label: 'I-refund',
                      color: const Color(0xFFC4793A),
                      isSmall: true,
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: const Center(child: Text('FULLY REFUNDED', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
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
      return DateTime.now().difference(DateTime.parse(dateStr)).inDays > 7;
    } catch (e) {
      return false;
    }
  }

  void _showRefundDialog(Sale sale, SaleProvider saleProvider, int remainingQuantity) {
    final reasonController = TextEditingController();
    int refundQuantity = remainingQuantity;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          builder: (context, value, child) => Transform.scale(scale: value, child: child),
          child: AlertDialog(
            title: const Text('I-refund ang Sale'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    children: [
                      Text('Total Amount: ₱${sale.total.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Remaining to refund: $remainingQuantity units', style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                const Text('Ilang units ang ire-refund?', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: refundQuantity > 1 ? () => setDialogState(() => refundQuantity--) : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                      child: Text('$refundQuantity', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    ),
                    IconButton(
                      onPressed: refundQuantity < remainingQuantity ? () => setDialogState(() => refundQuantity++) : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),
                TextButton(onPressed: () => setDialogState(() => refundQuantity = remainingQuantity), child: const Text('Lahat', style: TextStyle(color: Colors.orange))),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(labelText: 'Reason (e.g., Defective product)', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
              ElevatedButton(
                onPressed: () async {
                  if (reasonController.text.trim().isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Paki-ilagay ang reason')));
                    return;
                  }
                  final success = await saleProvider.processRefund(sale.id!, reasonController.text.trim(), refundQuantity);
                  if (success && mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Na-refund na ang sale')));
                    context.read<RefundProvider>().loadRefunds();
                    context.read<ProductProvider>().loadProducts();
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC4793A)),
                child: const Text('I-refund'),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }
}