import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/expense_provider.dart';
import '../models/expense.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class ExpenseScreen extends StatefulWidget {
  const ExpenseScreen({super.key});

  @override
  State<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends State<ExpenseScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _hoveredIndex = -1;
  int _expandedIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ExpenseProvider>().loadExpenses();
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String _formatDate(String dateString) {
    try {
      final dateTime = DateTime.parse(dateString);
      return DateFormat('MMM dd, yyyy').format(dateTime);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expenses', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (String choice) async {
              final expenseProvider = context.read<ExpenseProvider>();
              if (choice == 'csv') {
                await ExportService.exportExpensesToCSV(expenseProvider.expenses);
              } else if (choice == 'pdf') {
                await ExportService.exportExpensesToPDF(expenseProvider.expenses);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart), SizedBox(width: 8), Text('Export as CSV')])),
              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Text('Export as PDF')])),
            ],
          ),
          IconButton(
            onPressed: () {
              context.read<ExpenseProvider>().loadExpenses();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang expenses'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.refresh),
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
        child: Consumer<ExpenseProvider>(
          builder: (context, expenseProvider, child) {
            if (expenseProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (expenseProvider.error != null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                    const SizedBox(height: 16),
                    Text('Error: ${expenseProvider.error}'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => expenseProvider.loadExpenses(),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            if (expenseProvider.expenses.isEmpty) {
              return _buildEmptyState();
            }

            final totalExpenses = expenseProvider.getTotalExpenses();

            return Column(
              children: [
                _buildSummaryCard(totalExpenses),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => expenseProvider.loadExpenses(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: expenseProvider.expenses.length,
                      itemBuilder: (context, index) {
                        final expense = expenseProvider.expenses[index];
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: Duration(milliseconds: 300 + (index * 50)),
                          builder: (context, value, child) => Transform.translate(
                            offset: Offset((1 - value) * 50, 0),
                            child: Opacity(opacity: value, child: child),
                          ),
                          child: _buildExpenseCard(expense, expenseProvider, index),
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
          onPressed: () => _showExpenseDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.receipt_long, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang expenses', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mag-tap ng + para magdagdag ng expense', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(double totalExpenses) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * -30),
        child: Opacity(opacity: value, child: child),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.red[700]!, Colors.red[400]!],
          ),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Total Expenses', style: TextStyle(fontSize: 14, color: Colors.white70)),
                SizedBox(height: 4),
                Text('Gastos', style: TextStyle(fontSize: 12, color: Colors.white54)),
              ],
            ),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: totalExpenses),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) => Text(
                '₱${value.toStringAsFixed(2)}',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseCard(Expense expense, ExpenseProvider provider, int index) {
    final isExpanded = _expandedIndex == index;

    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredIndex = index),
      onExit: (_) => setState(() => _hoveredIndex = -1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.identity()..scale(_hoveredIndex == index ? 1.01 : 1.0),
        child: Card(
          elevation: _hoveredIndex == index ? 4 : 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: InkWell(
            onTap: () => setState(() => _expandedIndex = isExpanded ? -1 : index),
            borderRadius: BorderRadius.circular(12),
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
                            colors: [Colors.red[400]!, Colors.red[700]!],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(_getCategoryIcon(expense.category), color: Colors.white, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              expense.category,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDate(expense.createdAt),
                              style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '₱${expense.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[700],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete_outline, size: 18),
                            onPressed: () => _showDeleteDialog(expense, provider),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ],
                  ),
                  if (isExpanded && expense.description != null && expense.description!.isNotEmpty) ...[
                    const Divider(),
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.description, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            expense.description!,
                            style: const TextStyle(fontSize: 12, color: Colors.black54),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
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

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'utilities': return Icons.electrical_services;
      case 'supplies': return Icons.inventory_2;
      case 'rent': return Icons.home;
      case 'salary': return Icons.person;
      case 'transportation': return Icons.directions_car;
      case 'food': return Icons.restaurant;
      case 'miscellaneous': case 'others': return Icons.more_horiz;
      default: return Icons.receipt;
    }
  }

  void _showExpenseDialog({Expense? expense}) {
    final categoryController = TextEditingController(text: expense?.category ?? '');
    final amountController = TextEditingController(text: expense?.amount.toString() ?? '');
    final descriptionController = TextEditingController(text: expense?.description ?? '');
    final categories = ['Utilities', 'Supplies', 'Rent', 'Salary', 'Transportation', 'Food', 'Miscellaneous', 'Others'];

    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(expense == null ? 'Magdagdag ng Expense' : 'I-edit ang Expense'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: categoryController.text.isEmpty ? null : categoryController.text,
                    decoration: const InputDecoration(labelText: 'Category', border: OutlineInputBorder()),
                    items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (value) => setDialogState(() => categoryController.text = value ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    decoration: const InputDecoration(labelText: 'Amount', border: OutlineInputBorder(), prefixText: '₱'),
                    keyboardType: TextInputType.numberWithOptions(decimal: true),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: descriptionController,
                    decoration: const InputDecoration(labelText: 'Description (Optional)', border: OutlineInputBorder()),
                    maxLines: 3,
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
              TextButton(
                onPressed: () async {
                  if (categoryController.text.isEmpty || amountController.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pakilagyan ng category at amount'), behavior: SnackBarBehavior.floating),
                    );
                    return;
                  }

                  final newExpense = Expense(
                    id: expense?.id,
                    category: categoryController.text,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    description: descriptionController.text.isEmpty ? null : descriptionController.text,
                    createdAt: expense?.createdAt ?? DateTime.now().toIso8601String(),
                  );

                  Navigator.pop(context);
                  final success = expense == null
                      ? await context.read<ExpenseProvider>().addExpense(newExpense)
                      : await context.read<ExpenseProvider>().updateExpense(newExpense);

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(expense == null ? 'Nadagdag na ang expense' : 'Na-update na ang expense')),
                    );
                  }
                },
                child: Text(expense == null ? 'Idagdag' : 'I-save', style: const TextStyle(color: Colors.orange)),
              ),
            ],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ),
    );
  }

  void _showDeleteDialog(Expense expense, ExpenseProvider provider) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('Burahin ang Expense'),
          content: Text('Sigurado ka bang gusto mong burahin ang expense na ito?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteExpense(expense.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nabura na ang expense')));
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