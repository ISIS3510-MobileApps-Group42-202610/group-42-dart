import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../theme/app_theme.dart';
import '../../analytics/analytics.dart';
import '../bloc/product_bloc.dart';
import '../models/product_dto.dart';
import '../screens/product_detail_screen.dart';
import '../utils/price_formatter.dart';

class PublicListingCard extends StatelessWidget {
  final ProductDto product;

  const PublicListingCard({super.key, required this.product});

  Widget _placeholder() {
    return Container(
      width: 72,
      height: 72,
      color: AppColors.primaryBlue.withValues(alpha: 0.08),
      child: const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.primaryBlue,
        size: 32,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        // BQ12: listing_opened
        context.read<AnalyticsBloc>().add(TrackBusinessEvent(
          eventName: 'listing_opened',
          listingId: product.id,
          metadata: {
            'category': product.category,
            'title': product.title,
            'price': product.price,
          },
        ));

        final bloc = context.read<ProductBloc>();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: bloc,
              child: ProductDetailScreen(product: product),
            ),
          ),
        );
      },
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primaryBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: product.primaryImageUrl == null
                      ? _placeholder()
                      : CachedNetworkImage(
                          imageUrl: product.primaryImageUrl!,
                          fit: BoxFit.cover,
                          placeholder: (context, _) => _placeholder(),
                          errorWidget: (context, url, error) => _placeholder(),
                        ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: AppColors.labelDark,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      product.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.black87),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _Pill(label: product.category),
                        _Pill(label: product.condition),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      formatPriceWithApostrophes(product.price),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (product.sellerName != null &&
                        product.sellerName!.trim().isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Seller: ${product.sellerName}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;

  const _Pill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}
