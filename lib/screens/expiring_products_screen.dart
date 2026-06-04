import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class ExpiringProductsScreen extends StatelessWidget {
  const ExpiringProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ProductProvider>(
      builder: (context, productProvider, child) {
        final expiringProducts = productProvider.products
            .where((p) => p.expirationDate != null && (p.isExpiringSoon || p.isExpired))
            .toList()
          ..sort((a, b) {
            if (a.expirationDate == null || b.expirationDate == null) return 0;
            return DateTime.parse(a.expirationDate!).compareTo(DateTime.parse(b.expirationDate!));
          });

        if (expiringProducts.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle_outline,
                  size: 64,
                  color: Colors.green[400],
                ),
                const SizedBox(height: 16),
                Text(
                  'Walang products na a-expire',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Lahat ng products ay safe!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: expiringProducts.length,
          itemBuilder: (context, index) {
            final product = expiringProducts[index];
            final isExpired = product.isExpired;
            final daysUntilExpiry = product.expirationDate != null
                ? DateTime.parse(product.expirationDate!).difference(DateTime.now()).inDays
                : 0;

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isExpired ? Colors.red : Colors.orange,
                  child: Icon(
                    isExpired ? Icons.warning : Icons.access_time,
                    color: Colors.white,
                  ),
                ),
                title: Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Stock: ${product.quantity}'),
                    Text(
                      'Expiration: ${product.expirationDate ?? 'N/A'}',
                      style: TextStyle(
                        color: isExpired ? Colors.red : Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (!isExpired)
                      Text(
                        'Expire in $daysUntilExpiry days',
                        style: const TextStyle(color: Colors.orange),
                      ),
                  ],
                ),
                trailing: Text(
                  '₱${product.sellPrice.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
