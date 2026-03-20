import '../models/product_dto.dart';

class SmartRecommendationService {
  const SmartRecommendationService();

  List<ProductDto> rankListings({
    required List<ProductDto> listings,
    String query = '',
    List<String> searchHistory = const [],
  }) {
    final normalizedQuery = _normalize(query);
    final queryTokens = _tokenize(normalizedQuery);

    final ranked = listings
        .where((listing) => listing.active)
        .map((listing) {
      final score = _scoreListing(
        listing: listing,
        query: normalizedQuery,
        queryTokens: queryTokens,
        searchHistory: searchHistory,
      );

      return _ScoredListing(
        listing: listing,
        score: score,
      );
    })
        .toList();

    ranked.sort((a, b) {
      final scoreCompare = b.score.compareTo(a.score);
      if (scoreCompare != 0) return scoreCompare;

      return a.listing.title.toLowerCase().compareTo(
        b.listing.title.toLowerCase(),
      );
    });

    return ranked.map((item) => item.listing).toList();
  }

  List<String> buildSuggestions(List<String> searchHistory) {
    final frequency = <String, int>{};

    for (final search in searchHistory) {
      final tokens = _tokenize(_normalize(search));
      for (final token in tokens) {
        if (token.length < 3) continue;
        frequency[token] = (frequency[token] ?? 0) + 1;
      }
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(6).map((e) => e.key).toList();
  }

  List<ProductDto> getRecommendedListings({
    required List<ProductDto> listings,
    required List<String> searchHistory,
  }) {
    if (searchHistory.isEmpty) {
      return listings.where((l) => l.active).take(6).toList();
    }

    return rankListings(
      listings: listings,
      searchHistory: searchHistory,
    ).take(6).toList();
  }

  int _scoreListing({
    required ProductDto listing,
    required String query,
    required List<String> queryTokens,
    required List<String> searchHistory,
  }) {
    final title = _normalize(listing.title);
    final description = _normalize(listing.description);
    final category = _normalize(listing.category);
    final condition = _normalize(listing.condition);

    int score = 0;

    if (query.isNotEmpty) {
      if (title == query) score += 120;
      if (title.contains(query)) score += 80;
      if (description.contains(query)) score += 40;
      if (category.contains(query)) score += 35;
      if (condition.contains(query)) score += 15;

      for (final token in queryTokens) {
        if (title.contains(token)) score += 30;
        if (description.contains(token)) score += 18;
        if (category.contains(token)) score += 20;
        if (condition.contains(token)) score += 8;
      }
    }

    for (final pastSearch in searchHistory.take(8)) {
      final historyTokens = _tokenize(_normalize(pastSearch));
      for (final token in historyTokens) {
        if (token.length < 3) continue;

        if (title.contains(token)) score += 10;
        if (description.contains(token)) score += 6;
        if (category.contains(token)) score += 8;
        if (condition.contains(token)) score += 4;
      }
    }

    if (listing.active) score += 5;
    if (listing.imageUrl != null && listing.imageUrl!.trim().isNotEmpty) {
      score += 3;
    }

    return score;
  }

  String _normalize(String value) {
    return value.trim().toLowerCase();
  }

  List<String> _tokenize(String value) {
    return value
        .split(RegExp(r'\s+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class _ScoredListing {
  final ProductDto listing;
  final int score;

  const _ScoredListing({
    required this.listing,
    required this.score,
  });
}