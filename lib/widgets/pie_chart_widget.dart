import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoryPieData {
  final String name;
  final double value;
  final Color color;

  CategoryPieData({
    required this.name,
    required this.value,
    required this.color,
  });
}

class CategoryPieChart extends StatefulWidget {
  final List<CategoryPieData> data;
  final double centerValue;
  final String centerLabel;

  const CategoryPieChart({
    super.key,
    required this.data,
    this.centerValue = 0,
    this.centerLabel = '',
  });

  @override
  State<CategoryPieChart> createState() => _CategoryPieChartState();
}

class _CategoryPieChartState extends State<CategoryPieChart> {
  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    final double total = widget.data.fold(0.0, (sum, item) => sum + item.value);

    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(child: Text('No data available', style: TextStyle(color: Colors.grey))),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Stack(
            children: [
              PieChart(
                PieChartData(
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      setState(() {
                        if (!event.isInterestedForInteractions ||
                            pieTouchResponse == null ||
                            pieTouchResponse.touchedSection == null) {
                          _touchedIndex = -1;
                          return;
                        }
                        _touchedIndex = pieTouchResponse.touchedSection!.touchedSectionIndex;
                      });
                    },
                  ),
                  borderData: FlBorderData(show: false),
                  sectionsSpace: 2,
                  centerSpaceRadius: 55,
                  sections: List.generate(widget.data.length, (i) {
                    final isTouched = i == _touchedIndex;
                    final fontSize = isTouched ? 16.0 : 12.0;
                    final radius = isTouched ? 30.0 : 22.0;
                    final item = widget.data[i];
                    final pct = (item.value / total) * 100;

                    return PieChartSectionData(
                      color: item.color,
                      value: item.value,
                      title: pct >= 5 ? '${pct.toStringAsFixed(0)}%' : '',
                      radius: radius,
                      titleStyle: TextStyle(
                        fontSize: fontSize,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: const [
                          Shadow(color: Colors.black45, blurRadius: 2)
                        ],
                      ),
                    );
                  }),
                ),
              ),
              if (widget.centerLabel.isNotEmpty)
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.centerLabel,
                        style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.centerValue.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Legend grid
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: widget.data.map((item) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: item.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  item.name,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}
