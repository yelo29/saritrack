import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../providers/purchase_order_provider.dart';
import '../models/purchase_order.dart';
import '../models/product.dart';
import '../models/supplier.dart';

class PurchaseOrderFormScreen extends StatefulWidget {
  final PurchaseOrder? purchaseOrder;

  const PurchaseOrderFormScreen({super.key, this.purchaseOrder});

  @override
  State<PurchaseOrderFormScreen> createState() => _PurchaseOrderFormScreenState();
}

class _PurchaseOrderFormScreenState extends State<PurchaseOrderFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _notesController = TextEditingController();
  
  Product? _selectedProduct;
  Supplier? _selectedSupplier;
  DateTime? _deliveryDate;

  @override
  void initState() {
    super.initState();
    if (widget.purchaseOrder != null) {
      _quantityController.text = widget.purchaseOrder!.quantity.toString();
      _buyPriceController.text = widget.purchaseOrder!.buyPrice.toString();
      _notesController.text = widget.purchaseOrder!.notes ?? '';
      if (widget.purchaseOrder!.deliveryDate != null) {
        _deliveryDate = DateTime.parse(widget.purchaseOrder!.deliveryDate!);
      }
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().loadProducts();
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _buyPriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDeliveryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _deliveryDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _deliveryDate = picked;
      });
    }
  }

  void _savePurchaseOrder() {
    if (_formKey.currentState!.validate()) {
      if (_selectedProduct == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pumili ng product')),
        );
        return;
      }

      final quantity = int.parse(_quantityController.text);
      final buyPrice = double.parse(_buyPriceController.text);
      final totalCost = quantity * buyPrice;

      final purchaseOrder = PurchaseOrder(
        id: widget.purchaseOrder?.id,
        supplierId: _selectedSupplier?.id,
        productId: _selectedProduct!.id!,
        quantity: quantity,
        buyPrice: buyPrice,
        totalCost: totalCost,
        deliveryDate: _deliveryDate?.toIso8601String(),
        status: widget.purchaseOrder?.status ?? 'pending',
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        createdAt: widget.purchaseOrder?.createdAt ?? DateTime.now().toIso8601String(),
      );

      final provider = context.read<PurchaseOrderProvider>();
      final success = widget.purchaseOrder == null
          ? provider.addPurchaseOrder(purchaseOrder)
          : provider.updatePurchaseOrder(purchaseOrder);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.purchaseOrder == null 
                ? 'Nadagdag na ang purchase order' 
                : 'Na-update na ang purchase order'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.purchaseOrder == null 
            ? 'Magdagdag ng Purchase Order' 
            : 'I-edit ang Purchase Order'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Consumer<ProductProvider>(
                builder: (context, productProvider, child) {
                  if (productProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return DropdownButtonFormField<Product>(
                    value: _selectedProduct,
                    decoration: const InputDecoration(
                      labelText: 'Product',
                      border: OutlineInputBorder(),
                    ),
                    items: productProvider.products.map((product) {
                      return DropdownMenuItem(
                        value: product,
                        child: Text('${product.name} (Stock: ${product.quantity})'),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedProduct = value;
                        if (value != null) {
                          _buyPriceController.text = value.buyPrice.toString();
                        }
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              Consumer<SupplierProvider>(
                builder: (context, supplierProvider, child) {
                  if (supplierProvider.suppliers.isEmpty) {
                    return const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Wala pang suppliers. Magdagdag muna ng supplier.'),
                      ),
                    );
                  }
                  return DropdownButtonFormField<Supplier>(
                    value: _selectedSupplier,
                    decoration: const InputDecoration(
                      labelText: 'Supplier (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: supplierProvider.suppliers.map((supplier) {
                      return DropdownMenuItem(
                        value: supplier,
                        child: Text(supplier.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplier = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                decoration: const InputDecoration(
                  labelText: 'Quantity',
                  border: OutlineInputBorder(),
                  helperText: 'Ilang units ang order',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final quantity = int.tryParse(value);
                  if (quantity == null || quantity <= 0) {
                    return 'Valid quantity required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyPriceController,
                decoration: const InputDecoration(
                  labelText: 'Buy Price',
                  border: OutlineInputBorder(),
                  helperText: 'Presyo per unit',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  final price = double.tryParse(value);
                  if (price == null || price <= 0) {
                    return 'Valid price required';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _selectDeliveryDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Delivery Date (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Kailan dadating ang order',
                  ),
                  child: Text(
                    _deliveryDate == null
                        ? 'Pumili ng delivery date'
                        : '${_deliveryDate!.year}-${_deliveryDate!.month.toString().padLeft(2, '0')}-${_deliveryDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes (Optional)',
                  border: OutlineInputBorder(),
                  helperText: 'Karagdagang impormasyon',
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _savePurchaseOrder,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: const Text('Save'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
