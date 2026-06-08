import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ExpiringProductsScreen extends StatefulWidget {
  const ExpiringProductsScreen({super.key});

  @override
  State<ExpiringProductsScreen> createState() => _ExpiringProductsScreenState();
}

class _ExpiringProductsScreenState extends State<ExpiringProductsScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
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
        title: const Text('Expiring Products', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
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
        child: Consumer<ProductProvider>(
          builder: (context, productProvider, child) {
            final expiringProducts = productProvider.products
                .where((p) => p.expirationDate != null && (p.isExpiringSoon || p.isExpired))
                .toList()
              ..sort((a, b) {
                if (a.expirationDate == null || b.expirationDate == null) return 0;
                return DateTime.parse(a.expirationDate!).compareTo(DateTime.parse(b.expirationDate!));
              });

            if (expiringProducts.isEmpty) {
              return _buildEmptyState();
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: expiringProducts.length,
              itemBuilder: (context, index) {
                final product = expiringProducts[index];
                return TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0.0, end: 1.0),
                  duration: Duration(milliseconds: 300 + (index * 80)),
                  builder: (context, value, child) => Transform.translate(
                    offset: Offset((1 - value) * 50, 0),
                    child: Opacity(opacity: value, child: child),
                  ),
                  child: _buildProductCard(product, index),
                );
              },
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
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.green.withOpacity(0.1),
              ),
              child: Icon(Icons.check_circle_outline, size: 80, color: Colors.green[400]),
            ),
            const SizedBox(height: 16),
            Text(
              'Walang products na a-expire',
              style: TextStyle(fontSize: 18, color: Colors.grey[600]),
            ),
            const SizedBox(height: 8),
            Text(
              'Lahat ng products ay safe!',
              style: TextStyle(fontSize: 14, color: Colors.grey[500]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(Product product, int index) {
    final isExpired = product.isExpired;
    final daysUntilExpiry = product.expirationDate != null
        ? DateTime.parse(product.expirationDate!).difference(DateTime.now()).inDays
        : 0;
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 12),
        child: Card(
          elevation: isExpanded ? 4 : 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                        gradient: LinearGradient(
                          colors: isExpired
                              ? [Colors.red[400]!, Colors.red[700]!]
                              : [Colors.orange[400]!, Colors.orange[700]!],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isExpired ? Icons.warning : Icons.access_time,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.name,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text('Stock: ${product.quantity}', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: product.sellPrice),
                          duration: const Duration(milliseconds: 600),
                          builder: (context, value, child) => Text(
                            '₱${value.toStringAsFixed(2)}',
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D9D6E)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: isExpired ? Colors.red.withOpacity(0.1) : Colors.orange.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isExpired ? 'EXPIRED' : '$daysUntilExpiry days',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.bold,
                              color: isExpired ? Colors.red : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400], size: 20),
                  ],
                ),
                if (isExpanded) ...[
                  const Divider(),
                  const SizedBox(height: 12),
                  _buildInfoRow(Icons.calendar_today, 'Expiration:', product.expirationDate?.split('T')[0] ?? 'N/A', isExpired ? Colors.red : Colors.orange),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.inventory, 'Stock:', product.quantity.toString(), Colors.grey[700]),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.sell, 'Selling Price:', '₱${product.sellPrice.toStringAsFixed(2)}', Colors.grey[700]),
                  const SizedBox(height: 8),
                  if (product.buyPrice > 0)
                    _buildInfoRow(Icons.shopping_cart, 'Cost Price:', '₱${product.buyPrice.toStringAsFixed(2)}', Colors.grey[700]),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, size: 14, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            isExpired
                                ? 'EXPIRED na. Hindi na dapat ibenta.'
                                : 'Mag-e-expire sa loob ng $daysUntilExpiry araw. Ibenta na kaagad!',
                            style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, Color? valueColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        const SizedBox(width: 8),
        SizedBox(
          width: 90,
          child: Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600]), overflow: TextOverflow.ellipsis),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: valueColor),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}