import '../database/database_helper.dart';
import '../models/product.dart';

class ProductRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<int> addProduct(Product product) async {
    return await _dbHelper.createProduct(product);
  }

  Future<Product?> getProductById(int id) async {
    return await _dbHelper.getProduct(id);
  }

  Future<List<Product>> getAllProducts() async {
    return await _dbHelper.getAllProducts();
  }

  Future<int> updateProduct(Product product) async {
    return await _dbHelper.updateProduct(product);
  }

  Future<int> deleteProduct(int id) async {
    return await _dbHelper.deleteProduct(id);
  }

  Future<List<Product>> getLowStockProducts() async {
    return await _dbHelper.getLowStockProducts();
  }

  // Deduct stock when a sale is made
  Future<int> deductStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return 0;

    final updatedProduct = product.copyWith(
      quantity: product.quantity - quantity,
    );

    return await updateProduct(updatedProduct);
  }

  // Add stock when restocking
  Future<int> addStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return 0;

    final updatedProduct = product.copyWith(
      quantity: product.quantity + quantity,
    );

    return await updateProduct(updatedProduct);
  }

  // Add to refunded stock when refunding
  Future<int> addRefundedStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return 0;

    final updatedProduct = product.copyWith(
      refundedStock: product.refundedStock + quantity,
    );

    return await updateProduct(updatedProduct);
  }

  // Deduct from refunded stock when reselling
  Future<int> deductRefundedStock(int productId, int quantity) async {
    final product = await getProductById(productId);
    if (product == null) return 0;

    final updatedProduct = product.copyWith(
      refundedStock: product.refundedStock - quantity,
    );

    return await updateProduct(updatedProduct);
  }
}
