import 'package:flutter/material.dart';
import '../theme/banking_theme.dart';

class CardCarousel extends StatefulWidget {
  final List<Map<String, dynamic>> cards;
  final Function(int) onCardChanged;
  
  const CardCarousel({
    super.key,
    required this.cards,
    required this.onCardChanged,
  });

  @override
  State<CardCarousel> createState() => _CardCarouselState();
}

class _CardCarouselState extends State<CardCarousel> {
  final PageController _pageController = PageController(
    viewportFraction: 0.85,
  );
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController.addListener(() {
      final page = _pageController.page?.round() ?? 0;
      if (_currentPage != page) {
        setState(() => _currentPage = page);
        widget.onCardChanged(page);
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 220,
          child: PageView.builder(
            controller: _pageController,
            itemCount: widget.cards.length,
            itemBuilder: (context, index) {
              final card = widget.cards[index];
              final isSelected = _currentPage == index;
              
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 8),
                transform: Matrix4.identity()
                  ..scale(isSelected ? 1.0 : 0.95),
                child: _buildCard(card),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.cards.length,
            (index) => AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: _currentPage == index ? 24 : 8,
              height: 8,
              decoration: BoxDecoration(
                borderRadius: BankingTheme.borderRadiusSmall,
                color: _currentPage == index
                    ? BankingTheme.primary
                    : BankingTheme.border,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCard(Map<String, dynamic> card) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            card['color1'] ?? BankingTheme.primary,
            card['color2'] ?? BankingTheme.secondary,
          ],
        ),
        borderRadius: BankingTheme.borderRadiusXXLarge,
        boxShadow: BankingTheme.cardShadow,
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                card['bank'] ?? 'Bank Card',
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Icon(card['chipIcon'] ?? Icons.credit_card, color: Colors.white70),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            card['cardNumber'] ?? '**** **** **** 1234',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              letterSpacing: 2,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'BALANCE',
                    style: TextStyle(color: Colors.white70, fontSize: 10),
                  ),
                  Text(
                    '\$${card['balance']?.toStringAsFixed(2) ?? '0.00'}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BankingTheme.borderRadiusMedium,
                ),
                child: const Icon(Icons.more_horiz, color: Colors.white),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
