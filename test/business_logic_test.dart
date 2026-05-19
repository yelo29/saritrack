import 'package:flutter_test/flutter_test.dart';
import 'package:saritrack/models/product.dart';

void main() {
  group('Stock Deduction Logic', () {
    test('Product correctly identifies low stock', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 3,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      expect(product.isLowStock, true);
    });

    test('Product correctly identifies sufficient stock', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 10,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      expect(product.isLowStock, false);
    });

    test('Product at reorder level is considered low stock', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 5,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      expect(product.isLowStock, true);
    });

    test('Stock deduction calculation', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final quantityToDeduct = 5;
      final updatedProduct = product.copyWith(
        quantity: product.quantity - quantityToDeduct,
      );

      expect(updatedProduct.quantity, 15);
      expect(updatedProduct.isLowStock, false);
    });

    test('Stock deduction results in low stock', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 7,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final quantityToDeduct = 3;
      final updatedProduct = product.copyWith(
        quantity: product.quantity - quantityToDeduct,
      );

      expect(updatedProduct.quantity, 4);
      expect(updatedProduct.isLowStock, true);
    });
  });

  group('Profit Calculation Logic', () {
    test('Calculate profit per unit', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final profitPerUnit = product.sellPrice - product.buyPrice;
      expect(profitPerUnit, 5.0);
    });

    test('Calculate total profit for multiple units', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final quantitySold = 10;
      final totalProfit = (product.sellPrice - product.buyPrice) * quantitySold;
      expect(totalProfit, 50.0);
    });

    test('Calculate total sale amount', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final quantitySold = 5;
      final totalSale = product.sellPrice * quantitySold;
      expect(totalSale, 75.0);
    });

    test('Calculate profit margin percentage', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final profitMargin = ((product.sellPrice - product.buyPrice) / product.buyPrice) * 100;
      expect(profitMargin, 50.0);
    });

    test('Zero profit when buy price equals sell price', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 15.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final profitPerUnit = product.sellPrice - product.buyPrice;
      expect(profitPerUnit, 0.0);
    });

    test('Loss when sell price is less than buy price', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 20,
        buyPrice: 15.0,
        sellPrice: 10.0,
        reorderLevel: 5,
      );

      final profitPerUnit = product.sellPrice - product.buyPrice;
      expect(profitPerUnit, -5.0);
    });
  });

  group('Product Model Tests', () {
    test('Product toMap conversion', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 10,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
        supplierId: 2,
      );

      final map = product.toMap();

      expect(map['id'], 1);
      expect(map['name'], 'Test Product');
      expect(map['quantity'], 10);
      expect(map['buy_price'], 10.0);
      expect(map['sell_price'], 15.0);
      expect(map['reorder_level'], 5);
      expect(map['supplier_id'], 2);
    });

    test('Product fromMap conversion', () {
      final map = {
        'id': 1,
        'name': 'Test Product',
        'quantity': 10,
        'buy_price': 10.0,
        'sell_price': 15.0,
        'reorder_level': 5,
        'photo_path': null,
        'supplier_id': 2,
      };

      final product = Product.fromMap(map);

      expect(product.id, 1);
      expect(product.name, 'Test Product');
      expect(product.quantity, 10);
      expect(product.buyPrice, 10.0);
      expect(product.sellPrice, 15.0);
      expect(product.reorderLevel, 5);
      expect(product.supplierId, 2);
    });

    test('Product copyWith creates new instance', () {
      final product = Product(
        id: 1,
        name: 'Test Product',
        quantity: 10,
        buyPrice: 10.0,
        sellPrice: 15.0,
        reorderLevel: 5,
      );

      final updatedProduct = product.copyWith(quantity: 20);

      expect(product.quantity, 10);
      expect(updatedProduct.quantity, 20);
      expect(updatedProduct.name, product.name);
      expect(updatedProduct.buyPrice, product.buyPrice);
    });
  });
}
