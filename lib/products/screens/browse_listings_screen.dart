import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../services/smart_recommendation_service.dart';
import '../widgets/public_listing_card.dart';

class BrowseListingsScreen extends StatefulWidget {
  const BrowseListingsScreen({super.key});

  @override
  State<BrowseListingsScreen> createState() => _BrowseListingsScreenState();
}

class _BrowseListingsScreenState extends State<BrowseListingsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final SmartRecommendationService _smartService =
      const SmartRecommendationService();

  String _search = '';
  final List<String> _searchHistory = [];

  // Snackbar anti-spam mechanism
  DateTime? _lastSnackbarTime;
  String? _lastSnackbarMessage;
  static const Duration _snackbarCooldown = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductBloc>().add(const LoadPublicListings());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
    });
    context.read<ProductBloc>().add(const LoadPublicListings());
  }

  void _saveSearch(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;

    setState(() {
      _searchHistory.removeWhere(
        (item) => item.toLowerCase() == trimmed.toLowerCase(),
      );
      _searchHistory.insert(0, trimmed);

      if (_searchHistory.length > 10) {
        _searchHistory.removeLast();
      }
    });
  }

  void _applySuggestion(String suggestion) {
    _searchController.text = suggestion;
    setState(() {
      _search = suggestion;
    });
    _saveSearch(suggestion);
  }

  bool _shouldShowSnackbar(String message) {
    final now = DateTime.now();
    final lastTime = _lastSnackbarTime;

    // Check if message is identical to the last one shown
    if (_lastSnackbarMessage == message) {
      return false;
    }

    // Check if enough time has passed since the last snackbar
    if (lastTime != null && now.difference(lastTime) < _snackbarCooldown) {
      return false;
    }

    _lastSnackbarTime = now;
    _lastSnackbarMessage = message;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductError) {
          if (_shouldShowSnackbar(state.message)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message)),
            );
          }
        } else if (state is ProductOfflineFromCache) {
          if (_shouldShowSnackbar(state.message)) {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.orange[700],
                duration: const Duration(seconds: 4),
              ),
            );
          }
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Search listings')),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final activeListings = state.publicProducts
                    .where((p) => p.active)
                    .toList();

                final filteredActive = activeListings.where((p) {
                  final q = _search.toLowerCase().trim();
                  if (q.isEmpty) return true;
                  return p.title.toLowerCase().contains(q) ||
                      p.description.toLowerCase().contains(q) ||
                      p.category.toLowerCase().contains(q);
                }).toList();

                final paginatedProducts = filteredActive.take(6).toList();

                final recommendedListings = _smartService
                    .getRecommendedListings(
                      listings: activeListings,
                      searchHistory: _searchHistory,
                    );

                final suggestions = _smartService.buildSuggestions(
                  _searchHistory,
                );

                if ((state is ProductInitial || state is ProductLoading) &&
                    state.publicProducts.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Text(
                        'Smart search',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.labelDark,
                            ),
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'Search listings and get recommendations based on your recent queries.',
                        style: TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),
                      TextField(
                        controller: _searchController,
                        onChanged: (value) {
                          setState(() {
                            _search = value;
                          });
                        },
                        onSubmitted: (value) {
                          _saveSearch(value);
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by title, description or category',
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _search.isEmpty
                              ? null
                              : IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      _search = '';
                                    });
                                  },
                                  icon: const Icon(Icons.clear),
                                ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                      ),
                      if (suggestions.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'Suggested searches',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.labelDark,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: suggestions
                              .map(
                                (suggestion) => ActionChip(
                                  label: Text(suggestion),
                                  onPressed: () => _applySuggestion(suggestion),
                                ),
                              )
                              .toList(),
                        ),
                      ],
                      const SizedBox(height: 24),

                      if (_search.trim().isEmpty) ...[
                        const Text(
                          'Recommended for you',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 18,
                            color: AppColors.labelDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'These listings are ranked using your recent searches.',
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 12),
                        ...recommendedListings
                            .take(4)
                            .map(
                              (product) =>
                              PublicListingCard(product: product),
                        ),
                        const SizedBox(height: 24),
                      ],

                      const Text(
                        'AVAILABLE PRODUCTS',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: AppColors.primaryBlue,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (filteredActive.isEmpty)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Text(
                            'No products found matching your search.',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                      else
                        ...paginatedProducts.map(
                          (product) => PublicListingCard(product: product),
                        ),

                      if (paginatedProducts.length < filteredActive.length)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: ElevatedButton(
                              onPressed: () {
                                setState(() {
                                });
                              },
                              child: const Text("Load more"),
                            ),
                          ),
                        ),

                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
