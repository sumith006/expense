import 'package:flutter/material.dart';
import '../theme/neobrutal_theme.dart';
import '../app/routes.dart';

class AnimatedBottomNav extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemTapped;
  
  const AnimatedBottomNav({
    super.key,
    required this.selectedIndex,
    required this.onItemTapped,
  });

  @override
  State<AnimatedBottomNav> createState() => _AnimatedBottomNavState();
}

class _AnimatedBottomNavState extends State<AnimatedBottomNav>
    with SingleTickerProviderStateMixin {
  
  final List<Map<String, dynamic>> _items = [
    {'icon': Icons.home_rounded, 'label': 'HOME', 'route': AppRoutes.neobrutalDashboard},
    {'icon': Icons.receipt_long_rounded, 'label': 'RECORDS', 'route': AppRoutes.neobrutalExpense},
    {'icon': Icons.add_circle_outline, 'label': ''},
    {'icon': Icons.task_alt_rounded, 'label': 'TASKS', 'route': AppRoutes.neobrutalTask},
    {'icon': Icons.person_rounded, 'label': 'PROFILE', 'route': AppRoutes.neobrutalProfile},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      height: 70,
      decoration: BoxDecoration(
        color: NeoBrutalTheme.surface,
        borderRadius: NeoBrutalTheme.radiusLarge,
        border: Border.all(color: Colors.white.withValues(alpha: 0.05), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(_items.length, (index) {
          final item = _items[index];
          final isSelected = widget.selectedIndex == index;
          
          if (index == 2) {
            return const SizedBox(width: 48); // Space for FAB
          }
          
          return GestureDetector(
            onTap: () {
              widget.onItemTapped(index);
              if (!isSelected) {
                Navigator.pushNamed(context, item['route'] as String);
              }
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? NeoBrutalTheme.primary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: NeoBrutalTheme.radiusMedium,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    item['icon'] as IconData,
                    color: isSelected ? NeoBrutalTheme.primary : Colors.white24,
                    size: 24,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item['label'] as String,
                    style: TextStyle(
                      color: isSelected ? NeoBrutalTheme.primary : Colors.white24,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}
