import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';
import 'product_form_screen.dart';
import '../services/export_service.dart';

class ProductCatalogScreen extends StatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  State<ProductCatalogScreen> createState() => _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends State<ProductCatalogScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _filterType = 'all'; // 'all', 'low_stock', 'refund'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // Tutorial Dialog para sa Inventory Tab
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
                'Gabay sa Imbentaryo',
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
                    const TextSpan(text: 'Maligayang pagdating sa iyong '),
                    const TextSpan(text: 'Imbentaryo!\n\n', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: '1. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Para magdagdag ng bagong produkto, i-tap ang '),
                    const TextSpan(text: 'plus (+) button', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: ' sa ibabang kanang bahagi ng screen.\n\n'),
                    const TextSpan(text: '2. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Maaari mong gamitin ang '),
                    const TextSpan(text: 'Search Bar', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' sa itaas para mabilis na mahanap ang mga produkto gamit ang kanilang pangalan.\n\n'),
                    const TextSpan(text: '3. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Gamitin ang mga filter sa itaas:\n'),
                    const TextSpan(text: '• Lahat: ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Ipi-napakita ang lahat ng produkto.\n'),
                    const TextSpan(text: '• Mababa na: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                    const TextSpan(text: 'Ipi-napakita lamang ang mga produktong malapit nang maubos ang stock batay sa itinakda mong reorder level.\n'),
                    const TextSpan(text: '• Refund: ', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                    const TextSpan(text: 'Ipi-napakita ang mga produktong may naisoling stock.\n\n'),
                    const TextSpan(text: '4. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'I-tap ang mismong card ng produkto kung nais mo itong '),
                    const TextSpan(text: 'i-edit o i-update', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: ' ang presyo o dami ng stock nito.\n\n'),
                    const TextSpan(text: '5. ', style: TextStyle(fontWeight: FontWeight.bold)),
                    const TextSpan(text: 'Siguraduhing i-tap ang "↻"', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                    const TextSpan(text: ' button para i-refresh ang listahan ng produkto, kada sale mo.\n\n'),
                    // Inalis ang "const" dito para payagan ang paggamit ng Colors.amber[800] nang walang error
                    TextSpan(
                      text: 'Paalala: ', 
                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber[800]),
                    ),
                    const TextSpan(
                      text: 'Ang Sari Track ay isang ganap na offline app. Ang lahat ng datos ay ligtas na nakatago sa iyong device lamang, kaya siguraduhing ingatan ang iyong telepono upang hindi mawala ang iyong listahan.',
                    ),
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
          PopupMenuButton<String>(
            onSelected: (String choice) async {
              final productProvider = context.read<ProductProvider>();
              
              if (choice == 'csv') {
                await ExportService.exportProductsToCSV(productProvider.products);
              } else if (choice == 'pdf') {
                await ExportService.exportProductsToPDF(productProvider.products);
              }
            },
            itemBuilder: (BuildContext context) {
              return [
                const PopupMenuItem<String>(
                  value: 'csv',
                  child: Row(
                    children: [
                      Icon(Icons.table_chart),
                      SizedBox(width: 8),
                      Text('Export as CSV'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'pdf',
                  child: Row(
                    children: [
                      Icon(Icons.picture_as_pdf),
                      SizedBox(width: 8),
                      Text('Export as PDF'),
                    ],
                  ),
                ),
              ];
            },
          ),
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang imbentaryo')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
          // Idinagdag na "Paano?" Button
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

          if (productProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${productProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => productProvider.loadProducts(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (productProvider.products.isEmpty) {
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
                    'Wala pang products',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mag-tap ng + para magdagdag ng product',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
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
              Padding(
                padding: const EdgeInsets.all(8.0),
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
                      label: const Text('Mababa na'),
                      selected: _filterType == 'low_stock',
                      onSelected: (selected) {
                        setState(() {
                          _filterType = 'low_stock';
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Refund'),
                      selected: _filterType == 'refund',
                      onSelected: (selected) {
                        setState(() {
                          _filterType == 'refund';
                          _filterType = 'refund';
                        });
                      },
                    ),
                  ],
                ),
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () => productProvider.loadProducts(),
                  child: filteredProducts.isEmpty
                      ? Center(
                          child: Text(
                            _searchQuery.isEmpty && _filterType == 'all'
                                ? 'Wala pang products'
                                : 'Walang nahanap',
                          ),
                        )
                      : ListView.builder(
                          itemCount: filteredProducts.length,
                          itemBuilder: (context, index) {
                            final product = filteredProducts[index];
                            return _buildProductCard(product, productProvider);
                          },
                        ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const ProductFormScreen(),
            ),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildProductCard(Product product, ProductProvider provider) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductFormScreen(product: product),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
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
                            return const Icon(Icons.image, size: 32);
                          },
                        ),
                      )
                    : const Icon(Icons.image, size: 32, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          '₱${product.sellPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        Text(
                          'Stock: ${product.quantity}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.isLowStock ? Colors.red : Colors.grey[700],
                            fontWeight: product.isLowStock ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        if (product.refundedStock > 0)
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
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (product.isLowStock)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Mababa na',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.red[900],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteDialog(product, provider),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Product product, ProductProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await provider.deleteProduct(product.id!);
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Product deleted')),
                );
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}