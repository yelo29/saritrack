import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/product.dart';
import 'product_form_screen.dart';
import '../services/export_service.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all';
  late AnimationController _animationController;
  int _expandedIndex = -1;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _showHelpDialog() {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.help_outline, color: Colors.blue),
              SizedBox(width: 8),
              Expanded(child: Text('Gabay sa Imbentaryo', style: TextStyle(fontWeight: FontWeight.bold))),
            ],
          ),
          content: SingleChildScrollView(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.4),
                children: [
                  const TextSpan(text: 'Maligayang pagdating sa iyong '),
                  const TextSpan(text: 'Imbentaryo!\n\n', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: '1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'Para magdagdag ng bagong produkto, i-tap ang '),
                  const TextSpan(text: 'plus (+) button', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                  const TextSpan(text: ' sa ibabang kanang bahagi.\n\n'),
                  const TextSpan(text: '2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'Gamitin ang Search Bar para mabilis na mahanap ang produkto.\n\n'),
                  const TextSpan(text: '3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                  const TextSpan(text: 'I-tap ang card para i-edit ang produkto.\n\n'),
                  TextSpan(
                    text: 'Paalala: ',
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800]),
                  ),
                  const TextSpan(text: 'Ang lahat ng datos ay ligtas na nakatago sa iyong device lamang.'),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Naintindihan ko', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        title: TextField(
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
        actions: [
          PopupMenuButton<String>(
            onSelected: (choice) async {
              final productProvider = context.read<ProductProvider>();
              if (choice == 'csv') await ExportService.exportProductsToCSV(productProvider.products);
              else if (choice == 'pdf') await ExportService.exportProductsToPDF(productProvider.products);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart), SizedBox(width: 8), Text('Export as CSV')])),
              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Text('Export as PDF')])),
            ],
          ),
          IconButton(onPressed: () => setState(() => _searchQuery = ''), icon: const Icon(Icons.clear)),
          IconButton(
            onPressed: () {
              context.read<ProductProvider>().loadProducts();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang imbentaryo'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
          TextButton(
            onPressed: _showHelpDialog,
            child: const Text('Paano?', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        child: Consumer2<ProductProvider, SupplierProvider>(
          builder: (context, productProvider, supplierProvider, child) {
            if (productProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (productProvider.error != null) {
              return _buildErrorState(productProvider);
            }

            if (productProvider.products.isEmpty) {
              return _buildEmptyState();
            }

            final filteredProducts = productProvider.products.where((p) {
              final matchesSearch = p.name.toLowerCase().contains(_searchQuery);
              final matchesFilter = _filterType == 'all' ||
                  (_filterType == 'low_stock' && p.quantity <= p.reorderLevel) ||
                  (_filterType == 'refund' && p.refundedStock > 0);
              return matchesSearch && matchesFilter;
            }).toList();

            return Column(
              children: [
                _buildFilterChips(),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => productProvider.loadProducts(),
                    child: filteredProducts.isEmpty
                        ? Center(child: Text('Walang nahanap', style: TextStyle(color: Colors.grey[600])))
                        : ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = filteredProducts[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                builder: (context, value, child) => Transform.translate(
                                  offset: Offset((1 - value) * 50, 0),
                                  child: Opacity(opacity: value, child: child),
                                ),
                                child: _buildProductCard(product, productProvider, supplierProvider, index),
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
      floatingActionButton: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 400),
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductFormScreen())),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildErrorState(ProductProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Error: ${provider.error}'),
          const SizedBox(height: 16),
          ElevatedButton(onPressed: () => provider.loadProducts(), child: const Text('Retry')),
        ],
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
            Icon(Icons.inventory_2_outlined, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang products', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mag-tap ng + para magdagdag ng product', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
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
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            _buildFilterChip('Lahat', 'all'),
            const SizedBox(width: 8),
            _buildFilterChip('Mababa na', 'low_stock'),
            const SizedBox(width: 8),
            _buildFilterChip('Refund', 'refund'),
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
      selectedColor: const Color(0xFF1A6B8A),
      labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.grey[800], fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
      shape: StadiumBorder(side: BorderSide(color: isSelected ? Colors.transparent : Colors.grey[300]!)),
    );
  }

  Widget _buildProductCard(Product product, ProductProvider provider, SupplierProvider supplierProvider, int index) {
    final isExpanded = _expandedIndex == index;
    final isLowStock = product.quantity <= product.reorderLevel;
    final supplier = product.supplierId != null ? supplierProvider.getSupplierById(product.supplierId!) : null;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: product.photoPath != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(File(product.photoPath!), fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 32)),
                              )
                            : const Icon(Icons.image, size: 32, color: Colors.grey),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              product.name,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Wrap(
                              spacing: 8,
                              runSpacing: 4,
                              children: [
                                Text('₱${product.sellPrice.toStringAsFixed(2)}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                                Text('Stock: ${product.quantity}', style: TextStyle(fontSize: 12, color: isLowStock ? Colors.red : Colors.grey[700], fontWeight: isLowStock ? FontWeight.bold : FontWeight.normal)),
                                if (product.refundedStock > 0)
                                  Text('Ref: ${product.refundedStock}', style: TextStyle(fontSize: 12, color: Colors.orange[700], fontWeight: FontWeight.bold)),
                              ],
                            ),
                          ],
                        ),
                      ),
                      if (isLowStock)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: Colors.red.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                          child: Text('Mababa na', style: TextStyle(fontSize: 10, color: Colors.red[700], fontWeight: FontWeight.bold)),
                        ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400], size: 20),
                    ],
                  ),
                  if (isExpanded) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    _buildDetailRow(Icons.money, 'Buy Price:', '₱${product.buyPrice.toStringAsFixed(2)}'),
                    const SizedBox(height: 8),
                    _buildDetailRow(Icons.reorder, 'Reorder Level:', product.reorderLevel.toString()),
                    const SizedBox(height: 8),
                    if (product.supplierId != null)
                      _buildDetailRow(Icons.local_shipping, 'Supplier:', supplier?.name ?? 'Unknown'),
                    const SizedBox(height: 8),
                    if (product.expirationDate != null)
                      _buildDetailRow(Icons.calendar_today, 'Expiration:', product.expirationDate!),
                    const SizedBox(height: 8),
                    if (product.barcode != null)
                      _buildDetailRow(Icons.qr_code, 'Barcode:', product.barcode!),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildActionButton(
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => ProductFormScreen(product: product))),
                          icon: Icons.edit,
                          label: 'Edit',
                          color: const Color(0xFF1A6B8A),
                        ),
                        const SizedBox(width: 8),
                        _buildActionButton(
                          onPressed: () => _showDeleteDialog(product, provider),
                          icon: Icons.delete,
                          label: 'Burahin',
                          color: Colors.red,
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

  Widget _buildActionButton({required VoidCallback? onPressed, required IconData icon, required String label, required Color color}) {
    return MouseRegion(
      onEnter: (_) => setState(() {}),
      onExit: (_) => setState(() {}),
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 16),
        label: Text(label, style: const TextStyle(fontSize: 12)),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 100,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
        ),
      ],
    );
  }

  void _showDeleteDialog(Product product, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('Delete Product'),
          content: Text('Are you sure you want to delete ${product.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteProduct(product.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Product deleted')));
                }
              },
              child: const Text('Delete', style: TextStyle(color: Colors.red)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}