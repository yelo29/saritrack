# SariTrack

An offline-first inventory and sales tracker mobile application designed for Filipino sari-sari store owners. SariTrack helps store owners manage their products, track sales, monitor stock levels, and analyze profits - all without requiring an internet connection.

## Features

### Core Functionality
- **Product Catalog**: Add, edit, and delete products with name, quantity, buying price, selling price, reorder level, optional product photos, expiration date tracking, barcode for quick scanning, discount system, and CSV/PDF export
- **Quick Sale Screen**: Fast point-of-sale interface with product tiles in a grid layout, cart functionality, automatic stock deduction, expiration status indicators, barcode scanning, and discount price display
- **Quantity Picker**: Select multiple units when adding products to cart in Sell and Re-Sell tabs
- **Partial Removal**: Remove specific quantities from cart instead of all items
- **Refund Management**: Process refunds with quantity selection and reason tracking
- **Re-Sell Feature**: Resell refunded products with dedicated cart and checkout flow
- **Utang/Credit Tracking**: Track customer credits (utang) with customer management, credit limits, payment recording, and checkout integration
- **Expense Tracking**: Record business expenses (utilities, supplies, rent, salary, etc.) with category-based organization and CSV/PDF export
- **Local Backup/Restore**: Export database to JSON file for data safety and restore from backup when switching devices or recovering data
- **Expiration Date Tracking**: Track product expiration dates with visual indicators (expiring soon/expired) and dedicated expiring products report
- **Barcode Scanning**: Scan product barcodes using camera for quick product lookup and automatic cart addition
- **CSV/PDF Export**: Export sales history, expenses, profit data, and inventory to CSV or PDF format for accounting and record-keeping
- **Discount System**: Set percentage or fixed amount discounts on products for promotions and sales
- **Low-Stock Alerts**: Automatic notifications when products fall below their reorder level (both on app start and after each sale)
- **Profit Summary Chart**: Visual profit analysis with daily (last 7 days) and weekly (last 4 weeks) views using fl_chart (profit = sales - expenses)
- **Supplier Management**: Track suppliers with contact information and last restock dates

### Technical Features
- **100% Offline-First**: All data stored locally in SQLite database using sqflite
- **Optimistic UI**: Immediate UI updates with local database writes
- **State Management**: Provider pattern for efficient state management
- **Image Compression**: Product photos automatically compressed to <200KB using flutter_image_compress
- **Local Notifications**: Low-stock alerts using flutter_local_notifications
- **Sample Data**: Pre-seeded with sample products and sales for immediate preview

## Tech Stack

### Frontend
- **Framework**: Flutter (Dart) - Latest stable version
- **Language**: Dart
- **Database**: SQLite (via sqflite) for local database storage
- **State Management**: Provider pattern
- **HTTP**: Dio (for future sync capabilities)
- **Connectivity**: connectivity_plus
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **Image Handling**: image_picker + flutter_image_compress
- **Date Formatting**: intl

### Architecture
- **Pattern**: MVC-like (Models, Providers/Screens, Views)
- **Models**: Data models for Product, Sale, Refund, Supplier
- **Database**: SQLite with proper schema, indexes, and migrations
- **Repositories**: Data access layer abstracting database operations
- **Providers**: State management with ChangeNotifier
- **Services**: Notification service, image service, seed data service
- **Screens**: Modular UI components for each feature

### Object-Oriented Programming (OOP)
The application extensively uses OOP principles:

- **Classes and Inheritance**:
  - `StatefulWidget` and `State` for UI components
  - Base models with `toMap()`, `fromMap()`, and `copyWith()` methods
  - Provider classes extending `ChangeNotifier`

- **Encapsulation**:
  - Private fields with public getters/setters
  - State management through providers
  - Database operations abstracted through repositories

- **Models**:
  - `Product` - Product data model with stock management
  - `Sale` - Sale transaction model with payment tracking
  - `Refund` - Refund transaction model with quantity tracking
  - `Supplier` - Supplier information model

- **Providers**:
  - `ProductProvider` - Product state and stock management
  - `SaleProvider` - Sales and profit calculation logic
  - `RefundProvider` - Refund tracking and aggregation
  - `SupplierProvider` - Supplier data management

## Database Schema

```sql
CREATE TABLE products (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  quantity INTEGER NOT NULL DEFAULT 0,
  buy_price REAL NOT NULL,
  sell_price REAL NOT NULL,
  reorder_level INTEGER NOT NULL DEFAULT 5,
  photo_path TEXT,
  supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL,
  refunded_stock INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  qty_sold INTEGER NOT NULL,
  total REAL NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  amount_paid REAL,
  change_given REAL
);

CREATE TABLE refunds (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  sale_id INTEGER NOT NULL REFERENCES sales(id) ON DELETE CASCADE,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  amount REAL NOT NULL,
  reason TEXT NOT NULL,
  refunded_at TEXT DEFAULT CURRENT_TIMESTAMP,
  quantity INTEGER NOT NULL DEFAULT 1
);

CREATE TABLE suppliers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  contact TEXT,
  last_restock_date TEXT
);

CREATE TABLE sync_queue (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  method TEXT NOT NULL,
  endpoint TEXT NOT NULL,
  payload TEXT,
  timestamp TEXT DEFAULT CURRENT_TIMESTAMP,
  retries INTEGER DEFAULT 0
);

CREATE TABLE expenses (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  category TEXT NOT NULL,
  amount REAL NOT NULL,
  description TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
);

CREATE TABLE customers (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  name TEXT NOT NULL,
  contact TEXT,
  address TEXT,
  credit_limit REAL DEFAULT 0,
  current_balance REAL DEFAULT 0
);

CREATE TABLE utang_transactions (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  customer_id INTEGER NOT NULL,
  amount REAL NOT NULL,
  type TEXT NOT NULL,
  notes TEXT,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE CASCADE
);
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.11.5 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 21+)

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd saritrack
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Run the app**
   ```bash
   flutter run
   ```

### Android Permissions

The app requires the following permissions (automatically configured in `android/app/src/main/AndroidManifest.xml`):

- `CAMERA` - For taking product photos
- `READ_EXTERNAL_STORAGE` - For selecting images from gallery
- `WRITE_EXTERNAL_STORAGE` - For saving compressed images
- `POST_NOTIFICATIONS` - For low-stock alerts (Android 13+)

### Running Tests

```bash
flutter test
```

## Usage Guide

### First Launch
- The app automatically seeds sample data (3 products, 2 suppliers, and several sales) on first launch
- You'll see low-stock notifications if any sample products are below their reorder level

### Adding Products
1. Navigate to the **Inventory** tab
2. Tap the **+** floating action button
3. Fill in product details (name, quantity, prices, reorder level)
4. Optionally add a product photo by tapping the photo area
5. Optionally assign a supplier
6. Tap **Add Product**

### Making Sales
1. Navigate to the **Sell** tab
2. Tap product tiles to add them to your cart with quantity picker
3. Select the quantity to add (limited by available stock)
4. View the cart summary at the bottom
5. Tap the cart to view items and remove specific quantities
6. Enter the cash received from the customer
7. The change is automatically calculated
8. Tap **Complete Sale** to finalize

### Viewing Reports
1. Navigate to the **Reports** tab
2. Switch between **Profit Chart** and **Suppliers** using the tabs
3. Toggle between **Daily** and **Weekly** views for profit charts
4. View profit summaries including total profit, average daily profit, and best day

### Managing Suppliers
1. Navigate to the **Reports** tab
2. Select the **Suppliers** tab
3. Tap **+** to add a new supplier
4. Tap on a supplier to edit their details
5. Tap the delete icon to remove a supplier

### Low-Stock Alerts
- Notifications are automatically triggered when:
  - The app starts (checks all products)
  - A sale is completed (checks affected products)
- Products below their reorder level are highlighted in red in the inventory list
- A "Low Stock" badge appears on affected product cards

### Processing Refunds
1. Navigate to the **Refund** tab
2. View sales history with refund status
3. Tap on a sale to process a refund
4. Select the quantity to refund (up to the sold quantity)
5. Enter the reason for the refund
6. Tap **Confirm Refund** to process
7. Refunded stock is automatically added to the product's refunded stock
8. Profit calculations are updated to exclude refunded items

### Re-Selling Refunded Products
1. Navigate to the **Re-Sell** tab
2. View products with refunded stock (marked with "Ref:")
3. Tap a product to add to re-sell cart with quantity picker
4. View refund reasons by tapping the info icon (i)
5. Remove refunded stock by tapping the trash icon
6. Navigate to checkout and complete the re-sale
7. Stock is automatically deducted from refunded stock

### Tracking Expenses
1. Navigate to the **Reports** tab
2. Select the **Expenses** tab
3. Tap the **+** floating action button to add a new expense
4. Select a category (Utilities, Supplies, Rent, Salary, Transportation, Food, Miscellaneous, Others)
5. Enter the amount and optional description
6. Tap **Idagdag** to save the expense
7. View total expenses at the top of the screen
8. Tap on an expense to edit or delete it
9. Profit calculations automatically subtract expenses from sales

### Managing Customers and Utang
1. Navigate to the **Reports** tab
2. Select the **Customers** tab
3. Tap the **+** floating action button to add a new customer
4. Enter name, contact, address, and optional credit limit
5. Tap **Idagdag** to save the customer
6. View customer balance and credit limit on each customer card
7. Tap on a customer to edit their details
8. Tap the **Bayad** button to record a payment for a customer with outstanding balance
9. To record a sale as utang, toggle **Utang (Credit)** in the checkout screen and select a customer
10. The customer's balance will automatically update after the transaction

### Backup and Restore Data
1. Navigate to the **Reports** tab
2. Select the **Backup/Restore** tab
3. To backup: Tap the **I-backup** button to export your database to a JSON file
4. Share the backup file to a safe location (Google Drive, USB, email, etc.)
5. To restore: Tap the **I-restore** button and select a backup JSON file
6. Choose between **Replace** (deletes all existing data and restores from backup) or **Merge** (combines backup with existing data)
7. Wait for the restore process to complete
8. The app will display a success message when done

### Using Expiration Date Tracking
1. Navigate to **Inventory** → Add/Edit product
2. Tap on the **Expiration Date** field to select a date from the date picker
3. This is optional - only for perishable items (canned goods, snacks, beverages, etc.)
4. Products with expiration dates will show status indicators in the Sell tab:
   - **Orange badge**: Expiring soon (within 7 days)
   - **Red badge**: Expired
5. Navigate to **Reports** → **Expiring Products** tab to see all products with expiration dates
6. Products are sorted by expiration date (soonest first)
7. This helps you prioritize selling items that will expire soon to reduce waste

### Using Barcode Scanning
1. Navigate to the **Sell** tab
2. Tap the **barcode scanner icon** (QR code icon) in the app bar
3. Point your camera at a product barcode
4. The app will automatically detect the barcode and add the product to your cart
5. You can still adjust the quantity in the quantity picker dialog
6. If the barcode is not found in your product list, you'll see an error message
7. To add a barcode to a product: Navigate to **Inventory** → Edit product → Enter the barcode in the Barcode field or tap the scan button

### Using CSV/PDF Export
1. Navigate to **Inventory**, **Reports → Sales History**, **Reports → Expenses**, or **Reports → Profit Chart**
2. Tap the **menu icon** (three dots) in the app bar
3. Select **Export as CSV** or **Export as PDF**
4. The app will generate the file and open the share menu
5. Choose how to share: email, messaging apps, save to device, etc.
6. CSV files can be opened in Excel, Google Sheets, or any spreadsheet application
7. PDF files can be opened in any PDF viewer or shared for record-keeping
8. Export includes all current data (respects any filters you've applied)

### Using Discount System
1. Navigate to **Inventory** and tap the **+** button to add a new product or edit an existing one
2. Scroll down to the **Discount (Optional)** section
3. Select a discount type:
   - **Walang Discount**: No discount applied
   - **Percentage (%)**: Discount based on percentage (e.g., 10% off)
   - **Fixed Amount (₱)**: Discount based on fixed amount (e.g., ₱5 off)
4. Enter the discount value:
   - For percentage: Enter the percentage (e.g., 10 for 10%)
   - For fixed amount: Enter the amount in pesos (e.g., 5 for ₱5)
5. Save the product
6. The discounted price will be displayed in red with the original price struck through in the **Sell** tab
7. During checkout, the discounted price will be automatically applied
8. To remove a discount, edit the product and select "Walang Discount"

## Project Structure

```
lib/
├── database/
│   └── database_helper.dart      # SQLite database operations and migrations
├── models/
│   ├── product.dart              # Product data model with stock management
│   ├── sale.dart                 # Sale data model with payment tracking
│   ├── refund.dart               # Refund data model with quantity tracking
│   ├── supplier.dart             # Supplier data model
│   ├── expense.dart              # Expense data model
│   ├── customer.dart             # Customer data model
│   └── utang_transaction.dart    # Utang transaction data model
├── providers/
│   ├── product_provider.dart     # Product state and stock management
│   ├── sale_provider.dart        # Sales and profit calculation logic
│   ├── refund_provider.dart      # Refund tracking and aggregation
│   ├── supplier_provider.dart    # Supplier data management
│   ├── expense_provider.dart     # Expense state management
│   ├── customer_provider.dart    # Customer state management
│   └── utang_transaction_provider.dart # Utang transaction state management
├── repositories/
│   ├── product_repository.dart   # Product data access
│   ├── sale_repository.dart      # Sale data access
│   ├── refund_repository.dart    # Refund data access
│   ├── supplier_repository.dart  # Supplier data access
│   ├── expense_repository.dart   # Expense data access
│   ├── customer_repository.dart  # Customer data access
│   └── utang_transaction_repository.dart # Utang transaction data access
├── screens/
│   ├── home_screen.dart          # Main screen with bottom navigation
│   ├── product_catalog_screen.dart
│   ├── product_form_screen.dart
│   ├── quick_sale_screen.dart    # Sell tab with quantity picker and barcode scanning
│   ├── checkout_screen.dart      # Cart screen with partial removal and utang support
│   ├── resell_screen.dart        # Re-Sell tab for refunded products
│   ├── resell_checkout_screen.dart # Re-Sell cart checkout
│   ├── refund_screen.dart       # Refund management screen
│   ├── sales_history_screen.dart # Sales history viewer
│   ├── expense_screen.dart       # Expense tracking screen
│   ├── customer_screen.dart      # Customer management screen
│   ├── utang_payment_screen.dart # Utang payment recording screen
│   ├── backup_restore_screen.dart # Backup and restore screen
│   ├── barcode_scanner_screen.dart # Barcode scanning screen
│   ├── expiring_products_screen.dart # Expiration date tracking screen
│   ├── profit_chart_screen.dart
│   ├── supplier_list_screen.dart
│   └── supplier_form_screen.dart
├── services/
│   ├── notification_service.dart # Low-stock notifications
│   ├── image_service.dart         # Image picking and compression
│   ├── seed_data_service.dart    # Sample data seeding
│   ├── backup_service.dart       # Database backup and restore
│   └── export_service.dart      # CSV/PDF export functionality
└── main.dart                     # App entry point
```

## Future Enhancements

The app is designed to support future backend integration for:
- Multi-device synchronization
- Cloud backup
- User authentication
- Advanced reporting

The sync_queue table is already in place to support optimistic UI with background sync when a backend is implemented.

## License

This project is created as a demonstration of offline-first mobile app development with Flutter.

## Support

For issues or questions, please refer to the Flutter documentation at https://docs.flutter.dev/
