import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/weight_log.dart';
import '../models/user_profile.dart';
import 'package:intl/intl.dart';

class WeightProgressChart extends StatelessWidget {
  final List<WeightLog> weightLogs;
  final UserProfile? userProfile;

  const WeightProgressChart({
    Key? key,
    required this.weightLogs,
    this.userProfile,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (weightLogs.isEmpty) {
      return _buildEmptyState(context);
    }

    // Sortiere Logs nach Datum (älteste zuerst für Chart)
    final sortedLogs = List<WeightLog>.from(weightLogs)
      ..sort((a, b) => a.timestamp.compareTo(b.timestamp));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gewichtsentwicklung',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                _buildLegend(context),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 250,
              child: LineChart(
                _buildLineChartData(context, sortedLogs),
              ),
            ),
            const SizedBox(height: 16),
            _buildStats(context, sortedLogs),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          children: [
            Icon(
              Icons.show_chart,
              size: 64,
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Keine Gewichtsdaten',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Füge in den Einstellungen dein\naktuelles Gewicht hinzu, um den\nFortschritt zu verfolgen.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegend(BuildContext context) {
    return Row(
      children: [
        _buildLegendItem(context, Colors.green, 'Aktuell'),
        const SizedBox(width: 16),
        if (userProfile?.targetWeight != null)
          _buildLegendItem(context, Colors.orange, 'Ziel'),
      ],
    );
  }

  Widget _buildLegendItem(BuildContext context, Color color, String label) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  LineChartData _buildLineChartData(BuildContext context, List<WeightLog> sortedLogs) {
    final spots = sortedLogs.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.weight);
    }).toList();

    // Min und Max Gewicht für Y-Achse
    final weights = sortedLogs.map((log) => log.weight).toList();
    if (userProfile?.targetWeight != null) {
      weights.add(userProfile!.targetWeight!);
    }
    
    final minWeight = weights.reduce((a, b) => a < b ? a : b);
    final maxWeight = weights.reduce((a, b) => a > b ? a : b);
    final padding = (maxWeight - minWeight) * 0.1;

    return LineChartData(
      gridData: FlGridData(
        show: true,
        drawVerticalLine: true,
        horizontalInterval: 5,
        getDrawingHorizontalLine: (value) {
          return FlLine(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
        getDrawingVerticalLine: (value) {
          return FlLine(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            strokeWidth: 1,
          );
        },
      ),
      titlesData: FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            interval: 1,
            getTitlesWidget: (value, meta) {
              if (value.toInt() >= sortedLogs.length) {
                return const Text('');
              }
              final log = sortedLogs[value.toInt()];
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  DateFormat('dd.MM').format(log.timestamp),
                  style: const TextStyle(fontSize: 10),
                ),
              );
            },
          ),
        ),
        leftTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 42,
            interval: 5,
            getTitlesWidget: (value, meta) {
              return Text(
                '${value.toStringAsFixed(0)} kg',
                style: const TextStyle(fontSize: 10),
              );
            },
          ),
        ),
        rightTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      ),
      borderData: FlBorderData(
        show: true,
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
        ),
      ),
      minX: 0,
      maxX: (sortedLogs.length - 1).toDouble(),
      minY: (minWeight - padding).clamp(0, double.infinity),
      maxY: maxWeight + padding,
      lineBarsData: [
        // Gewichtsverlauf
        LineChartBarData(
          spots: spots,
          isCurved: true,
          color: Colors.green,
          barWidth: 3,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: true,
            getDotPainter: (spot, percent, barData, index) {
              return FlDotCirclePainter(
                radius: 4,
                color: Colors.green,
                strokeWidth: 2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(
            show: true,
            color: Colors.green.withOpacity(0.1),
          ),
        ),
        // Zielgewicht Linie
        if (userProfile?.targetWeight != null)
          LineChartBarData(
            spots: [
              FlSpot(0, userProfile!.targetWeight!),
              FlSpot((sortedLogs.length - 1).toDouble(), userProfile!.targetWeight!),
            ],
            isCurved: false,
            color: Colors.orange,
            barWidth: 2,
            dashArray: [5, 5],
            dotData: FlDotData(show: false),
          ),
      ],
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipItems: (touchedSpots) {
            return touchedSpots.map((spot) {
              if (spot.barIndex == 0) {
                final log = sortedLogs[spot.x.toInt()];
                return LineTooltipItem(
                  '${DateFormat('dd.MM.yy').format(log.timestamp)}\n${log.weight.toStringAsFixed(1)} kg',
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }
              return null;
            }).toList();
          },
        ),
      ),
    );
  }

  Widget _buildStats(BuildContext context, List<WeightLog> sortedLogs) {
    final latestWeight = sortedLogs.last.weight;
    final firstWeight = sortedLogs.first.weight;
    final weightChange = latestWeight - firstWeight;
    final isLoss = weightChange < 0;

    final daysSinceStart = DateTime.now().difference(sortedLogs.first.timestamp).inDays;
    final weeklyChange = daysSinceStart > 0 
        ? (weightChange / daysSinceStart * 7) 
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
                context,
                'Aktuell',
                '${latestWeight.toStringAsFixed(1)} kg',
                Icons.monitor_weight,
              ),
              _buildStatItem(
                context,
                'Veränderung',
                '${isLoss ? '' : '+'}${weightChange.toStringAsFixed(1)} kg',
                isLoss ? Icons.trending_down : Icons.trending_up,
                color: isLoss ? Colors.green : Colors.orange,
              ),
              _buildStatItem(
                context,
                'Ø pro Woche',
                '${weeklyChange < 0 ? '' : '+'}${weeklyChange.toStringAsFixed(2)} kg',
                Icons.speed,
              ),
            ],
          ),
          if (userProfile?.targetWeight != null) ...[
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  context,
                  'Zielgewicht',
                  '${userProfile!.targetWeight!.toStringAsFixed(1)} kg',
                  Icons.flag,
                ),
                _buildStatItem(
                  context,
                  'Noch zu gehen',
                  '${(userProfile!.targetWeight! - latestWeight).abs().toStringAsFixed(1)} kg',
                  Icons.route,
                ),
                _buildStatItem(
                  context,
                  'Fortschritt',
                  '${userProfile!.calculateWeightProgress()?.toStringAsFixed(0) ?? 0}%',
                  Icons.check_circle,
                  color: Colors.green,
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: color ?? Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
