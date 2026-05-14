import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:isis3510_group42_flutter_app/products/screens/chats_screen.dart';

import '../../auth/auth.dart';
import '../../analytics/analytics.dart';
import '../../products/bloc/product_bloc.dart';
import '../../products/bloc/product_state.dart';
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

    return ProductsProviders(dio: dio, child: const _HomeScreenView());
  }
}

class _HomeScreenView extends StatefulWidget {
  const _HomeScreenView();

  @override
  State<_HomeScreenView> createState() => _HomeScreenViewState();
}

class _HomeScreenViewState extends State<_HomeScreenView> {
  int _selectedIndex = 0;
  DateTime? navStartTime;
  bool _handledUnauthorized = false;

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthBloc>().state;

    if (authState is AuthLoading || authState is AuthInitial) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (authState is! AuthAuthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        Navigator.pushNamedAndRemoveUntil(
          context,
          '/login',
              (_) => false,
        );
      });

      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final user = authState.user;

    final pages = <Widget>[
      const BrowseListingsScreen(),
      const ChatsScreen(),
      const SellerProductsScreen(),
      _ProfileTab(user: user),
    ];

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductUnauthorized && !_handledUnauthorized) {
          _handledUnauthorized = true;
          ScaffoldMessenger.of(context).hideCurrentSnackBar();
          context.read<AuthBloc>().add(const AuthLogoutRequest());
        }
      },
      child: Scaffold(
        body: IndexedStack(index: _selectedIndex, children: pages),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            navStartTime = DateTime.now();
            setState(() => _selectedIndex = index);
            // Trackear navegación una vez que se renderiza la nueva pantalla
            // Widgets binding sirve para ejecutar algo despuess de que el widget se haya renderizado,
            // es decir justo lo que necesitamos para el bq1.
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (navStartTime != null) {
                final durationMs = DateTime.now()
                    .difference(navStartTime!)
                    .inMilliseconds
                    .toDouble();
                // pasar el evento al bloc analitico
                context.read<AnalyticsBloc>().add(
                  TrackScreenNavigation(durationMs: durationMs),
                );
              }
            });
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.search_outlined),
              selectedIcon: Icon(Icons.search),
              label: 'Search',
            ),
            NavigationDestination(
              icon: Icon(Icons.chat_outlined),
              selectedIcon: Icon(Icons.chat),
              label: 'Chats',
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
      ),
    );
  }
}

class _ProfileTab extends StatelessWidget {
  final AuthUser? user;

  const _ProfileTab({required this.user});

  @override
  Widget build(BuildContext context) {
    final userName = user?.name ?? 'User';
    final profilePic = user?.profilePic;

    return Scaffold(
      appBar: AppBar(title: Text('Welcome, $userName')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            children: [
              CircleAvatar(
                radius: 52,
                backgroundColor: AppColors.inputFill,
                backgroundImage: profilePic != null && profilePic.isNotEmpty
                    ? NetworkImage(profilePic)
                    : null,
                child: profilePic == null || profilePic.isEmpty
                    ? const Icon(
                  Icons.person_outline,
                  size: 48,
                  color: AppColors.primaryBlue,
                )
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                userName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.labelDark,
                ),
              ),
              if (user?.email != null) ...[
                const SizedBox(height: 4),
                Text(
                  user!.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
              const SizedBox(height: 28),

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
              const SizedBox(height: 32),
              const Divider(),
              const SizedBox(height: 8),
              const Text(
                'Analytics QA',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.bug_report_outlined),
                  label: const Text('Simulate Crash (BQ1)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade700,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    throw Exception(
                      'BQ1 simulated crash — ProfileTab test button',
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  icon: const Icon(Icons.warning_amber_rounded),
                  label: const Text('Simulate Fatal Crash (BQ1)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Future.error(
                      StateError(
                        'BQ1 simulated FATAL crash — async unhandled error',
                      ),
                      StackTrace.current,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}