import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants_shared.dart';

class BarDataPoint {
  final String label;
  final double value;
  final Color? color;

  BarDataPoint({
    required this.label,
    required this.value,
    this.color,
  });
}

class CustomBarChart extends StatelessWidget {
  final List<BarDataPoint> data;
  final double barWidth;
  final bool showGrid;

  const CustomBarChart({
    super.key,
    required this.data,
    this.barWidth = 18.0,
    this.showGrid = false,
  });

  @override
  Widget build(BuildContext context) {
    final double maxVal = data.map((d) => d.value).fold(0.0, (max, v) => v > max ? v : max);
    final double maxY = maxVal == 0 ? 10.0 : (maxVal * 1.15); // Add 15% top padding

    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available', style: TextStyle(color: Colors.grey))),
      );
    }

    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => isDark ? Colors.grey.shade900 : Colors.white,
              tooltipBorder: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                return BarTooltipItem(
                  '${data[groupIndex].label}\n',
                  TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: rod.toY.toStringAsFixed(0),
                      style: TextStyle(
                        color: rod.color,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 36,
                getTitlesWidget: (value, meta) {
                  return Text(
                    value.toInt().toString(),
                    style: const TextStyle(color: Colors.grey, fontSize: 10),
                  );
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < data.length) {
                    return Text(
                      data[index].label,
                      style: const TextStyle(color: Colors.grey, fontSize: 10, fontWeight: FontWeight.bold),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ),
          gridData: FlGridData(
            show: showGrid,
            drawHorizontalLine: true,
            getDrawingHorizontalLine: (value) => FlLine(
              color: isDark ? const Color(0xFF1E1E2E) : const Color(0xFFE2E8F0),
              strokeWidth: 1,
            ),
            drawVerticalLine: false,
          ),
          borderData: FlBorderData(show: false),
          barGroups: List.generate(data.length, (index) {
            final dp = data[index];
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(
                  toY: dp.value,
                  color: dp.color ?? AppConstants.primaryColor,
                  width: barWidth,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: isDark ? const Color(0xFF0F0F1A) : const Color(0xFFF1F5F9),
                  ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
