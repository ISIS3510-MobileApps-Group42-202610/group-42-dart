class PendingListingOperation {
  final String id;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<String> imagePaths;
  final String createdAt;

  const PendingListingOperation({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imagePaths,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'condition': condition,
      'imagePaths': imagePaths,
      'createdAt': createdAt,
    };
  }

  factory PendingListingOperation.fromJson(Map<String, dynamic> json) {
    return PendingListingOperation(
      id: json['id'].toString(),
      title: json['title'].toString(),
      description: json['description'].toString(),
      price: (json['price'] as num).toDouble(),
      category: json['category'].toString(),
      condition: json['condition'].toString(),
      imagePaths: (json['imagePaths'] as List)
          .map((item) => item.toString())
          .toList(),
      createdAt: json['createdAt'].toString(),
    );
  }
}