import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sale_provider.dart';
import 'package:intl/intl.dart';
import '../services/export_service.dart';

class ProfitChartScreen extends StatefulWidget {
  const ProfitChartScreen({super.key});

  @override
  State<ProfitChartScreen> createState() => _ProfitChartScreenState();
}

class _ProfitChartScreenState extends State<ProfitChartScreen> with SingleTickerProviderStateMixin {
  bool _isDailyView = true;
  Map<String, double> _profitData = {};
  bool _isLoading = false;
  late AnimationController _animationController;
  int _selectedBarIndex = -1;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..forward();
    _loadProfitData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadProfitData() async {
    setState(() => _isLoading = true);
    final saleProvider = context.read<SaleProvider>();
    _profitData = _isDailyView
        ? await saleProvider.getDailyProfit(7)
        : _aggregateByWeek(await saleProvider.getDailyProfit(28));
    setState(() => _isLoading = false);
  }

  Map<String, double> _aggregateByWeek(Map<String, double> dailyData) {
    final Map<String, double> weeklyData = {};
    final Map<int, List<double>> weekGroups = {};
    dailyData.forEach((dateStr, profit) {
      try {
        final date = DateTime.parse(dateStr);
        final weekNumber = _getWeekNumber(date);
        weekGroups.putIfAbsent(weekNumber, () => []).add(profit);
      } catch (e) {}
    });
    weekGroups.forEach((weekNumber, profits) {
      weeklyData['Week $weekNumber'] = profits.reduce((a, b) => a + b);
    });
    return weeklyData;
  }

  int _getWeekNumber(DateTime date) {
    final firstDayOfYear = DateTime(date.year, 1, 1);
    final dayOfYear = date.difference(firstDayOfYear).inDays;
    return ((dayOfYear / 7).floor() + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profit Summary', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        elevation: 0,
        actions: [
          PopupMenuButton<String>(
            onSelected: (choice) async {
              if (choice == 'csv') await ExportService.exportProfitToCSV(_profitData, _isDailyView);
              else if (choice == 'pdf') await ExportService.exportProfitToPDF(_profitData, _isDailyView);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'csv', child: Row(children: [Icon(Icons.table_chart), SizedBox(width: 8), Text('Export as CSV')])),
              const PopupMenuItem(value: 'pdf', child: Row(children: [Icon(Icons.picture_as_pdf), SizedBox(width: 8), Text('Export as PDF')])),
            ],
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
        child: Column(
          children: [
            _buildControlButtons(),
            _buildViewToggle(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _profitData.isEmpty
                      ? _buildEmptyState()
                      : SingleChildScrollView(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              FadeTransition(
                                opacity: _animationController,
                                child: _buildChartCard(),
                              ),
                              const SizedBox(height: 16),
                              FadeTransition(
                                opacity: _animationController.drive(CurveTween(curve: Curves.easeIn)),
                                child: _buildSummaryCard(),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlButtons() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 400),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * -30),
        child: Opacity(opacity: value, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildActionButton(
              icon: Icons.refresh,
              label: 'I-refresh',
              color: Theme.of(context).colorScheme.primary,
              onPressed: () async {
                await context.read<SaleProvider>().loadSales();
                _loadProfitData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Na-refresh na ang analitika'), behavior: SnackBarBehavior.floating),
                );
              },
            ),
            _buildActionButton(
              icon: Icons.analytics,
              label: 'I-reset',
              color: Colors.red,
              onPressed: () => _showResetDialog(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onPressed}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        child: TextButton.icon(
          onPressed: onPressed,
          icon: Icon(icon, color: color),
          label: Text(label, style: TextStyle(color: color)),
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          ),
        ),
      ),
    );
  }

  Widget _buildViewToggle() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      builder: (context, value, child) => Transform.translate(
        offset: Offset(0, (1 - value) * -20),
        child: Opacity(opacity: value, child: child),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: true, label: Text('Daily'), icon: Icon(Icons.calendar_today)),
            ButtonSegment(value: false, label: Text('Weekly'), icon: Icon(Icons.date_range)),
          ],
          selected: {_isDailyView},
          onSelectionChanged: (Set<bool> newSelection) {
            setState(() {
              _isDailyView = newSelection.first;
              _loadProfitData();
            });
          },
          style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Theme.of(context).colorScheme.primary;
              return Colors.transparent;
            }),
            foregroundColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return Theme.of(context).colorScheme.onSurface;
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 500),
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.show_chart, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('Wala pang sales data', style: TextStyle(fontSize: 18, color: Colors.grey[600])),
            const SizedBox(height: 8),
            Text('Magbenta muna sa Sell tab', style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              _isDailyView ? 'Last 7 Days' : 'Last 4 Weeks',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: _getMaxProfit() * 1.2,
                  minY: 0,
                  barGroups: _buildBarGroups(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (value) => FlLine(color: Colors.grey[300]!, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          final keys = _profitData.keys.toList();
                          if (index >= 0 && index < keys.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(_formatDate(keys[index]), style: const TextStyle(fontSize: 10)),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          if (value == 0 || value == meta.max) return const SizedBox.shrink();
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text('₱${value.toInt()}', style: const TextStyle(fontSize: 10)),
                          );
                        },
                        reservedSize: 40,
                      ),
                    ),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final keys = _profitData.keys.toList();
                        final date = keys[group.x.toInt()];
                        final profit = _profitData[date]!;
                        return BarTooltipItem(
                          '₱${profit.toStringAsFixed(2)}',
                          const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final entries = _profitData.entries.toList();
    return List.generate(entries.length, (index) {
      final isSelected = _selectedBarIndex == index;
      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entries[index].value,
            color: isSelected ? const Color(0xFFC4793A) : Theme.of(context).colorScheme.primary,
            width: 24,
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(6), topRight: Radius.circular(6)),
          ),
        ],
        showingTooltipIndicators: isSelected ? [0] : [],
      );
    });
  }

  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _buildSummaryRow('Total Profit', _getTotalProfit()),
            const Divider(),
            _buildSummaryRow('Total VAT Collected', _getTotalVAT()),
            const Divider(),
            _buildSummaryRow('Average Daily Profit', _getAverageProfit()),
            const Divider(),
            _buildSummaryRow('Best Day', _getBestDay(), isText: true),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, dynamic value, {bool isText = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.0, end: isText ? 1 : value),
            duration: const Duration(milliseconds: 600),
            curve: Curves.easeOutCubic,
            builder: (context, animValue, child) {
              if (isText) return Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold));
              return Text('₱${(animValue as double).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF2D9D6E)));
            },
          ),
        ],
      ),
    );
  }

  double _getMaxProfit() => _profitData.isEmpty ? 100 : _profitData.values.reduce((a, b) => a > b ? a : b);
  double _getTotalProfit() => _profitData.values.fold(0, (sum, v) => sum + v);
  double _getTotalVAT() {
    final saleProvider = context.read<SaleProvider>();
    return saleProvider.sales.fold(0, (sum, sale) => sum + sale.vatAmount);
  }
  double _getAverageProfit() => _profitData.isEmpty ? 0 : _getTotalProfit() / _profitData.length;
  String _getBestDay() {
    if (_profitData.isEmpty) return 'N/A';
    final entry = _profitData.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${_formatDate(entry.key)} (₱${entry.value.toStringAsFixed(2)})';
  }

  String _formatDate(String dateStr) {
    try {
      if (_isDailyView) return DateFormat('MM/dd').format(DateTime.parse(dateStr));
      return dateStr;
    } catch (e) {
      return dateStr;
    }
  }

  void _showResetDialog() {
    showDialog(
      context: context,
      builder: (context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 300),
        curve: Curves.elasticOut,
        builder: (context, value, child) => Transform.scale(scale: value, child: child),
        child: AlertDialog(
          title: const Text('I-reset ang Analitika'),
          content: const Text('Sigurado ka bang gusto mong burahin lahat ng sales data? Hindi na ito maibabalik.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            TextButton(
              onPressed: () async {
                Navigator.pop(context);
                await context.read<SaleProvider>().deleteAllSales();
                setState(() => _profitData = {});
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Nabura na ang lahat ng sales data'), backgroundColor: Colors.red),
                  );
                }
              },
              child: const Text('Burahin Lahat', style: TextStyle(color: Colors.red)),
            ),
          ],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }
}