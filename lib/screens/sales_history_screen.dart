import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/sale_provider.dart';
import '../providers/product_provider.dart';
import '../models/sale.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class SalesHistoryScreen extends StatefulWidget {
  const SalesHistoryScreen({super.key});

  @override
  State<SalesHistoryScreen> createState() => _SalesHistoryScreenState();
}

class _SalesHistoryScreenState extends State<SalesHistoryScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _startDate;
  DateTime? _endDate;
  late AnimationController _animationController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SaleProvider>().loadSales();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<Sale> _filterSales(List<Sale> sales, ProductProvider productProvider) {
    var filtered = sales;
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((sale) {
        final product = productProvider.getProductById(sale.productId);
        return product?.name.toLowerCase().contains(_searchQuery) ?? false;
      }).toList();
    }
    if (_startDate != null) {
      filtered = filtered.where((sale) => DateTime.parse(sale.createdAt).isAfter(_startDate!.subtract(const Duration(days: 1)))).toList();
    }
    if (_endDate != null) {
      filtered = filtered.where((sale) => DateTime.parse(sale.createdAt).isBefore(_endDate!.add(const Duration(days: 1)))).toList();
    }
    filtered.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales History', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
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
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (choice) async {
              final saleProvider = context.read<SaleProvider>();
              final productProvider = context.read<ProductProvider>();
              final filtered = _filterSales(saleProvider.sales, productProvider);
              final productNames = {for (var p in productProvider.products) p.id!: p.name};
              if (choice == 'csv') await ExportService.exportSalesToCSV(filtered, productNames);
              else if (choice == 'pdf') await ExportService.exportSalesToPDF(filtered, productNames);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart), SizedBox(width: 8), Text('Export as CSV')])),
              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Text('Export as PDF')])),
            ],
          ),
          IconButton(onPressed: () => setState(() => _searchQuery = ''), icon: const Icon(Icons.clear)),
          IconButton(onPressed: _selectDateRange, icon: const Icon(Icons.date_range), tooltip: 'Filter by date'),
          if (_startDate != null) IconButton(onPressed: _clearDateFilter, icon: const Icon(Icons.filter_alt_off)),
          IconButton(onPressed: () => context.read<SaleProvider>().loadSales(), icon: const Icon(Icons.refresh)),
        ],
      ),
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
        child: Consumer2<SaleProvider, ProductProvider>(
          builder: (context, saleProvider, productProvider, child) {
            if (saleProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (saleProvider.sales.isEmpty) {
              return _buildEmptyState();
            }

            final filteredSales = _filterSales(saleProvider.sales, productProvider);
            final totalSales = filteredSales.fold(0.0, (sum, s) => sum + s.total);
            final totalItems = filteredSales.fold(0, (sum, s) => sum + s.qtySold);

            return Column(
              children: [
                FadeTransition(
                  opacity: _animationController,
                  child: _buildSummaryCard(totalSales, totalItems, filteredSales.length),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => saleProvider.loadSales(),
                    child: filteredSales.isEmpty
                        ? Center(child: Text('Walang nahanap', style: TextStyle(color: Colors.grey[600])))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredSales.length,
                            itemBuilder: (context, index) {
                              final sale = filteredSales[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 30)),
                                builder: (context, value, child) => Transform.translate(
                                  offset: Offset((1 - value) * 50, 0),
                                  child: Opacity(opacity: value, child: child),
                                ),
                                child: _buildSaleCard(sale, productProvider, index),
                              );
                            },
                          ),
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
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang sales', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalSales, int totalItems, int transactionCount) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [const Color(0xFF1A6B8A), const Color(0xFF003547)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_startDate != null && _endDate != null)
            Text(
              '${DateFormat('MMM dd, yyyy').format(_startDate!)} - ${DateFormat('MMM dd, yyyy').format(_endDate!)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatColumn('₱${totalSales.toStringAsFixed(2)}', 'Total Sales'),
              _buildStatColumn('$totalItems', 'Items Sold'),
              _buildStatColumn('$transactionCount', 'Transactions'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: double.tryParse(value.replaceAll('₱', '')) ?? 0),
          duration: const Duration(milliseconds: 600),
          builder: (context, anim, child) {
            if (value.contains('₱')) return Text('₱${(anim).toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
            return Text('${anim.toInt()}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white));
          },
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.white70)),
      ],
    );
  }

  Widget _buildSaleCard(Sale sale, ProductProvider productProvider, int index) {
    final product = productProvider.getProductById(sale.productId);
    final isExpanded = _expandedIndex == index;
    final pricePerUnit = sale.total / sale.qtySold;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        child: Card(
          elevation: isExpanded ? 4 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: const Color(0xFF1A6B8A),
                      child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product?.name ?? 'Unknown',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatDate(sale.createdAt),
                            style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₱${sale.total.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D9D6E)),
                        ),
                        Text(
                          '${sale.qtySold} pc${sale.qtySold > 1 ? 's' : ''}',
                          style: TextStyle(fontSize: 10, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400], size: 18),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _buildDetailChip(Icons.receipt, '₱${pricePerUnit.toStringAsFixed(2)}/pc'),
                      if (sale.hasDiscount) _buildDetailChip(Icons.local_offer, sale.discountType == 'percentage' ? '${sale.discountValue.toStringAsFixed(0)}% off' : '₱${sale.discountValue.toStringAsFixed(2)} off'),
                      if (sale.vatAmount > 0) _buildDetailChip(Icons.account_balance, 'VAT: ₱${sale.vatAmount.toStringAsFixed(2)}'),
                      if (sale.amountPaid != null) _buildDetailChip(Icons.payment, 'Paid: ₱${sale.amountPaid!.toStringAsFixed(2)}'),
                      if (sale.changeGiven != null && sale.changeGiven! > 0) _buildDetailChip(Icons.money_off, 'Change: ₱${sale.changeGiven!.toStringAsFixed(2)}'),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey[600]),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(fontSize: 10, color: Colors.grey[700])),
        ],
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('MMM dd, hh:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  Future<void> _selectDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: Theme.of(context).colorScheme), child: child!),
    );
    if (picked != null) setState(() {
      _startDate = picked.start;
      _endDate = picked.end;
    });
  }

  void _clearDateFilter() => setState(() {
    _startDate = null;
    _endDate = null;
  });
}