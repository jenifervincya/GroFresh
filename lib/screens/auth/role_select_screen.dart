import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import 'register_screen.dart';

/// First screen a new user sees — choose farmer (seller) or buyer before
/// registering. Feeds the 'role' field required by ApiService.registerUser.
class RoleSelectScreen extends StatelessWidget {
  const RoleSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SizedBox(height: 16),
            GradientContainer(
              padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: const BoxDecoration(color: Colors.white24, shape: BoxShape.circle),
                    child: const Icon(Icons.eco, size: 34, color: Colors.white),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'GroFresh',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 30, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: -0.5),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Fair prices. Verified delivery.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white70, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text('I am a...', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.agriculture,
              title: 'Farmer / Seller',
              subtitle: 'List produce and get fair bids',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen(role: 'farmer')),
              ),
            ),
            const SizedBox(height: 12),
            _RoleCard(
              icon: Icons.storefront,
              title: 'Buyer',
              subtitle: 'Browse and bid on fresh batches',
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const RegisterScreen(role: 'buyer')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  gradient: AppColors.heroGradient,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.textDark)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: AppColors.accentSoft, shape: BoxShape.circle),
                child: const Icon(Icons.chevron_right, color: AppColors.accent, size: 20),
              ),
            ],
          ),
        ),
      ),
    );
  }
}