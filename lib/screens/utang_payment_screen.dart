import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/customer.dart';
import '../models/utang_transaction.dart';
import '../providers/utang_transaction_provider.dart';
import '../providers/customer_provider.dart';
import 'package:intl/intl.dart';

class UtangPaymentScreen extends StatefulWidget {
  final Customer customer;

  const UtangPaymentScreen({super.key, required this.customer});

  @override
  State<UtangPaymentScreen> createState() => _UtangPaymentScreenState();
}

class _UtangPaymentScreenState extends State<UtangPaymentScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UtangTransactionProvider>().loadTransactionsByCustomerId(widget.customer.id!);
    });
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy • hh:mm a').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name} - Payments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Consumer2<UtangTransactionProvider, CustomerProvider>(
        builder: (context, utangProvider, customerProvider, child) {
          if (utangProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final customer = customerProvider.getCustomerById(widget.customer.id!) ?? widget.customer;
          final transactions = utangProvider.transactions.where((t) => t.customerId == widget.customer.id).toList();

          return Column(
            children: [
              // Balance Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: customer.currentBalance > 0
                    ? Colors.orange.withOpacity(0.1)
                    : Colors.green.withOpacity(0.1),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Current Balance',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '₱${customer.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: customer.currentBalance > 0 ? Colors.orange : Colors.green,
                          ),
                        ),
                        if (customer.currentBalance > 0)
                          ElevatedButton.icon(
                            onPressed: () => _showPaymentDialog(customer),
                            icon: const Icon(Icons.payment),
                            label: const Text('Bayad'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                            ),
                          ),
                      ],
                    ),
                    if (customer.creditLimit > 0) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Credit Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
              // Transactions List
              Expanded(
                child: transactions.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.receipt_long,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Wala pang transactions',
                              style: TextStyle(
                                fontSize: 18,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => utangProvider.loadTransactionsByCustomerId(widget.customer.id!),
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return _buildTransactionCard(transaction);
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTransactionCard(UtangTransaction transaction) {
    final isCredit = transaction.type == 'credit';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: isCredit ? Colors.orange : Colors.green,
              child: Icon(
                isCredit ? Icons.shopping_cart : Icons.payment,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isCredit ? 'Utang' : 'Bayad',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (transaction.notes != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      transaction.notes!,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    _formatDate(transaction.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Text(
              '₱${transaction.amount.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isCredit ? Colors.orange : Colors.green,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPaymentDialog(Customer customer) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('I-record ang Bayad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Kasalukuyang utang: ₱${customer.currentBalance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              decoration: const InputDecoration(
                labelText: 'Halaga ng Bayad',
                border: OutlineInputBorder(),
                prefixText: '₱',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: notesController,
              decoration: const InputDecoration(
                labelText: 'Notes (Optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
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
              final amount = double.tryParse(amountController.text);
              if (amount == null || amount <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pakilagyan ng valid na amount')),
                );
                return;
              }

              if (amount > customer.currentBalance) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Ang bayad ay hindi dapat lampas sa kasalukuyang utang')),
                );
                return;
              }

              Navigator.pop(context);

              final transaction = UtangTransaction(
                customerId: customer.id!,
                amount: amount,
                type: 'payment',
                notes: notesController.text.isEmpty ? null : notesController.text,
                createdAt: DateTime.now().toIso8601String(),
              );

              final success = await context.read<UtangTransactionProvider>().addUtangTransaction(transaction);

              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Naitala na ang bayad')),
                );
              }
            },
            child: const Text('I-save', style: TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }
}
