import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../utils/constants_shared.dart';

class LineDataPoint {
  final double x; // e.g. month index (1-12) or day of week
  final double y; // value
  final String label;

  LineDataPoint({
    required this.x,
    required this.y,
    required this.label,
  });
}

class CustomLineChart extends StatelessWidget {
  final List<LineDataPoint> line1Data;
  final List<LineDataPoint>? line2Data;
  final String line1Name;
  final String? line2Name;
  final Color line1Color;
  final Color line2Color;

  const CustomLineChart({
    super.key,
    required this.line1Data,
    this.line2Data,
    required this.line1Name,
    this.line2Name,
    this.line1Color = AppConstants.primaryColor,
    this.line2Color = AppConstants.secondaryColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (line1Data.isEmpty) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available', style: TextStyle(color: Colors.grey))),
      );
    }

    // Determine max values to scale chart nicely
    final allY = [...line1Data.map((d) => d.y), ...?line2Data?.map((d) => d.y)];
    final double maxVal = allY.fold(0.0, (max, v) => v > max ? v : max);
    final double maxY = maxVal == 0 ? 10.0 : (maxVal * 1.2);

    final spots1 = line1Data.map((dp) => FlSpot(dp.x, dp.y)).toList();
    final spots2 = line2Data?.map((dp) => FlSpot(dp.x, dp.y)).toList();

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: LineChart(
            LineChartData(
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                  strokeWidth: 1,
                ),
              ),
              titlesData: FlTitlesData(
                show: true,
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        meta: meta,
                        child: Text(
                          value.toInt().toString(),
                          style: const TextStyle(color: Colors.grey, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      // Find matching label
                      final match = line1Data.firstWhere(
                        (dp) => dp.x.toInt() == value.toInt(),
                        orElse: () => LineDataPoint(x: value, y: 0, label: ''),
                      );
                      if (match.label.isNotEmpty) {
                        return Text(
                          match.label,
                          style: const TextStyle(color: Colors.grey, fontSize: 9, fontWeight: FontWeight.bold),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  getTooltipColor: (_) => isDark ? Colors.grey.shade900 : Colors.white,
                  tooltipBorder: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
              lineBarsData: [
                // Line 1
                LineChartBarData(
                  spots: spots1,
                  isCurved: true,
                  color: line1Color,
                  barWidth: 4,
                  isStrokeCapRound: true,
                  dotData: const FlDotData(show: true),
                  belowBarData: BarAreaData(
                    show: true,
                    color: line1Color.withValues(alpha: 0.1),
                  ),
                ),
                // Line 2 (Optional)
                if (spots2 != null)
                  LineChartBarData(
                    spots: spots2,
                    isCurved: true,
                    color: line2Color,
                    barWidth: 4,
                    isStrokeCapRound: true,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: line2Color.withValues(alpha: 0.1),
                    ),
                  ),
              ],
            ),
          ),
        ),
        
        // Legends
        if (line2Name != null) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLegend(line1Name, line1Color),
              const SizedBox(width: 24),
              _buildLegend(line2Name!, line2Color),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildLegend(String name, Color color) {
    return Row(
      children: [
        Container(
          width: 14,
          height: 4,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          name,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// Extension to avoid compilation error on shade850 (which doesn't exist on all platforms)
extension on ColorScheme {
  // Simple helper fallback
}
extension on Colors {
  // Empty
}
extension on Color {
  // Empty
}

// Custom helper to get a shade of slate
extension SlateTheme on ThemeData {
  // Empty
}

extension SlateColor on Colors {
  // Empty
}

// Let's replace shade850 with simple Color definition to be clean
extension SlateHelper on BuildContext {
  // Empty
}
// We will write Colors.slate.shade800 or similar instead. Let's fix the compile-safety below
