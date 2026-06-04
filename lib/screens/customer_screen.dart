import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customer_provider.dart';
import '../models/customer.dart';
import 'utang_payment_screen.dart';

class CustomerScreen extends StatefulWidget {
  const CustomerScreen({super.key});

  @override
  State<CustomerScreen> createState() => _CustomerScreenState();
}

class _CustomerScreenState extends State<CustomerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomerProvider>().loadCustomers();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: () {
              context.read<CustomerProvider>().loadCustomers();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Na-refresh na ang customers')),
              );
            },
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: Consumer<CustomerProvider>(
        builder: (context, customerProvider, child) {
          if (customerProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (customerProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${customerProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => customerProvider.loadCustomers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (customerProvider.customers.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Wala pang customers',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mag-tap ng + para magdagdag ng customer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => customerProvider.loadCustomers(),
            child: ListView.builder(
              itemCount: customerProvider.customers.length,
              itemBuilder: (context, index) {
                final customer = customerProvider.customers[index];
                return _buildCustomerCard(customer, customerProvider);
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCustomerDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCustomerCard(Customer customer, CustomerProvider provider) {
    final hasOutstandingBalance = customer.currentBalance > 0;
    final isOverLimit = customer.currentBalance > customer.creditLimit && customer.creditLimit > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: () {
          _showCustomerDialog(customer: customer);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: hasOutstandingBalance
                        ? Colors.orange
                        : Theme.of(context).colorScheme.primary,
                    child: Text(
                      customer.name[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          customer.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (customer.contact != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            customer.contact!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                        if (customer.address != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            customer.address!,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOverLimit
                              ? Colors.red.withOpacity(0.1)
                              : hasOutstandingBalance
                                  ? Colors.orange.withOpacity(0.1)
                                  : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '₱${customer.currentBalance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isOverLimit
                                ? Colors.red
                                : hasOutstandingBalance
                                    ? Colors.orange
                                    : Colors.green,
                          ),
                        ),
                      ),
                      if (customer.creditLimit > 0) ...[
                        const SizedBox(height: 4),
                        Text(
                          'Limit: ₱${customer.creditLimit.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (hasOutstandingBalance)
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UtangPaymentScreen(customer: customer),
                          ),
                        );
                      },
                      icon: const Icon(Icons.payment, size: 16),
                      label: const Text('Bayad'),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.orange,
                      ),
                    ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline),
                    onPressed: () => _showDeleteDialog(customer, provider),
                  ),
                ],
              ),
            ],
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
      builder: (context) => AlertDialog(
        title: Text(customer == null ? 'Magdagdag ng Customer' : 'I-edit ang Customer'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Pangalan',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: contactController,
                decoration: const InputDecoration(
                  labelText: 'Contact (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Address (Optional)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: creditLimitController,
                decoration: const InputDecoration(
                  labelText: 'Credit Limit (Optional)',
                  border: OutlineInputBorder(),
                  prefixText: '₱',
                ),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselahin'),
          ),
          TextButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Pakilagyan ng pangalan')),
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
            child: Text(customer == null ? 'Idagdag' : 'I-save', style: const TextStyle(color: Colors.orange)),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Customer customer, CustomerProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Burahin ang Customer'),
        content: Text('Sigurado ka bang gusto mong burahin si ${customer.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kanselahin'),
          ),
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
      ),
    );
  }
}
