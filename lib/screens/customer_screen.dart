import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import 'utang_payment_screen.dart';
import '../widgets/animated_button.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  int _expandedIndex = -1;
  int _hoveredIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
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
        title: const Text('Customers', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              context.read<CustomerProvider>().loadCustomers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang customers'), behavior: SnackBarBehavior.floating),
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
        child: Consumer<CustomerProvider>(
          builder: (context, customerProvider, child) {
            if (customerProvider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (customerProvider.error != null) {
              return _buildErrorState(customerProvider);
            }

            if (customerProvider.customers.isEmpty) {
              return _buildEmptyState();
            }

            return RefreshIndicator(
              onRefresh: () => customerProvider.loadCustomers(),
              child: ListView.builder(
                padding: const EdgeInsets.all(12),
                itemCount: customerProvider.customers.length,
                itemBuilder: (context, index) {
                  final customer = customerProvider.customers[index];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: Duration(milliseconds: 300 + (index * 50)),
                    builder: (context, value, child) => Transform.translate(
                      offset: Offset((1 - value) * 50, 0),
                      child: Opacity(opacity: value, child: child),
                    ),
                    child: _buildCustomerCard(customer, customerProvider, index),
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
          onPressed: () => _showCustomerDialog(),
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  Widget _buildErrorState(CustomerProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
          const SizedBox(height: 16),
          Text('Error: ${provider.error}'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => provider.loadCustomers(),
            child: const Text('Retry'),
          ),
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
            Icon(Icons.people_outline, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang customers', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Mag-tap ng + para magdagdag ng customer', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, CustomerProvider provider, int index) {
    final hasOutstandingBalance = customer.currentBalance > 0;
    final isOverLimit = customer.currentBalance > customer.creditLimit && customer.creditLimit > 0;
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
                          gradient: LinearGradient(
                            colors: hasOutstandingBalance
                                ? [const Color(0xFFC4793A), const Color(0xFF4A2800)]
                                : [const Color(0xFF1A6B8A), const Color(0xFF003547)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          customer.name[0].toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              customer.name,
                              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (customer.contact != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                customer.contact!,
                                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0.0, end: customer.currentBalance),
                            duration: const Duration(milliseconds: 600),
                            builder: (context, value, child) => Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: isOverLimit
                                    ? Colors.red.withOpacity(0.1)
                                    : hasOutstandingBalance
                                        ? Colors.orange.withOpacity(0.1)
                                        : Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                '₱${value.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isOverLimit ? Colors.red : hasOutstandingBalance ? Colors.orange : Colors.green,
                                ),
                              ),
                            ),
                          ),
                          if (customer.creditLimit > 0) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
                              style: TextStyle(fontSize: 9, color: Colors.grey[500]),
                            ),
                          ],
                        ],
                      ),
                      Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: Colors.grey[400], size: 18),
                    ],
                  ),
                  if (isExpanded) ...[
                    const Divider(),
                    const SizedBox(height: 12),
                    if (customer.address != null && customer.address!.isNotEmpty) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.location_on, size: 14, color: Colors.grey[600]),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              customer.address!,
                              style: TextStyle(fontSize: 12, color: Colors.grey[700]),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (hasOutstandingBalance)
                          AnimatedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => UtangPaymentScreen(customer: customer)),
                              );
                            },
                            icon: Icons.payment,
                            label: 'Bayad',
                            color: const Color(0xFFC4793A),
                            isSmall: true,
                          ),
                        const SizedBox(width: 8),
                        AnimatedButton(
                          onPressed: () => _showCustomerDialog(customer: customer),
                          icon: Icons.edit,
                          label: 'Edit',
                          color: const Color(0xFF1A6B8A),
                          isSmall: true,
                        ),
                        const SizedBox(width: 8),
                        AnimatedButton(
                          onPressed: () => _showDeleteDialog(customer, provider),
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

  void _showCustomerDialog({Customer? customer}) {
    final nameController = TextEditingController(text: customer?.name ?? '');
    final contactController = TextEditingController(text: customer?.contact ?? '');
    final addressController = TextEditingController(text: customer?.address ?? '');
    final creditLimitController = TextEditingController(text: customer?.creditLimit.toString() ?? '0');

    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: Text(customer == null ? 'Magdagdag ng Customer' : 'I-edit ang Customer'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Pangalan', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contactController,
                  decoration: const InputDecoration(labelText: 'Contact (Optional)', border: OutlineInputBorder()),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address (Optional)', border: OutlineInputBorder()),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: creditLimitController,
                  decoration: const InputDecoration(labelText: 'Credit Limit (Optional)', border: OutlineInputBorder(), prefixText: '₱'),
                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(
              onPressed: () async {
                if (nameController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pakilagyan ng pangalan'), behavior: SnackBarBehavior.floating),
                  );
                  return;
                }

                final newCustomer = Customer(
                  id: customer?.id,
                  name: nameController.text,
                  contact: contactController.text.isEmpty ? null : contactController.text,
                  address: addressController.text.isEmpty ? null : addressController.text,
                  creditLimit: double.tryParse(creditLimitController.text) ?? 0,
                  currentBalance: customer?.currentBalance ?? 0,
                );

                Navigator.pop(context);
                final success = customer == null
                    ? await context.read<CustomerProvider>().addCustomer(newCustomer)
                    : await context.read<CustomerProvider>().updateCustomer(newCustomer);

                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(customer == null ? 'Nadagdag na ang customer' : 'Na-update na ang customer')),
                  );
                }
              },
              child: Text(customer == null ? 'Idagdag' : 'I-save', style: const TextStyle(color: Color(0xFFC4793A))),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _showDeleteDialog(Customer customer, CustomerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('Burahin ang Customer'),
          content: Text('Sigurado ka bang gusto mong burahin si ${customer.name}?'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                final success = await provider.deleteCustomer(customer.id!);
                if (success && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nabura na ang customer')),
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