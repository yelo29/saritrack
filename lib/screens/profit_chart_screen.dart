import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';
import '../providers/sale_provider.dart';
import 'package:intl/intl.dart';

class ProfitChartScreen extends StatefulWidget {
  const ProfitChartScreen({super.key});

  @override
  State<ProfitChartScreen> createState() => _ProfitChartScreenState();
}

class _ProfitChartScreenState extends State<ProfitChartScreen> {
  bool _isDailyView = true;
  Map<String, double> _profitData = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadProfitData();
  }

  Future<void> _loadProfitData() async {
    setState(() {
      _isLoading = true;
    });

    final saleProvider = context.read<SaleProvider>();
    
    if (_isDailyView) {
      _profitData = await saleProvider.getDailyProfit(7);
    } else {
      // For weekly view, aggregate by week
      final dailyData = await saleProvider.getDailyProfit(28);
      _profitData = _aggregateByWeek(dailyData);
    }

    setState(() {
      _isLoading = false;
    });
  }

  Map<String, double> _aggregateByWeek(Map<String, double> dailyData) {
    final Map<String, double> weeklyData = {};
    final Map<int, List<double>> weekGroups = {};
    
    dailyData.forEach((dateStr, profit) {
      try {
        final date = DateTime.parse(dateStr);
        final weekNumber = _getWeekNumber(date);
        weekGroups.putIfAbsent(weekNumber, () => []).add(profit);
      } catch (e) {
        // Skip invalid dates
      }
    });
    
    weekGroups.forEach((weekNumber, profits) {
      final totalProfit = profits.reduce((a, b) => a + b);
      weeklyData['Week $weekNumber'] = totalProfit;
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
        title: const Text('Profit Summary'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Control buttons row
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () async {
                    await context.read<SaleProvider>().loadSales();
                    _loadProfitData();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Na-refresh na ang analitika')),
                    );
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('I-refresh'),
                ),
                TextButton.icon(
                  onPressed: () async {
                    // Confirm before deleting all sales
                    final confirmed = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('I-reset ang Analitika'),
                        content: const Text('Sigurado ka bang gusto mong burahin lahat ng sales data? Hindi na ito maibabalik.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Kanselahin'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Burahin Lahat', style: TextStyle(color: Colors.red)),
                          ),
                        ],
                      ),
                    );
                    
                    if (confirmed == true) {
                      await context.read<SaleProvider>().deleteAllSales();
                      setState(() {
                        _profitData = {};
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Nabura na ang lahat ng sales data')),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.analytics),
                  label: const Text('I-reset ang Analitika'),
                ),
              ],
            ),
          ),
          // Daily/Weekly toggle
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(
                  value: true,
                  label: Text('Daily'),
                  icon: Icon(Icons.calendar_today),
                ),
                ButtonSegment(
                  value: false,
                  label: Text('Weekly'),
                  icon: Icon(Icons.date_range),
                ),
              ],
              selected: {_isDailyView},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isDailyView = newSelection.first;
                  _loadProfitData();
                });
              },
            ),
          ),
          const SizedBox(height: 16),
          // Chart and summary
          Expanded(
            child: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _profitData.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.show_chart,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Wala pang sales data',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              Text(
                                _isDailyView ? 'Last 7 Days' : 'Last 4 Weeks',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                height: 300,
                                child: BarChart(
                                  BarChartData(
                                    alignment: BarChartAlignment.spaceAround,
                                    maxY: _getMaxProfit() * 1.2,
                                    minY: 0,
                                    baselineY: 0,
                                    barGroups: _buildBarGroups(),
                                    gridData: FlGridData(
                                      show: true,
                                      drawVerticalLine: false,
                                      horizontalInterval: _getMaxProfit() > 0 ? _getMaxProfit() / 5 : 100,
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
                                                child: Text(
                                                  _formatDate(keys[index]),
                                                  style: const TextStyle(fontSize: 10),
                                                ),
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
                                            if (value == meta.max || value == meta.min) {
                                              return const SizedBox.shrink();
                                            }
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 8),
                                              child: Text(
                                                '₱${value.toInt()}',
                                                style: const TextStyle(fontSize: 10),
                                              ),
                                            );
                                          },
                                          reservedSize: 40,
                                        ),
                                      ),
                                      topTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
                                      rightTitles: const AxisTitles(
                                        sideTitles: SideTitles(showTitles: false),
                                      ),
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
                                            const TextStyle(color: Colors.white),
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
                      ),
                      const SizedBox(height: 16),
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Summary',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildSummaryRow('Total Profit', _getTotalProfit()),
                              _buildSummaryRow('Average Daily Profit', _getAverageProfit()),
                              _buildSummaryRow('Best Day', _getBestDay()),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
          ),
        ],
      ),
    );
  }

  List<BarChartGroupData> _buildBarGroups() {
    final entries = _profitData.entries.toList();
    return List.generate(
      entries.length,
      (index) => BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(
            toY: entries[index].value,
            color: Theme.of(context).colorScheme.primary,
            width: 16,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(4),
              topRight: Radius.circular(4),
            ),
          ),
        ],
      ),
    );
  }

  double _getMaxProfit() {
    if (_profitData.isEmpty) return 100;
    return _profitData.values.reduce((a, b) => a > b ? a : b);
  }

  double _getTotalProfit() {
    return _profitData.values.fold(0, (sum, value) => sum + value);
  }

  double _getAverageProfit() {
    if (_profitData.isEmpty) return 0;
    return _getTotalProfit() / _profitData.length;
  }

  String _getBestDay() {
    if (_profitData.isEmpty) return 'N/A';
    final entry = _profitData.entries.reduce((a, b) => a.value > b.value ? a : b);
    return '${_formatDate(entry.key)} (₱${entry.value.toStringAsFixed(2)})';
  }

  String _formatDate(String dateStr) {
    try {
      if (_isDailyView) {
        final date = DateTime.parse(dateStr);
        return DateFormat('MM/dd').format(date);
      } else {
        // For weekly view, the key is already formatted as "Week X"
        return dateStr;
      }
    } catch (e) {
      return dateStr;
    }
  }

  Widget _buildSummaryRow(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value is String ? value : '₱${(value as double).toStringAsFixed(2)}',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
