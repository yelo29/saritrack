import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/supplier_provider.dart';
import '../models/supplier.dart';
import 'supplier_form_screen.dart';
import '../widgets/animated_button.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _hoveredIndex = -1;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<SupplierProvider>().loadSuppliers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang suppliers'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.refresh),
            label: const Text('I-refresh'),
          ),
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
        child: Consumer<SupplierProvider>(
          builder: (context, supplierProvider, child) {
            if (supplierProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (supplierProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: ${supplierProvider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => supplierProvider.loadSuppliers(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (supplierProvider.suppliers.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => supplierProvider.loadSuppliers(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: supplierProvider.suppliers.length,
                itemBuilder: (context, index) {
                  final supplier = supplierProvider.suppliers[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset((1 - value) * 50, 0),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: _buildSupplierCard(supplier, supplierProvider, index),
                  );
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const SupplierFormScreen()),
            );
          },
          child: const Icon(Icons.add),
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
            Icon(Icons.local_shipping_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang suppliers', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mag-tap ng + para magdagdag ng supplier', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSupplierCard(Supplier supplier, SupplierProvider provider, int index) {
    final isExpanded = _expandedIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_hoveredIndex == index ? 1.01 : 1.0),
        child: Card(
          elevation: _hoveredIndex == index ? 4 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: InkWell(
            onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFC4793A), Color(0xFF4A2800)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          supplier.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              supplier.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (supplier.contact != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                supplier.contact!,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400], size: 18),
                    ],
                  ),
                  if (isExpanded) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    if (supplier.address != null && supplier.address!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              supplier.address!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (supplier.lastRestockDate != null) ...[
                      Row(
                        children: [
                          Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Text(
                            'Last restock: ${_formatDate(supplier.lastRestockDate!)}',
                            style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => SupplierFormScreen(supplier: supplier)),
                            );
                          },
                          icon: Icons.edit,
                          label: 'Edit',
                          color: const Color(0xFF1A6B8A),
                          isSmall: true,
                        ),
                        const SizedBox(width: 8),
                        AnimatedButton(
                          onPressed: () => _showDeleteDialog(supplier, provider),
                          icon: Icons.delete,
                          label: 'Burahin',
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
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.month}/${date.day}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  void _showDeleteDialog(Supplier supplier, SupplierProvider provider) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('Burahin ang Supplier'),
          content: Text('Sigurado ka bang gusto mong burahin ang ${supplier.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteSupplier(supplier.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nabura na ang supplier')),
                  );
                }
              },
              child: const Text('Burahin', style: TextStyle(color: Colors.red)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}