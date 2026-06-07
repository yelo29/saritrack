import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/purchase_order_provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/purchase_order.dart';
import 'purchase_order_form_screen.dart';

class PurchaseOrderListScreen extends StatefulWidget {
  const PurchaseOrderListScreen({super.key});

  @override
  State<PurchaseOrderListScreen> createState() => _PurchaseOrderListScreenState();
}

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> with SingleTickerProviderStateMixin {
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().loadPurchaseOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  List<PurchaseOrder> _filterOrders(List<PurchaseOrder> orders) {
    var filtered = orders;
    if (_filterStatus != 'all') filtered = filtered.where((order) => order.status == _filterStatus).toList();
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final productProvider = context.read<ProductProvider>();
        final supplierProvider = context.read<SupplierProvider>();
        final product = productProvider.getProductById(order.productId);
        final supplier = order.supplierId != null
            ? supplierProvider.suppliers.firstWhere((s) => s.id == order.supplierId, orElse: () => supplierProvider.suppliers.first)
            : null;
        return (product?.name.toLowerCase().contains(_searchQuery) ?? false) || (supplier?.name.toLowerCase().contains(_searchQuery) ?? false);
      }).toList();
    }
    return filtered;
  }

  String _formatDate(String dateStr) {
    try {
      return DateFormat('MMM dd, yyyy').format(DateTime.parse(dateStr));
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'delivered': return Colors.green;
      case 'cancelled': return Colors.red;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(onPressed: () => setState(() => _searchQuery = ''), icon: const Icon(Icons.clear)),
          IconButton(
            onPressed: () => context.read<PurchaseOrderProvider>().loadPurchaseOrders(),
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
        child: Column(
          children: [
            _buildSearchAndFilter(),
            Expanded(
              child: Consumer3<PurchaseOrderProvider, ProductProvider, SupplierProvider>(
                builder: (context, orderProvider, productProvider, supplierProvider, child) {
                  if (orderProvider.isLoading) return const Center(child: CircularProgressIndicator());

                  if (orderProvider.purchaseOrders.isEmpty) return _buildEmptyState();

                  final filteredOrders = _filterOrders(orderProvider.purchaseOrders);
                  if (filteredOrders.isEmpty) return _buildNoResultsState();

                  return RefreshIndicator(
                    onRefresh: () => orderProvider.loadPurchaseOrders(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: filteredOrders.length,
                      itemBuilder: (context, index) {
                        final order = filteredOrders[index];
                        final product = productProvider.getProductById(order.productId);
                        final supplier = order.supplierId != null
                            ? supplierProvider.suppliers.firstWhere((s) => s.id == order.supplierId, orElse: () => supplierProvider.suppliers.first)
                            : null;
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          builder: (context, value, child) => Transform.translate(
                            offset: Offset((1 - value) * 50, 0),
                            child: Opacity(opacity: value, child: child),
                          ),
                          child: _buildOrderCard(order, product, supplier, orderProvider, index),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PurchaseOrderFormScreen())),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * -20),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
        ),
        child: Column(
          children: [
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Maghanap ng purchase order...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All', 'all'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Pending', 'pending'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Delivered', 'delivered'),
                  const SizedBox(width: 8),
                  _buildFilterChip('Cancelled', 'cancelled'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) => setState(() => _filterStatus = value),
      backgroundColor: Colors.grey[200],
      selectedColor: const Color(0xFF1A6B8A),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FadeTransition(
        opacity: _animationController,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang purchase orders', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mag-tap ng + para magdagdag', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text('Walang nahanap', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildOrderCard(PurchaseOrder order, product, supplier, PurchaseOrderProvider provider, int index) {
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
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
                        gradient: LinearGradient(
                          colors: order.status == 'pending'
                              ? [Colors.orange[400]!, Colors.orange[700]!]
                              : order.status == 'delivered'
                                  ? [Colors.green[400]!, Colors.green[700]!]
                                  : [Colors.red[400]!, Colors.red[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        order.status == 'pending' ? Icons.pending : (order.status == 'delivered' ? Icons.check_circle : Icons.cancel),
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(product?.name ?? 'Unknown Product', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          Text('₱${order.totalCost.toStringAsFixed(2)} • ${order.quantity} pcs', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400]),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  if (supplier != null) _buildDetailRow(Icons.local_shipping, 'Supplier:', supplier.name),
                  if (order.hasDeliveryDate) ...[
                    _buildDetailRow(Icons.calendar_today, 'Delivery:', _formatDate(order.deliveryDate!)),
                    if (order.isDeliveryOverdue)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('OVERDUE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                    if (order.isDeliveryApproaching && !order.isDeliveryOverdue)
                      Container(
                        margin: const EdgeInsets.only(top: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Colors.orange.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Text('ARRIVING SOON', style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold, fontSize: 11)),
                      ),
                  ],
                  if (order.notes != null && order.notes!.isNotEmpty) _buildDetailRow(Icons.description, 'Notes:', order.notes!),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (order.status != 'delivered' && order.status != 'cancelled')
                        _buildStatusButton(order, provider, 'Delivered', Colors.green),
                      if (order.status != 'delivered' && order.status != 'cancelled')
                        const SizedBox(width: 8),
                      if (order.status != 'cancelled')
                        _buildStatusButton(order, provider, 'Cancel', Colors.red),
                      const SizedBox(width: 8),
                      AnimatedButton(
                        onPressed: () => _showDeleteDialog(order, provider),
                        icon: Icons.delete,
                        label: 'Delete',
                        color: Colors.red,
                        isSmall: true,
                      ),
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

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 14, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          const SizedBox(width: 8),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }

  Widget _buildStatusButton(PurchaseOrder order, PurchaseOrderProvider provider, String status, Color color) {
    return AnimatedButton(
      onPressed: () async {
        if (status == 'Delivered') await provider.markAsDelivered(order.id!);
        else await provider.markAsCancelled(order.id!);
      },
      icon: status == 'Delivered' ? Icons.check : Icons.close,
      label: status,
      color: color,
      isSmall: true,
    );
  }

  void _showDeleteDialog(PurchaseOrder order, PurchaseOrderProvider provider) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('Delete Purchase Order'),
          content: const Text('Sigurado ka bang gusto mong burahin itong purchase order?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hindi')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await provider.deletePurchaseOrder(order.id!);
              },
              child: const Text('Oo', style: TextStyle(color: Colors.red)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// Reusable AnimatedButton (same as before)
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final bool isSmall;

  const AnimatedButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.isSmall = false,
  });

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
        transform: Matrix4.identity()..scale(_isHovered && widget.onPressed != null ? 1.05 : 1.0),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: Icon(widget.icon, size: widget.isSmall ? 16 : 20),
          label: Text(widget.label, style: TextStyle(fontSize: widget.isSmall ? 12 : 14)),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: Colors.white,
            padding: widget.isSmall ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8) : const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isSmall ? 20 : 12)),
          ),
        ),
      ),
    );
  }
}