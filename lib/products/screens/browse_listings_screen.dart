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

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Search listings'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                final allListings =
                state.publicProducts.where((p) => p.active).toList();

                final rankedListings = _smartService.rankListings(
                  listings: allListings,
                  query: _search,
                  searchHistory: _searchHistory,
                );

                final recommendedListings = _smartService.getRecommendedListings(
                  listings: allListings,
                  searchHistory: _searchHistory,
                );

                final suggestions =
                _smartService.buildSuggestions(_searchHistory);

                if ((state is ProductInitial || state is ProductLoading) &&
                    allListings.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                return RefreshIndicator(
                  onRefresh: _refresh,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: [
                      Text(
                        'Smart search',
                        style:
                        Theme.of(context).textTheme.headlineSmall?.copyWith(
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
                        if (recommendedListings.isEmpty)
                          const Card(
                            child: Padding(
                              padding: EdgeInsets.all(18),
                              child: Text(
                                'No recommendations available yet.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          )
                        else
                          ...recommendedListings.map(
                                (product) => PublicListingCard(product: product),
                          ),
                        const SizedBox(height: 24),
                      ],
                      Text(
                        _search.trim().isEmpty
                            ? 'All active listings'
                            : 'Search results',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 18,
                          color: AppColors.labelDark,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${rankedListings.length} result(s)',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      if (rankedListings.isEmpty)
                        const Card(
                          child: Padding(
                            padding: EdgeInsets.all(18),
                            child: Text(
                              'No listings match your search.',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ),
                        )
                      else
                        ...rankedListings.map(
                              (product) => PublicListingCard(product: product),
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