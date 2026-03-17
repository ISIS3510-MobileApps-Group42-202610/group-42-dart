import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/auth.dart';
import '../../products/products_providers.dart';
import '../../products/screens/browse_listings_screen.dart';
import '../../products/screens/seller_products_screen.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tokenStorage = TokenStorage();
    final dio = createDio(
      tokenStorage: tokenStorage,
      baseUrl: 'https://group-42-backend.vercel.app/api/v1',
    );

    return ProductsProviders(
      dio: dio,
      child: const _HomeScreenView(),
    );
  }
}

class _HomeScreenView extends StatefulWidget {
  const _HomeScreenView();

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;

    final pages = <Widget>[
      const BrowseListingsScreen(),
      const SellerProductsScreen(),
      _ProfileTab(userName: user?.name ?? 'User'),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() => _selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Icon(Icons.sell_outlined),
            selectedIcon: Icon(Icons.sell),
            label: 'My listings',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final String userName;

  const _ProfileTab({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: primaryButtonStyle(),
                onPressed: () {
                  context.read<AuthBloc>().add(const AuthLogoutRequest());
                },
                child: const Text('Logout'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: dangerButtonStyle(),
                onPressed: () {
                  Navigator.pushNamed(context, '/delete-account');
                },
                child: const Text('Delete account'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}