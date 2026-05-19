# SariTrack

An offline-first inventory and sales tracker mobile application designed for Filipino sari-sari store owners. SariTrack helps store owners manage their products, track sales, monitor stock levels, and analyze profits - all without requiring an internet connection.

## Features

### Core Functionality
- **Product Catalog**: Add, edit, and delete products with name, quantity, buying price, selling price, reorder level, and optional product photos
- **Quick Sale Screen**: Fast point-of-sale interface with product tiles in a grid layout, cart functionality, and automatic stock deduction
- **Low-Stock Alerts**: Automatic notifications when products fall below their reorder level (both on app start and after each sale)
- **Profit Summary Chart**: Visual profit analysis with daily (last 7 days) and weekly (last 4 weeks) views using fl_chart
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
- **Flutter**: Latest stable version
- **SQLite**: sqflite for local database storage
- **State Management**: Provider
- **HTTP**: Dio (for future sync capabilities)
- **Connectivity**: connectivity_plus
- **Notifications**: flutter_local_notifications
- **Charts**: fl_chart
- **Image Handling**: image_picker + flutter_image_compress
- **Date Formatting**: intl

### Architecture
- **Models**: Data models for Product, Sale, Supplier, SyncQueue
- **Database**: SQLite with proper schema and indexes
- **Repositories**: Data access layer abstracting database operations
- **Providers**: State management with ChangeNotifier
- **Services**: Notification service, image service, seed data service
- **Screens**: Modular UI components for each feature

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
  supplier_id INTEGER REFERENCES suppliers(id) ON DELETE SET NULL
);

CREATE TABLE sales (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id INTEGER NOT NULL REFERENCES products(id) ON DELETE CASCADE,
  qty_sold INTEGER NOT NULL,
  total REAL NOT NULL,
  created_at TEXT DEFAULT CURRENT_TIMESTAMP
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
```

## Setup Instructions

### Prerequisites
- Flutter SDK (3.11.5 or higher)
- Android Studio / VS Code with Flutter extension
- Android device or emulator (API 21+)

### Installation

1. **Clone or navigate to the project directory**
   ```bash
   cd mobile_app_test_ideas
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
2. Tap product tiles to add them to your cart
3. View the cart summary at the bottom
4. Enter the cash received from the customer
5. The change is automatically calculated
6. Tap **Complete Sale** to finalize

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

## Project Structure

```
lib/
├── database/
│   └── database_helper.dart      # SQLite database operations
├── models/
│   ├── product.dart              # Product data model
│   ├── sale.dart                 # Sale data model
│   ├── supplier.dart             # Supplier data model
│   └── sync_queue.dart           # Sync queue data model
├── providers/
│   ├── product_provider.dart     # Product state management
│   ├── sale_provider.dart        # Sale state management
│   └── supplier_provider.dart    # Supplier state management
├── repositories/
│   ├── product_repository.dart   # Product data access
│   ├── sale_repository.dart      # Sale data access
│   └── supplier_repository.dart  # Supplier data access
├── screens/
│   ├── home_screen.dart          # Main screen with bottom navigation
│   ├── product_catalog_screen.dart
│   ├── product_form_screen.dart
│   ├── quick_sale_screen.dart
│   ├── profit_chart_screen.dart
│   ├── supplier_list_screen.dart
│   └── supplier_form_screen.dart
├── services/
│   ├── notification_service.dart # Low-stock notifications
│   ├── image_service.dart         # Image picking and compression
│   └── seed_data_service.dart    # Sample data seeding
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
