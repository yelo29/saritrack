import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/supplier.dart';
import '../models/sync_queue.dart';
import '../models/refund.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('saritrack.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 12,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Create products table
    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL DEFAULT 0,
        refunded_stock INTEGER NOT NULL DEFAULT 0,
        buy_price REAL NOT NULL,
        sell_price REAL NOT NULL,
        reorder_level INTEGER NOT NULL DEFAULT 5,
        photo_path TEXT,
        supplier_id INTEGER,
        expiration_date TEXT,
        barcode TEXT,
        discount_type TEXT,
        discount_value REAL DEFAULT 0,
        FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE SET NULL
      )
    ''');

    // Create sales table
    await db.execute('''
      CREATE TABLE sales (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        product_id INTEGER NOT NULL,
        qty_sold INTEGER NOT NULL,
        total REAL NOT NULL,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        is_resold INTEGER NOT NULL DEFAULT 0,
        amount_paid REAL,
        change_given REAL,
        discount_type TEXT,
        discount_value REAL DEFAULT 0,
        original_price REAL NOT NULL,
        FOREIGN KEY (product_id) REFERENCES products(id) ON DELETE CASCADE
      )
    ''');

    // Create suppliers table
    await db.execute('''
      CREATE TABLE suppliers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT,
        address TEXT,
        last_restock_date TEXT
      )
    ''');

    // Create sync_queue table
    await db.execute('''
      CREATE TABLE sync_queue (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        method TEXT NOT NULL,
        endpoint TEXT NOT NULL,
        payload TEXT,
        timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
        retries INTEGER DEFAULT 0
      )
    ''');

    // Create refunds table
    await db.execute('''
      CREATE TABLE refunds (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        sale_id INTEGER NOT NULL,
        reason TEXT NOT NULL,
        refunded_at TEXT NOT NULL,
        amount REAL NOT NULL,
        FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
      )
    ''');

    // Create indexes for better performance
    await db.execute('CREATE INDEX idx_sales_product_id ON sales(product_id)');
    await db.execute('CREATE INDEX idx_sales_created_at ON sales(created_at)');
    await db.execute('CREATE INDEX idx_products_supplier_id ON products(supplier_id)');
    await db.execute('CREATE INDEX idx_refunds_sale_id ON refunds(sale_id)');

    // Create expenses table
    await db.execute('''
      CREATE TABLE expenses (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        description TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP
      )
    ''');
    await db.execute('CREATE INDEX idx_expenses_created_at ON expenses(created_at)');

    // Create customers table
    await db.execute('''
      CREATE TABLE customers (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        contact TEXT,
        address TEXT,
        credit_limit REAL DEFAULT 0,
        current_balance REAL DEFAULT 0
      )
    ''');

    // Create utang_transactions table
    await db.execute('''
      CREATE TABLE utang_transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        customer_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        type TEXT NOT NULL,
        notes TEXT,
        created_at TEXT DEFAULT CURRENT_TIMESTAMP,
        FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
      )
    ''');
    await db.execute('CREATE INDEX idx_utang_customer_id ON utang_transactions(customer_id)');
    await db.execute('CREATE INDEX idx_utang_created_at ON utang_transactions(created_at)');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add address column to suppliers table
      await db.execute('ALTER TABLE suppliers ADD COLUMN address TEXT');
    }
    if (oldVersion < 3) {
      // Create refunds table
      await db.execute('''
        CREATE TABLE refunds (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          sale_id INTEGER NOT NULL,
          reason TEXT NOT NULL,
          refunded_at TEXT NOT NULL,
          amount REAL NOT NULL,
          FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_refunds_sale_id ON refunds(sale_id)');
    }
    if (oldVersion < 4) {
      // Add refunded_stock column to products table
      await db.execute('ALTER TABLE products ADD COLUMN refunded_stock INTEGER NOT NULL DEFAULT 0');
      // Add is_resold column to sales table
      await db.execute('ALTER TABLE sales ADD COLUMN is_resold INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 5) {
      // Add amount_paid column to sales table
      await db.execute('ALTER TABLE sales ADD COLUMN amount_paid REAL DEFAULT 0');
      // Add change_given column to sales table
      await db.execute('ALTER TABLE sales ADD COLUMN change_given REAL DEFAULT 0');
    }
    if (oldVersion < 6) {
      // Add quantity column to refunds table
      await db.execute('ALTER TABLE refunds ADD COLUMN quantity INTEGER NOT NULL DEFAULT 0');
    }
    if (oldVersion < 7) {
      // Create expenses table
      await db.execute('''
        CREATE TABLE expenses (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          category TEXT NOT NULL,
          amount REAL NOT NULL,
          description TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');
      await db.execute('CREATE INDEX idx_expenses_created_at ON expenses(created_at)');
    }
    if (oldVersion < 8) {
      // Create customers table
      await db.execute('''
        CREATE TABLE customers (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          name TEXT NOT NULL,
          contact TEXT,
          address TEXT,
          credit_limit REAL DEFAULT 0,
          current_balance REAL DEFAULT 0
        )
      ''');

      // Create utang_transactions table
      await db.execute('''
        CREATE TABLE utang_transactions (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          customer_id INTEGER NOT NULL,
          amount REAL NOT NULL,
          type TEXT NOT NULL,
          notes TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
        )
      ''');
      await db.execute('CREATE INDEX idx_utang_customer_id ON utang_transactions(customer_id)');
      await db.execute('CREATE INDEX idx_utang_created_at ON utang_transactions(created_at)');
    }
    if (oldVersion < 9) {
      // Add expiration_date column to products table
      await db.execute('ALTER TABLE products ADD COLUMN expiration_date TEXT');
    }
    if (oldVersion < 10) {
      // Add barcode column to products table
      await db.execute('ALTER TABLE products ADD COLUMN barcode TEXT');
    }
    if (oldVersion < 11) {
      // Add discount columns to products table
      await db.execute('ALTER TABLE products ADD COLUMN discount_type TEXT');
      await db.execute('ALTER TABLE products ADD COLUMN discount_value REAL DEFAULT 0');
    }
    if (oldVersion < 12) {
      // Add discount columns to sales table
      await db.execute('ALTER TABLE sales ADD COLUMN discount_type TEXT');
      await db.execute('ALTER TABLE sales ADD COLUMN discount_value REAL DEFAULT 0');
      await db.execute('ALTER TABLE sales ADD COLUMN original_price REAL DEFAULT total');
    }
  }

  // Product CRUD operations
  Future<int> createProduct(Product product) async {
    final db = await instance.database;
    return await db.insert('products', product.toMap());
  }

  Future<Product?> getProduct(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> getAllProducts() async {
    final db = await instance.database;
    final result = await db.query('products', orderBy: 'name ASC');
    return result.map((map) => Product.fromMap(map)).toList();
  }

  Future<int> updateProduct(Product product) async {
    final db = await instance.database;
    return await db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sale CRUD operations
  Future<int> createSale(Sale sale) async {
    final db = await instance.database;
    return await db.insert('sales', sale.toMap());
  }

  Future<List<Sale>> getAllSales() async {
    final db = await instance.database;
    final result = await db.query('sales', orderBy: 'created_at DESC');
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByProductId(int productId) async {
    final db = await instance.database;
    final result = await db.query(
      'sales',
      where: 'product_id = ?',
      whereArgs: [productId],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  Future<List<Sale>> getSalesByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'sales',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );
    return result.map((map) => Sale.fromMap(map)).toList();
  }

  // Supplier CRUD operations
  Future<int> createSupplier(Supplier supplier) async {
    final db = await instance.database;
    return await db.insert('suppliers', supplier.toMap());
  }

  Future<Supplier?> getSupplier(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return Supplier.fromMap(maps.first);
  }

  Future<List<Supplier>> getAllSuppliers() async {
    final db = await instance.database;
    final result = await db.query('suppliers', orderBy: 'name ASC');
    return result.map((map) => Supplier.fromMap(map)).toList();
  }

  Future<int> updateSupplier(Supplier supplier) async {
    final db = await instance.database;
    return await db.update(
      'suppliers',
      supplier.toMap(),
      where: 'id = ?',
      whereArgs: [supplier.id],
    );
  }

  Future<int> deleteSupplier(int id) async {
    final db = await instance.database;
    return await db.delete(
      'suppliers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Sync Queue operations
  Future<int> addToSyncQueue(SyncQueue item) async {
    final db = await instance.database;
    return await db.insert('sync_queue', item.toMap());
  }

  Future<List<SyncQueue>> getSyncQueue() async {
    final db = await instance.database;
    final result = await db.query('sync_queue', orderBy: 'timestamp ASC');
    return result.map((map) => SyncQueue.fromMap(map)).toList();
  }

  Future<int> deleteSyncQueueItem(int id) async {
    final db = await instance.database;
    return await db.delete(
      'sync_queue',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearSyncQueue() async {
    final db = await instance.database;
    return await db.delete('sync_queue');
  }

  // Utility: Get products with low stock
  Future<List<Product>> getLowStockProducts() async {
    final db = await instance.database;
    final result = await db.query(
      'products',
      where: 'quantity <= reorder_level',
      orderBy: 'quantity ASC',
    );
    return result.map((map) => Product.fromMap(map)).toList();
  }

  // Close database
  Future<void> close() async {
    final db = await instance.database;
    if (db != null) {
      await db.close();
    }
  }

  // Refund CRUD operations
  Future<int> createRefund(Refund refund) async {
    final db = await instance.database;
    return await db.insert('refunds', refund.toMap());
  }

  Future<List<Refund>> getAllRefunds() async {
    final db = await instance.database;
    final result = await db.query('refunds', orderBy: 'refunded_at DESC');
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<List<Refund>> getRefundsBySaleId(int saleId) async {
    final db = await instance.database;
    final result = await db.query(
      'refunds',
      where: 'sale_id = ?',
      whereArgs: [saleId],
      orderBy: 'refunded_at DESC',
    );
    return result.map((map) => Refund.fromMap(map)).toList();
  }

  Future<int> deleteRefund(int id) async {
    final db = await instance.database;
    return await db.delete(
      'refunds',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // Expense CRUD operations
  Future<int> createExpense(Map<String, dynamic> expense) async {
    final db = await instance.database;
    return await db.insert('expenses', expense);
  }

  Future<List<Map<String, dynamic>>> getAllExpenses() async {
    final db = await instance.database;
    final result = await db.query('expenses', orderBy: 'created_at DESC');
    return result;
  }

  Future<List<Map<String, dynamic>>> getExpensesByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.query(
      'expenses',
      where: 'created_at BETWEEN ? AND ?',
      whereArgs: [startDate, endDate],
      orderBy: 'created_at DESC',
    );
    return result;
  }

  Future<int> updateExpense(int id, Map<String, dynamic> expense) async {
    final db = await instance.database;
    return await db.update(
      'expenses',
      expense,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteExpense(int id) async {
    final db = await instance.database;
    return await db.delete(
      'expenses',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<double> getTotalExpensesByDateRange(String startDate, String endDate) async {
    final db = await instance.database;
    final result = await db.rawQuery(
      'SELECT SUM(amount) as total FROM expenses WHERE created_at BETWEEN ? AND ?',
      [startDate, endDate],
    );
    return result.first['total'] as double? ?? 0.0;
  }

  // Customer CRUD operations
  Future<int> createCustomer(Map<String, dynamic> customer) async {
    final db = await instance.database;
    return await db.insert('customers', customer);
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await instance.database;
    final result = await db.query('customers', orderBy: 'name ASC');
    return result;
  }

  Future<Map<String, dynamic>?> getCustomer(int id) async {
    final db = await instance.database;
    final maps = await db.query(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );

    if (maps.isEmpty) return null;
    return maps.first;
  }

  Future<int> updateCustomer(int id, Map<String, dynamic> customer) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      customer,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteCustomer(int id) async {
    final db = await instance.database;
    return await db.delete(
      'customers',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> updateCustomerBalance(int customerId, double newBalance) async {
    final db = await instance.database;
    return await db.update(
      'customers',
      {'current_balance': newBalance},
      where: 'id = ?',
      whereArgs: [customerId],
    );
  }

  // Utang Transaction CRUD operations
  Future<int> createUtangTransaction(Map<String, dynamic> transaction) async {
    final db = await instance.database;
    return await db.insert('utang_transactions', transaction);
  }

  Future<List<Map<String, dynamic>>> getUtangTransactionsByCustomerId(int customerId) async {
    final db = await instance.database;
    final result = await db.query(
      'utang_transactions',
      where: 'customer_id = ?',
      whereArgs: [customerId],
      orderBy: 'created_at DESC',
    );
    return result;
  }

  Future<List<Map<String, dynamic>>> getAllUtangTransactions() async {
    final db = await instance.database;
    final result = await db.query('utang_transactions', orderBy: 'created_at DESC');
    return result;
  }

  Future<double> getCustomerBalance(int customerId) async {
    final db = await instance.database;
    final customer = await getCustomer(customerId);
    if (customer == null) return 0.0;
    return customer['current_balance'] as double? ?? 0.0;
  }
}
