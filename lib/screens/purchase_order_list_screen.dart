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

class _PurchaseOrderListScreenState extends State<PurchaseOrderListScreen> {
  String _filterStatus = 'all';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseOrderProvider>().loadPurchaseOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<PurchaseOrder> _filterOrders(List<PurchaseOrder> orders) {
    var filtered = orders;

    // Apply status filter
    if (_filterStatus != 'all') {
      filtered = filtered.where((order) => order.status == _filterStatus).toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((order) {
        final productProvider = context.read<ProductProvider>();
        final supplierProvider = context.read<SupplierProvider>();
        final product = productProvider.getProductById(order.productId);
        final supplier = order.supplierId != null 
            ? supplierProvider.suppliers.firstWhere(
                (s) => s.id == order.supplierId,
                orElse: () => supplierProvider.suppliers.first,
              )
            : null;
        
        final productName = product?.name.toLowerCase() ?? '';
        final supplierName = supplier?.name.toLowerCase() ?? '';
        return productName.contains(_searchQuery) || supplierName.contains(_searchQuery);
      }).toList();
    }

    return filtered;
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return DateFormat('MMM dd, yyyy').format(date);
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'delivered':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _showStatusDialog(PurchaseOrder order) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Change Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Pending'),
              onTap: () {
                Navigator.pop(context);
                context.read<PurchaseOrderProvider>().updatePurchaseOrder(
                  order.copyWith(status: 'pending'),
                );
              },
            ),
            ListTile(
              title: const Text('Delivered'),
              onTap: () {
                Navigator.pop(context);
                context.read<PurchaseOrderProvider>().markAsDelivered(order.id!);
              },
            ),
            ListTile(
              title: const Text('Cancelled'),
              onTap: () {
                Navigator.pop(context);
                context.read<PurchaseOrderProvider>().markAsCancelled(order.id!);
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase Orders'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              setState(() {
                _searchController.clear();
                _searchQuery = '';
              });
            },
            icon: const Icon(Icons.clear),
          ),
          IconButton(
            onPressed: () {
              context.read<PurchaseOrderProvider>().loadPurchaseOrders();
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filter Bar
          Container(
            padding: const EdgeInsets.all(8),
            color: Theme.of(context).colorScheme.primaryContainer,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Maghanap ng purchase order...',
                    prefixIcon: Icon(Icons.search),
                    border: OutlineInputBorder(),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value.toLowerCase();
                    });
                  },
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('All'),
                        selected: _filterStatus == 'all',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'all';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Pending'),
                        selected: _filterStatus == 'pending',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'pending';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Delivered'),
                        selected: _filterStatus == 'delivered',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'delivered';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      FilterChip(
                        label: const Text('Cancelled'),
                        selected: _filterStatus == 'cancelled',
                        onSelected: (selected) {
                          setState(() {
                            _filterStatus = 'cancelled';
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Orders List
          Expanded(
            child: Consumer3<PurchaseOrderProvider, ProductProvider, SupplierProvider>(
              builder: (context, orderProvider, productProvider, supplierProvider, child) {
                if (orderProvider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (orderProvider.purchaseOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inventory_2_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Wala pang purchase orders',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final filteredOrders = _filterOrders(orderProvider.purchaseOrders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Walang nahanap',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filteredOrders.length,
                  itemBuilder: (context, index) {
                    final order = filteredOrders[index];
                    final product = productProvider.getProductById(order.productId);
                    final supplier = order.supplierId != null 
                        ? supplierProvider.suppliers.firstWhere(
                            (s) => s.id == order.supplierId,
                            orElse: () => supplierProvider.suppliers.first,
                          )
                        : null;

                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getStatusColor(order.status),
                          child: Icon(
                            order.status == 'pending' 
                                ? Icons.pending 
                                : order.status == 'delivered' 
                                    ? Icons.check_circle 
                                    : Icons.cancel,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(
                          product?.name ?? 'Unknown Product',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Quantity: ${order.quantity} | Total: ₱${order.totalCost.toStringAsFixed(2)}'),
                            if (supplier != null)
                              Text('Supplier: ${supplier.name}'),
                            if (order.hasDeliveryDate)
                              Text(
                                'Delivery: ${_formatDate(order.deliveryDate!)}',
                                style: TextStyle(
                                  color: order.isDeliveryOverdue 
                                      ? Colors.red 
                                      : order.isDeliveryApproaching 
                                          ? Colors.orange 
                                          : Colors.grey[600],
                                  fontWeight: order.isDeliveryOverdue || order.isDeliveryApproaching 
                                      ? FontWeight.bold 
                                      : FontWeight.normal,
                                ),
                              ),
                            if (order.isDeliveryOverdue)
                              const Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            if (order.isDeliveryApproaching && !order.isDeliveryOverdue)
                              const Text(
                                'ARRIVING SOON',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            if (order.notes != null && order.notes!.isNotEmpty)
                              Text('Notes: ${order.notes}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              onPressed: () => _showStatusDialog(order),
                              icon: const Icon(Icons.edit),
                              tooltip: 'Change Status',
                            ),
                            IconButton(
                              onPressed: () async {
                                final confirmed = await showDialog<bool>(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: const Text('Delete Purchase Order'),
                                    content: const Text('Sigurado ka bang gusto mong burahin itong purchase order?'),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, false),
                                        child: const Text('Hindi'),
                                      ),
                                      TextButton(
                                        onPressed: () => Navigator.pop(context, true),
                                        child: const Text('Oo'),
                                      ),
                                    ],
                                  ),
                                );
                                if (confirmed == true) {
                                  await orderProvider.deletePurchaseOrder(order.id!);
                                }
                              },
                              icon: const Icon(Icons.delete),
                              tooltip: 'Delete',
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const PurchaseOrderFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
