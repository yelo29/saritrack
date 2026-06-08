import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/supplier_provider.dart';
import '../models/product.dart';
import '../services/image_service.dart';
import 'barcode_scanner_screen.dart';

class ProductFormScreen extends StatefulWidget {
  final Product? product;

  const ProductFormScreen({super.key, this.product});

  @override
  State<ProductFormScreen> createState() => _ProductFormScreenState();
}

class _ProductFormScreenState extends State<ProductFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _quantityController = TextEditingController();
  final _refundedStockController = TextEditingController();
  final _buyPriceController = TextEditingController();
  final _sellPriceController = TextEditingController();
  final _reorderLevelController = TextEditingController();
  final _supplierController = TextEditingController();
  final _barcodeController = TextEditingController();
  String? _photoPath;
  int? _selectedSupplierId;
  DateTime? _expirationDate;
  String? _discountType;
  final _discountValueController = TextEditingController();
  final _vatRateController = TextEditingController();
  double _vatRate = 0;

  @override
  void initState() {
    super.initState();
    if (widget.product != null) {
      _nameController.text = widget.product!.name;
      _quantityController.text = widget.product!.quantity.toString();
      _refundedStockController.text = widget.product!.refundedStock.toString();
      _buyPriceController.text = widget.product!.buyPrice.toString();
      _sellPriceController.text = widget.product!.sellPrice.toString();
      _reorderLevelController.text = widget.product!.reorderLevel.toString();
      _photoPath = widget.product!.photoPath;
      _selectedSupplierId = widget.product!.supplierId;
      _supplierController.text = widget.product!.supplierId?.toString() ?? '';
      if (widget.product!.expirationDate != null) {
        _expirationDate = DateTime.parse(widget.product!.expirationDate!);
      }
      _barcodeController.text = widget.product!.barcode ?? '';
      _discountType = widget.product!.discountType;
      _discountValueController.text = widget.product!.discountValue.toString();
      _vatRate = widget.product!.vatRate;
      _vatRateController.text = _vatRate.toString();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SupplierProvider>().loadSuppliers();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _quantityController.dispose();
    _refundedStockController.dispose();
    _buyPriceController.dispose();
    _sellPriceController.dispose();
    _reorderLevelController.dispose();
    _supplierController.dispose();
    _barcodeController.dispose();
    _discountValueController.dispose();
    _vatRateController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final path = await ImageService.pickAndCompressImage();
    if (path != null) {
      setState(() {
        _photoPath = path;
      });
    }
  }

  Future<void> _scanBarcode() async {
    final scannedBarcode = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) => const BarcodeScannerScreen(),
      ),
    );

    if (scannedBarcode != null && mounted) {
      setState(() {
        _barcodeController.text = scannedBarcode;
      });
    }
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final productProvider = context.read<ProductProvider>();
    
    final product = Product(
      id: widget.product?.id,
      name: _nameController.text.trim(),
      quantity: int.parse(_quantityController.text),
      refundedStock: _refundedStockController.text.trim().isEmpty
          ? 0
          : int.parse(_refundedStockController.text.trim()),
      buyPrice: double.parse(_buyPriceController.text),
      sellPrice: double.parse(_sellPriceController.text),
      reorderLevel: int.parse(_reorderLevelController.text),
      photoPath: _photoPath,
      supplierId: _selectedSupplierId,
      expirationDate: _expirationDate?.toIso8601String(),
      barcode: _barcodeController.text.trim().isEmpty ? null : _barcodeController.text.trim(),
      discountType: _discountType,
      discountValue: _discountValueController.text.trim().isEmpty ? 0 : double.parse(_discountValueController.text.trim()),
      vatRate: _vatRate,
    );

    bool success;
    if (widget.product == null) {
      success = await productProvider.addProduct(product);
    } else {
      success = await productProvider.updateProduct(product);
    }

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.product == null 
              ? 'Nadagdag na ang product' 
              : 'Na-update na ang product'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.product == null ? 'Magdagdag ng Product' : 'I-edit ang Product'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Photo section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 200,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey[400]!),
                  ),
                  child: _photoPath != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            File(_photoPath!),
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return const Center(
                                child: Icon(Icons.image, size: 64, color: Colors.grey),
                              );
                            },
                          ),
                        )
                      : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate, size: 64, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('Mag-tap para magdagdag ng photo', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                ),
              ),
              if (_photoPath != null) ...[
                const SizedBox(height: 8),
                TextButton.icon(
                  onPressed: () {
                    setState(() {
                      _photoPath = null;
                    });
                  },
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Alisin ang photo'),
                ),
              ],
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Pangalan ng Product',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Paki-ilagay ang pangalan ng product';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _quantityController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Dami (Original Stock)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Paki-ilagay ang dami';
                  }
                  if (int.tryParse(value) == null || int.tryParse(value)! < 0) {
                    return 'Dapat ay positive na number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _refundedStockController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Refunded Stock (Optional)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value != null && value.trim().isNotEmpty) {
                    if (int.tryParse(value) == null || int.tryParse(value)! < 0) {
                      return 'Dapat ay positive na number';
                    }
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _buyPriceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Presyo ng Bili (₱)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Paki-ilagay ang presyo ng bili';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Paki-ilagay ang tamang presyo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _sellPriceController,
                keyboardType: TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Presyo ng Benta (₱)',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Paki-ilagay ang presyo ng benta';
                  }
                  if (double.tryParse(value) == null || double.parse(value) < 0) {
                    return 'Paki-ilagay ang tamang presyo';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _reorderLevelController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Reorder Level',
                  border: OutlineInputBorder(),
                  helperText: 'Minimum stock bago mag-alert',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Paki-ilagay ang reorder level';
                  }
                  if (int.tryParse(value) == null || int.parse(value) < 0) {
                    return 'Paki-ilagay ang tamang reorder level';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: () async {
                  final pickedDate = await showDatePicker(
                    context: context,
                    initialDate: _expirationDate ?? DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 3650)),
                  );
                  if (pickedDate != null) {
                    setState(() {
                      _expirationDate = pickedDate;
                    });
                  }
                },
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Expiration Date (Optional)',
                    border: OutlineInputBorder(),
                    helperText: 'Para sa mga perishable items',
                  ),
                  child: Text(
                    _expirationDate == null
                        ? 'Pumili ng expiration date'
                        : '${_expirationDate!.year}-${_expirationDate!.month.toString().padLeft(2, '0')}-${_expirationDate!.day.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _barcodeController,
                      decoration: const InputDecoration(
                        labelText: 'Barcode (Optional)',
                        border: OutlineInputBorder(),
                        helperText: 'I-scan o i-type ang barcode para mabilis na paghanap',
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _scanBarcode,
                    icon: const Icon(Icons.qr_code_scanner),
                    tooltip: 'Scan Barcode',
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Discount (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _discountType,
                decoration: const InputDecoration(
                  labelText: 'Discount Type',
                  border: OutlineInputBorder(),
                  helperText: 'Piliin ang uri ng discount',
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Walang Discount'),
                  ),
                  DropdownMenuItem(
                    value: 'percentage',
                    child: Text('Percentage (%)'),
                  ),
                  DropdownMenuItem(
                    value: 'fixed',
                    child: Text('Fixed Amount (₱)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _discountType = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              if (_discountType != null)
                TextFormField(
                  controller: _discountValueController,
                  decoration: InputDecoration(
                    labelText: _discountType == 'percentage' ? 'Discount Percentage (%)' : 'Discount Amount (₱)',
                    border: const OutlineInputBorder(),
                    helperText: _discountType == 'percentage' 
                        ? 'Halimbawa: 10 para sa 10% discount' 
                        : 'Halimbawa: 5 para sa ₱5 discount',
                  ),
                  keyboardType: TextInputType.number,
                ),
              if (_discountType != null) const SizedBox(height: 16),
              const SizedBox(height: 16),
              const Text(
                'VAT (Optional)',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<double>(
                value: _vatRate == 0 ? null : _vatRate,
                decoration: const InputDecoration(
                  labelText: 'VAT Rate',
                  border: OutlineInputBorder(),
                  helperText: 'Piliin ang VAT rate (12% para sa registered businesses)',
                ),
                items: const [
                  DropdownMenuItem(
                    value: null,
                    child: Text('Walang VAT (0%)'),
                  ),
                  DropdownMenuItem(
                    value: 12.0,
                    child: Text('12% (Standard VAT)'),
                  ),
                  DropdownMenuItem(
                    value: 0.0,
                    child: Text('0% (VAT Exempt)'),
                  ),
                ],
                onChanged: (value) {
                  setState(() {
                    _vatRate = value ?? 0;
                    _vatRateController.text = _vatRate.toString();
                  });
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

                  return DropdownButtonFormField<int>(
                    value: _selectedSupplierId,
                    decoration: const InputDecoration(
                      labelText: 'Supplier (Optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: supplierProvider.suppliers.map((supplier) {
                      return DropdownMenuItem<int>(
                        value: supplier.id,
                        child: Text(supplier.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSupplierId = value;
                      });
                    },
                  );
                },
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _saveProduct,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  minimumSize: const Size(double.infinity, 48),
                ),
                child: Text(
                  widget.product == null ? 'Magdagdag' : 'I-update',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
