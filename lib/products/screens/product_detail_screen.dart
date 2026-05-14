import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../models/product_dto.dart';
import 'chat_screen.dart';
import '../utils/price_formatter.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductDto product;

  const ProductDetailScreen({super.key, required this.product});

  Widget imagePlaceholder() {
    return Container(
      color: Colors.grey.shade200,
      alignment: Alignment.center,
      child: const Icon(
        Icons.inventory_2_outlined,
        size: 48,
        color: Colors.grey,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = product.primaryImageUrl;

    final title = product.title;
    final description = product.description;
    final category = product.category;
    final sellerName = product.sellerName ?? 'Unknown';

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        } else if (state is ProductError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Product details')),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (category.toLowerCase() == 'textbook')
                  _MeetingPlaceBadge(
                    text: 'Suggested meeting place: Library',
                    color: Colors.blue.shade50,
                  ),

                if (category.toLowerCase() == 'electronics')
                  _MeetingPlaceBadge(
                    text: 'Suggested meeting place: Engineering Lab',
                    color: Colors.green.shade50,
                  ),

                AspectRatio(
                  aspectRatio: 16 / 9,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: imageUrl == null || imageUrl.trim().isEmpty
                        ? imagePlaceholder()
                        : CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, _) => imagePlaceholder(),
                      errorWidget: (context, url, error) =>
                          imagePlaceholder(),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),

                const SizedBox(height: 10),

                Text(
                  formatPriceWithApostrophes(product.price),
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                if (!product.active) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'This product is sold',
                    style: TextStyle(
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                Text(
                  description,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 15,
                    height: 1.35,
                  ),
                ),

                const SizedBox(height: 20),

                Text(
                  'Category: $category',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ChatScreen(
                            productId: product.id,
                            sellerName: sellerName,
                            productName: title,
                            sellerId: product.sellerId,
                            mode: ChatMode.buyer,
                          ),
                        ),
                      );
                    },
                    child: const Text('Contact seller'),
                  ),
                ),

                const SizedBox(height: 10),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: product.active
                        ? () {
                      context.read<ProductBloc>().add(
                        BuyProductRequested(product.id),
                      );
                    }
                        : null,
                    child: const Text('Buy'),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MeetingPlaceBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _MeetingPlaceBadge({
    required this.text,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}