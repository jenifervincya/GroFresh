import 'package:flutter/material.dart';
import 'screens/auth/role_select_screen.dart';
import 'screens/buyer/buyer_home_screen.dart';
import 'screens/seller/seller_dashboard_screen.dart';
import 'services/auth_session.dart';
import 'core/theme/app_theme.dart';

void main() {
  runApp(const GroFreshApp());
}

class GroFreshApp extends StatelessWidget {
  const GroFreshApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GroFresh',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      // TODO(WIRING): once shared_preferences persists the session, check
      // AuthSession here to skip straight to ProfileSwitcherScreen for
      // already-logged-in users instead of always showing RoleSelectScreen.
      home: AuthSession.instance.isLoggedIn ? const ProfileSwitcherScreen() : const RoleSelectScreen(),
    );
  }
}

/// Single entry point that lets the demo device flip between buyer and
/// seller profile within one app, per the Swiggy/Zomato-style dual-profile
/// design already agreed by the team.
/// TODO(WIRING): replace with real logged-in-user role from auth/session
/// once registration/KYC flow determines it.
class ProfileSwitcherScreen extends StatefulWidget {
  const ProfileSwitcherScreen({super.key});

  @override
  State<ProfileSwitcherScreen> createState() => _ProfileSwitcherScreenState();
}

class _ProfileSwitcherScreenState extends State<ProfileSwitcherScreen> {
  bool _isBuyer = true;
  // TODO(WIRING): pull real seller id from session after login.
  static const _demoSellerId = 'demo-seller-id';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isBuyer ? const BuyerHomeScreen() : const SellerDashboardScreen(sellerId: _demoSellerId),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _isBuyer ? 0 : 1,
        onDestinationSelected: (i) => setState(() => _isBuyer = i == 0),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.storefront_outlined), selectedIcon: Icon(Icons.storefront), label: 'Buyer'),
          NavigationDestination(icon: Icon(Icons.agriculture_outlined), selectedIcon: Icon(Icons.agriculture), label: 'Seller'),
        ],
      ),
    );
  }
}