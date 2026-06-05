import 'dart:io';
import 'package:csv/csv.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/expense.dart';

class ExportService {
  // Export products to CSV
  static Future<void> exportProductsToCSV(List<Product> products) async {
    final List<List<dynamic>> rows = [
      ['ID', 'Name', 'Quantity', 'Buy Price', 'Sell Price', 'Reorder Level', 'Barcode', 'Expiration Date'],
    ];

    for (var product in products) {
      rows.add([
        product.id,
        product.name,
        product.quantity,
        product.buyPrice,
        product.sellPrice,
        product.reorderLevel,
        product.barcode ?? 'N/A',
        product.expirationDate ?? 'N/A',
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv, 'products.csv');
  }

  // Export sales to CSV
  static Future<void> exportSalesToCSV(List<Sale> sales, Map<int, String> productNames) async {
    final List<List<dynamic>> rows = [
      ['ID', 'Product Name', 'Quantity Sold', 'Total', 'Created At'],
    ];

    for (var sale in sales) {
      rows.add([
        sale.id,
        productNames[sale.productId] ?? 'Unknown (ID: ${sale.productId})',
        sale.qtySold,
        sale.total,
        sale.createdAt,
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv, 'sales.csv');
  }

  // Export expenses to CSV
  static Future<void> exportExpensesToCSV(List<Expense> expenses) async {
    final List<List<dynamic>> rows = [
      ['ID', 'Category', 'Amount', 'Description', 'Created At'],
    ];

    for (var expense in expenses) {
      rows.add([
        expense.id,
        expense.category,
        expense.amount,
        expense.description ?? 'N/A',
        expense.createdAt,
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rows);
    await _saveAndShareFile(csv, 'expenses.csv');
  }

  // Export products to PDF
  static Future<void> exportProductsToPDF(List<Product> products) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Product Inventory Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(1),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Product Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Barcode', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...products.map((product) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product.name),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product.quantity.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₱${product.sellPrice.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(product.barcode ?? 'N/A'),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );

    final List<int> pdfBytes = await pdf.save();
    await _saveAndShareFile(pdfBytes, 'products.pdf');
  }

  // Export sales to PDF
  static Future<void> exportSalesToPDF(List<Sale> sales, Map<int, String> productNames) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Sales Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(3),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(1),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Product Name', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Quantity', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Total', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...sales.map((sale) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(sale.id?.toString() ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(productNames[sale.productId] ?? 'Unknown (ID: ${sale.productId})'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(sale.qtySold.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₱${sale.total.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(sale.createdAt),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );

    final List<int> pdfBytes = await pdf.save();
    await _saveAndShareFile(pdfBytes, 'sales.pdf');
  }

  // Export expenses to PDF
  static Future<void> exportExpensesToPDF(List<Expense> expenses) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Expense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1),
                  1: const pw.FlexColumnWidth(2),
                  2: const pw.FlexColumnWidth(1),
                  3: const pw.FlexColumnWidth(3),
                  4: const pw.FlexColumnWidth(2),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('ID', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...expenses.map((expense) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(expense.id?.toString() ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(expense.category),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₱${expense.amount.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(expense.description ?? 'N/A'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(expense.createdAt),
                      ),
                    ],
                  )),
                ],
              ),
            ],
          );
        },
      ),
    );

    final List<int> pdfBytes = await pdf.save();
    await _saveAndShareFile(pdfBytes, 'expenses.pdf');
  }

  // Helper method to save and share file
  static Future<void> _saveAndShareFile(dynamic content, String filename) async {
    final directory = await getTemporaryDirectory();
    final path = '${directory.path}/$filename';
    final file = File(path);
    
    if (content is String) {
      await file.writeAsString(content);
    } else {
      await file.writeAsBytes(content);
    }
    
    await Share.shareXFiles([XFile(path)], text: 'Exported $filename');
  }

  // Export profit data to CSV
  static Future<void> exportProfitToCSV(Map<String, double> profitData, bool isDailyView) async {
    final List<List<dynamic>> rows = [
      ['Period', 'Profit'],
    ];

    for (var entry in profitData.entries) {
      rows.add([
        entry.key,
        entry.value,
      ]);
    }

    final String csv = const ListToCsvConverter().convert(rows);
    final filename = isDailyView ? 'profit_daily.csv' : 'profit_weekly.csv';
    await _saveAndShareFile(csv, filename);
  }

  // Export profit data to PDF
  static Future<void> exportProfitToPDF(Map<String, double> profitData, bool isDailyView) async {
    final pdf = pw.Document();
    
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Profit Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text(isDailyView ? 'Last 7 Days' : 'Last 4 Weeks', style: pw.TextStyle(fontSize: 14)),
              pw.SizedBox(height: 20),
              pw.Table(
                border: pw.TableBorder.all(),
                columnWidths: {
                  0: const pw.FlexColumnWidth(2),
                  1: const pw.FlexColumnWidth(1),
                },
                children: [
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColors.grey300),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Period', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('Profit', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  ...profitData.entries.map((entry) => pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(entry.key),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₱${entry.value.toStringAsFixed(2)}'),
                      ),
                    ],
                  )),
                ],
              ),
              pw.SizedBox(height: 20),
              pw.Text('Total Profit: ₱${profitData.values.fold(0.0, (sum, value) => sum + value).toStringAsFixed(2)}', 
                style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            ],
          );
        },
      ),
    );

    final List<int> pdfBytes = await pdf.save();
    final filename = isDailyView ? 'profit_daily.pdf' : 'profit_weekly.pdf';
    await _saveAndShareFile(pdfBytes, filename);
  }
}
