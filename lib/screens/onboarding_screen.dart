import 'package:flutter/material.dart';
import 'package:liquid_swipe/liquid_swipe.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../app/routes.dart';
import '../theme/neobrutal_theme.dart';
import '../widgets/gradient_button.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _currentPage = 0;
  late LiquidController _liquidController;

  @override
  void initState() {
    super.initState();
    _liquidController = LiquidController();
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      _buildPage(
        color: const Color(0xFF0A0A0F),
        title: 'Master Your Money',
        subtitle: 'Track expenses effortlessly with our neo-brutalist interface designed for speed.',
        icon: Icons.account_balance_wallet_rounded,
        gradient: NeoBrutalTheme.primaryGradient,
      ),
      _buildPage(
        color: const Color(0xFF16161D),
        title: 'Complete Your Goals',
        subtitle: 'Integrated task management helps you stay productive while saving more.',
        icon: Icons.task_alt_rounded,
        gradient: NeoBrutalTheme.secondaryGradient,
      ),
      _buildPage(
        color: const Color(0xFF0A0A0F),
        title: 'Secure & Private',
        subtitle: 'Your data stays on your device. Secured with PIN and biometric protection.',
        icon: Icons.security_rounded,
        gradient: NeoBrutalTheme.vibrantGradient,
        isLast: true,
      ),
    ];

    return Scaffold(
      body: Stack(
        children: [
          LiquidSwipe(
            pages: pages,
            liquidController: _liquidController,
            onPageChangeCallback: (index) {
              setState(() => _currentPage = index);
            },
            ignoreUserGestureWhileAnimating: true,
            enableSideReveal: true,
            slideIconWidget: const Icon(Icons.arrow_back_ios, color: Colors.white),
          ),
          
          Positioned(
            bottom: 40,
            left: 20,
            right: 20,
            child: Column(
              children: [
                AnimatedSmoothIndicator(
                  activeIndex: _currentPage,
                  count: pages.length,
                  effect: ExpandingDotsEffect(
                    activeDotColor: NeoBrutalTheme.primary,
                    dotColor: Colors.white.withValues(alpha: 0.2),
                    dotHeight: 8,
                    dotWidth: 8,
                  ),
                ),
                const SizedBox(height: 32),
                if (_currentPage == pages.length - 1)
                  GradientButton(
                    text: 'GET STARTED',
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, AppRoutes.pinSetup);
                    },
                    colors: const [NeoBrutalTheme.primary, NeoBrutalTheme.accent],
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => _liquidController.jumpToPage(page: pages.length - 1),
                        child: const Text('SKIP', style: TextStyle(color: Colors.white54)),
                      ),
                      TextButton(
                        onPressed: () => _liquidController.animateToPage(page: _currentPage + 1),
                        child: const Text('NEXT', style: TextStyle(color: NeoBrutalTheme.primary, fontWeight: FontWeight.bold)),
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

  Widget _buildPage({
    required Color color,
    required String title,
    required String subtitle,
    required IconData icon,
    required LinearGradient gradient,
    bool isLast = false,
  }) {
    return Container(
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: gradient,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: gradient.colors.first.withValues(alpha: 0.3),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, size: 80, color: Colors.white),
          ),
          const SizedBox(height: 60),
          Text(
            title,
            textAlign: TextAlign.center,
            style: NeoBrutalTheme.textTheme.displaySmall?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.6),
              fontSize: 16,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
