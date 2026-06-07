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

class _UtangPaymentScreenState extends State<UtangPaymentScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<UtangTransactionProvider>().loadTransactionsByCustomerId(widget.customer.id!);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    try {
      return DateFormat('MMM dd, yyyy • hh:mm a').format(DateTime.parse(dateString));
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.customer.name} - Payments', style: const TextStyle(fontWeight: FontWeight.bold)),
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
        child: Consumer2<UtangTransactionProvider, CustomerProvider>(
          builder: (context, utangProvider, customerProvider, child) {
            if (utangProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final customer = customerProvider.getCustomerById(widget.customer.id!) ?? widget.customer;
            final transactions = utangProvider.transactions.where((t) => t.customerId == widget.customer.id).toList();

            return Column(
              children: [
                FadeTransition(
                  opacity: _animationController,
                  child: _buildBalanceCard(customer),
                ),
                Expanded(
                  child: transactions.isEmpty
                      ? _buildEmptyState()
                      : RefreshIndicator(
                          onRefresh: () => utangProvider.loadTransactionsByCustomerId(widget.customer.id!),
                          child: ListView.builder(
                            padding: const EdgeInsets.all(12),
                            itemCount: transactions.length,
                            itemBuilder: (context, index) {
                              final transaction = transactions[index];
                              return TweenAnimationBuilder<double>(
                                tween: Tween(begin: 0.0, end: 1.0),
                                duration: Duration(milliseconds: 300 + (index * 50)),
                                builder: (context, value, child) => Transform.translate(
                                  offset: Offset((1 - value) * 50, 0),
                                  child: Opacity(opacity: value, child: child),
                                ),
                                child: _buildTransactionCard(transaction, index),
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

  Widget _buildBalanceCard(Customer customer) {
    final hasBalance = customer.currentBalance > 0;
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: hasBalance
              ? [const Color(0xFFC4793A), const Color(0xFF4A2800)]
              : [const Color(0xFF2D9D6E), const Color(0xFF002117)],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Current Balance', style: TextStyle(fontSize: 14, color: Colors.white70)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: customer.currentBalance),
                duration: const Duration(milliseconds: 800),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) => Text(
                  '₱${value.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              if (customer.currentBalance > 0)
                AnimatedButton(
                  onPressed: () => _showPaymentDialog(customer),
                  icon: Icons.payment,
                  label: 'Bayad',
                  color: Colors.white,
                  textColor: const Color(0xFFC4793A),
                ),
            ],
          ),
          if (customer.creditLimit > 0) ...[
            const SizedBox(height: 12),
            Text(
              'Credit Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.white70),
            ),
          ],
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
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang transactions', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildTransactionCard(UtangTransaction transaction, int index) {
    final isCredit = transaction.type == 'credit';
    final isExpanded = _expandedIndex == index;

    return GestureDetector(
      onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
      child: Card(
        elevation: isExpanded ? 4 : 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        colors: isCredit
                            ? [Colors.orange[400]!, Colors.orange[700]!]
                            : [Colors.green[400]!, Colors.green[700]!],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isCredit ? Icons.shopping_cart : Icons.payment,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCredit ? 'Utang' : 'Bayad',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatDate(transaction.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: transaction.amount),
                    duration: const Duration(milliseconds: 600),
                    builder: (context, value, child) => Text(
                      '₱${value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isCredit ? Colors.orange : Colors.green,
                      ),
                    ),
                  ),
                  Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400]),
                ],
              ),
              if (isExpanded && transaction.notes != null) ...[
                const Divider(),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (isCredit ? Colors.orange : Colors.green).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.description, size: 16, color: isCredit ? Colors.orange : Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          transaction.notes!,
                          style: TextStyle(fontSize: 13, color: Colors.grey[700]),
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
    );
  }

  void _showPaymentDialog(Customer customer) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('I-record ang Bayad'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Kasalukuyang utang:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                      '₱${customer.currentBalance.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFC4793A), fontSize: 16),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                decoration: const InputDecoration(
                  labelText: 'Halaga ng Bayad',
                  border: OutlineInputBorder(),
                  prefixText: '₱',
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                autofocus: true,
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount == null || amount <= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pakilagyan ng valid na amount'), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }

                if (amount > customer.currentBalance) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ang bayad ay hindi dapat lampas sa kasalukuyang utang'), behavior: SnackBarBehavior.floating),
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
                    const SnackBar(content: Text('Naitala na ang bayad'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('I-save', style: TextStyle(color: Color(0xFFC4793A))),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}

// Extended AnimatedButton with textColor option
class AnimatedButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final IconData icon;
  final String label;
  final Color color;
  final Color? textColor;
  final bool isSmall;

  const AnimatedButton({
    super.key,
    this.onPressed,
    required this.icon,
    required this.label,
    required this.color,
    this.textColor,
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
          icon: Icon(widget.icon, size: widget.isSmall ? 16 : 20, color: widget.textColor ?? Colors.white),
          label: Text(
            widget.label,
            style: TextStyle(fontSize: widget.isSmall ? 12 : 14, color: widget.textColor ?? Colors.white),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: widget.color,
            foregroundColor: widget.textColor ?? Colors.white,
            padding: widget.isSmall
                ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                : const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(widget.isSmall ? 20 : 12)),
          ),
        ),
      ),
    );
  }
}