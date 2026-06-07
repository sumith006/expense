import 'package:flutter/material.dart';
import '../theme/banking_theme.dart';
import '../widgets/banking_glass_card.dart';
import '../widgets/quick_action_button.dart';
import '../widgets/banking_transaction_item.dart';
import '../widgets/card_carousel.dart';
import '../widgets/floating_bottom_nav.dart';

class BankingDashboardScreen extends StatefulWidget {
  const BankingDashboardScreen({super.key});

  @override
  State<BankingDashboardScreen> createState() => _BankingDashboardScreenState();
}

class _BankingDashboardScreenState extends State<BankingDashboardScreen> {
  int _selectedNavIndex = 0;
  // ignore: unused_field
  double _totalBalance = 12450.50;
  
  final List<Map<String, dynamic>> _cards = [
    {
      'bank': 'Main Account',
      'cardNumber': '**** 4532',
      'balance': 12450.50,
      'color1': const Color(0xFF6C63FF),
      'color2': const Color(0xFF3B82F6),
      'chipIcon': Icons.credit_card,
    },
    {
      'bank': 'Savings',
      'cardNumber': '**** 7890',
      'balance': 8500.00,
      'color1': const Color(0xFF8B5CF6),
      'color2': const Color(0xFF06B6D4),
      'chipIcon': Icons.savings,
    },
    {
      'bank': 'Business',
      'cardNumber': '**** 1122',
      'balance': 3250.75,
      'color1': const Color(0xFFEC4899),
      'color2': const Color(0xFFF43F5E),
      'chipIcon': Icons.business_center,
    },
  ];
  
  final List<Map<String, dynamic>> _transactions = [
    {
      'title': 'Grocery Shopping',
      'subtitle': 'Food • 2 hours ago',
      'amount': 45.50,
      'icon': Icons.shopping_bag,
      'iconColor': const Color(0xFF10B981),
      'isExpense': true,
    },
    {
      'title': 'Salary Deposit',
      'subtitle': 'Income • Yesterday',
      'amount': 3200.00,
      'icon': Icons.work,
      'iconColor': const Color(0xFF6C63FF),
      'isExpense': false,
    },
    {
      'title': 'Netflix Subscription',
      'subtitle': 'Bills • 2 days ago',
      'amount': 15.99,
      'icon': Icons.movie,
      'iconColor': const Color(0xFFEC4899),
      'isExpense': true,
    },
    {
      'title': 'Uber Ride',
      'subtitle': 'Travel • 3 days ago',
      'amount': 25.00,
      'icon': Icons.car_rental,
      'iconColor': const Color(0xFF06B6D4),
      'isExpense': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: BankingTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(),
            
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Card Carousel
                    CardCarousel(
                      cards: _cards,
                      onCardChanged: (index) {
                        setState(() {
                          _totalBalance = _cards[index]['balance'];
                        });
                      },
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Quick Actions
                    _buildQuickActions(),
                    
                    const SizedBox(height: 24),
                    
                    // Today's Tasks Section
                    _buildTasksSection(),
                    
                    const SizedBox(height: 24),
                    
                    // Recent Transactions
                    _buildRecentTransactions(),
                    
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: _buildFloatingButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: FloatingBottomNav(
        selectedIndex: _selectedNavIndex,
        onItemTapped: (index) {
          setState(() {
            _selectedNavIndex = index;
          });
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Good ${_getTimeOfDay()},',
                style: BankingTheme.textTheme.bodyMedium?.copyWith(
                  color: BankingTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'John Anderson',
                style: BankingTheme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          Container(
            decoration: BoxDecoration(
              color: BankingTheme.surface,
              shape: BoxShape.circle,
              boxShadow: BankingTheme.cardShadow,
            ),
            child: IconButton(
              onPressed: () {},
              icon: const Icon(Icons.notifications_none),
              color: BankingTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      {'icon': Icons.send, 'label': 'Transfer', 'color': BankingTheme.primary},
      {'icon': Icons.receipt, 'label': 'Bills', 'color': BankingTheme.secondary},
      {'icon': Icons.add_card, 'label': 'Top Up', 'color': BankingTheme.success},
      {'icon': Icons.price_check, 'label': 'Withdraw', 'color': BankingTheme.warning},
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((action) {
          return QuickActionButton(
            icon: action['icon'] as IconData,
            label: action['label'] as String,
            color: action['color'] as Color,
            onTap: () {
              // Handle action
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTasksSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Today\'s Tasks',
                style: BankingTheme.textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BankingGlassCard(
            onTap: () {},
            child: Column(
              children: [
                _buildTaskItem('Complete project report', 'High', '6:00 PM'),
                const Divider(),
                _buildTaskItem('Buy groceries', 'Medium', '8:00 PM'),
                const Divider(),
                _buildTaskItem('Call dentist', 'Low', 'Tomorrow'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(String title, String priority, String dueTime) {
    Color priorityColor;
    switch (priority) {
      case 'High':
        priorityColor = BankingTheme.error;
        break;
      case 'Medium':
        priorityColor = BankingTheme.warning;
        break;
      default:
        priorityColor = BankingTheme.success;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Transform.scale(
            scale: 1.2,
            child: Checkbox(
              value: false,
              onChanged: (val) {},
              shape: const RoundedRectangleBorder(
                borderRadius: BankingTheme.borderRadiusSmall,
              ),
              activeColor: BankingTheme.success,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: BankingTheme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: priorityColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      priority,
                      style: BankingTheme.textTheme.labelSmall?.copyWith(
                        color: BankingTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.access_time, size: 12, color: BankingTheme.textTertiary),
                    const SizedBox(width: 4),
                    Text(
                      dueTime,
                      style: BankingTheme.textTheme.labelSmall?.copyWith(
                        color: BankingTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Transactions',
                style: BankingTheme.textTheme.headlineSmall,
              ),
              TextButton(
                onPressed: () {},
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          BankingGlassCard(
            child: Column(
              children: _transactions.map((tx) {
                return BankingTransactionItem(
                  title: tx['title'] as String,
                  subtitle: tx['subtitle'] as String,
                  amount: tx['amount'] as double,
                  icon: tx['icon'] as IconData,
                  iconColor: tx['iconColor'] as Color,
                  isExpense: tx['isExpense'] as bool,
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingButton() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        gradient: BankingTheme.primaryGradient,
        shape: BoxShape.circle,
        boxShadow: BankingTheme.floatingShadow,
      ),
      child: FloatingActionButton(
        onPressed: () {},
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: const Icon(Icons.add, color: Colors.white, size: 28),
      ),
    );
  }

  String _getTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Morning';
    if (hour < 17) return 'Afternoon';
    return 'Evening';
  }
}
