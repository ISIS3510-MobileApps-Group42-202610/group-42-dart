import 'dart:math';
import '../models/product_dto.dart';

class SmartRecommendationService {
  const SmartRecommendationService();

  List<ProductDto> rankListings({
    required List<ProductDto> listings,
    String query = '',
    List<String> searchHistory = const [],
  }) {
    final activeListings = listings.where((l) => l.active).toList();
    if (activeListings.isEmpty) return [];

    final normalizedQuery = _normalize(query);
    final profile = _buildUserProfile(normalizedQuery, searchHistory);

    final scored = activeListings.map((listing) {
      final doc = _normalize(_listingDocument(listing));

      final score =
          _textSimilarity(profile, doc) +
              _fuzzyScore(normalizedQuery, doc) +
              _fieldBoost(normalizedQuery, listing) +
              _metadataBoost(listing);

      return _ScoredListing(listing: listing, score: score);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.listing).toList();
  }

  List<ProductDto> getRecommendedListings({
    required List<ProductDto> listings,
    required List<String> searchHistory,
  }) {
    return rankListings(
      listings: listings,
      searchHistory: searchHistory,
    ).take(6).toList();
  }

  List<String> buildSuggestions(List<String> searchHistory) {
    final frequency = <String, int>{};

    for (final search in searchHistory) {
      for (final token in _tokenize(search)) {
        if (token.length < 3) continue;
        frequency[token] = (frequency[token] ?? 0) + 1;
      }
    }

    final sorted = frequency.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(6).map((e) => e.key).toList();
  }

  String _listingDocument(ProductDto listing) {
    return [
      listing.title,
      listing.title,
      listing.title,
      listing.category,
      listing.category,
      listing.description,
      listing.condition,
      listing.sellerName ?? '',
    ].join(' ');
  }

  String _buildUserProfile(String query, List<String> history) {
    final parts = <String>[];

    if (query.isNotEmpty) {
      parts.add(query);
      parts.add(query);
      parts.add(query);
    }

    for (int i = 0; i < history.length; i++) {
      final normalized = _normalize(history[i]);
      final weight = max(1, history.length - i);

      for (int j = 0; j < weight; j++) {
        parts.add(normalized);
      }
    }

    return parts.join(' ');
  }

  double _textSimilarity(String query, String document) {
    final queryTokens = _tokenize(query).toSet();
    final docTokens = _tokenize(document).toSet();

    if (queryTokens.isEmpty) return 0.0;
    if (docTokens.isEmpty) return 0.0;

    final intersection = queryTokens.intersection(docTokens).length;
    final union = queryTokens.union(docTokens).length;

    return intersection / union;
  }

  double _fuzzyScore(String query, String document) {
    final queryTokens = _tokenize(query);
    final docTokens = _tokenize(document);

    if (queryTokens.isEmpty || docTokens.isEmpty) return 0.0;

    double total = 0.0;

    for (final q in queryTokens) {
      double best = 0.0;

      for (final d in docTokens) {
        if (d.contains(q) || q.contains(d)) {
          best = max(best, 0.85);
        } else {
          best = max(best, _levenshteinSimilarity(q, d));
        }
      }

      total += best;
    }

    return total / queryTokens.length;
  }

  double _fieldBoost(String query, ProductDto listing) {
    if (query.isEmpty) return 0.0;

    final title = _normalize(listing.title);
    final category = _normalize(listing.category);
    final description = _normalize(listing.description);
    final condition = _normalize(listing.condition);

    double boost = 0.0;

    if (title.contains(query)) boost += 1.2;
    if (category.contains(query)) boost += 0.8;
    if (description.contains(query)) boost += 0.4;
    if (condition.contains(query)) boost += 0.2;

    final queryTokens = _tokenize(query);

    for (final token in queryTokens) {
      if (title.contains(token)) boost += 0.45;
      if (category.contains(token)) boost += 0.35;
      if (description.contains(token)) boost += 0.20;
      if (condition.contains(token)) boost += 0.10;
    }

    return boost;
  }

  double _metadataBoost(ProductDto listing) {
    double boost = 0.0;

    if (listing.imageUrl != null && listing.imageUrl!.trim().isNotEmpty) {
      boost += 0.05;
    }

    if (listing.active) {
      boost += 0.05;
    }

    return boost;
  }

  double _levenshteinSimilarity(String a, String b) {
    if (a == b) return 1.0;
    if (a.isEmpty || b.isEmpty) return 0.0;

    final distance = _levenshteinDistance(a, b);
    final maxLength = max(a.length, b.length);

    return 1.0 - (distance / maxLength);
  }

  int _levenshteinDistance(String a, String b) {
    final matrix = List.generate(
      a.length + 1,
          (_) => List<int>.filled(b.length + 1, 0),
    );

    for (int i = 0; i <= a.length; i++) {
      matrix[i][0] = i;
    }

    for (int j = 0; j <= b.length; j++) {
      matrix[0][j] = j;
    }

    for (int i = 1; i <= a.length; i++) {
      for (int j = 1; j <= b.length; j++) {
        final cost = a[i - 1] == b[j - 1] ? 0 : 1;

        matrix[i][j] = min(
          min(
            matrix[i - 1][j] + 1,
            matrix[i][j - 1] + 1,
          ),
          matrix[i - 1][j - 1] + cost,
        );
      }
    }

    return matrix[a.length][b.length];
  }

  List<String> _tokenize(String value) {
    return _normalize(value)
        .split(RegExp(r'\s+'))
        .map((token) => token.trim())
        .where((token) => token.length >= 2)
        .where((token) => !_stopWords.contains(token))
        .toList();
  }

  String _normalize(String value) {
    return _removeAccents(value.toLowerCase())
        .replaceAll(RegExp(r'[^a-z0-9ñ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _removeAccents(String value) {
    return value
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u');
  }
}

class _ScoredListing {
  final ProductDto listing;
  final double score;

  const _ScoredListing({
    required this.listing,
    required this.score,
  });
}

const Set<String> _stopWords = {
  'a',
  'al',
  'algo',
  'algunas',
  'algunos',
  'ante',
  'antes',
  'como',
  'con',
  'contra',
  'cual',
  'cuando',
  'de',
  'del',
  'desde',
  'donde',
  'durante',
  'e',
  'el',
  'ella',
  'ellas',
  'ellos',
  'en',
  'entre',
  'era',
  'eran',
  'es',
  'esa',
  'esas',
  'ese',
  'eso',
  'esos',
  'esta',
  'estaba',
  'estado',
  'estan',
  'estar',
  'este',
  'esto',
  'estos',
  'fue',
  'fueron',
  'ha',
  'han',
  'hasta',
  'hay',
  'la',
  'las',
  'le',
  'lo',
  'los',
  'mas',
  'me',
  'mi',
  'mis',
  'muy',
  'no',
  'nos',
  'o',
  'otra',
  'otras',
  'otro',
  'otros',
  'para',
  'pero',
  'por',
  'porque',
  'que',
  'se',
  'si',
  'sin',
  'sobre',
  'su',
  'sus',
  'tambien',
  'te',
  'tiene',
  'tu',
  'tus',
  'un',
  'una',
  'unas',
  'uno',
  'unos',
  'y',
  'ya',
};