import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../models/product_dto.dart';
import 'chat_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final ProductDto product;

  const ProductDetailScreen({super.key, required this.product});

  // metodo para resolver la url de la imagen, priorizando imageUrl y luego el primer item de images
  String? resolveImageUrl(ProductDto product) {
    if (product.imageUrl != null && product.imageUrl!.trim().isNotEmpty) {
      return product.imageUrl!.trim();
    }

    for (final image in product.images) {
      final url = image.url.trim();
      if (url.isNotEmpty) return url;
    }

    return null;
  }

  // placeholder para imagenes
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
    // mostrar la imagen del producto, con un placeholder si no hay imagen o si la url es invalida
    final imageUrl = resolveImageUrl(product);

    return BlocListener<ProductBloc, ProductState>(
      listener: (context, state) {
        if (state is ProductActionSuccess) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        } else if (state is ProductError) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        appBar: AppBar(title: const Text("Product details")),
        body: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (product.category.toLowerCase() == "textbook")
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Suggested meeting place: Library",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

              if (product.category.toLowerCase() == "electronics")
                Container(
                  padding: const EdgeInsets.all(10),
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    "Suggested meeting place: Engineering Lab",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

              AspectRatio(
                aspectRatio: 16 / 9,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: imageUrl == null
                      ? imagePlaceholder()
                      : Image.network(
                          imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              imagePlaceholder(),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // titulo
              Text(
                product.title,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),

              // precio
              Text(
                "\$${product.price}",
                style: const TextStyle(
                  fontSize: 20,
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),

              if (!product.active)
                const Text(
                  "This product is sold",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              const SizedBox(height: 20),

              // descripcion
              Text(
                product.description,
                style: const TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 20),

              // categoria
              Text("Category: ${product.category}"),
              const Spacer(),

              // boton de contacto
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChatScreen(
                          productId: product.id,
                          sellerName: product.sellerName ?? "Unknown",
                        ),
                      ),
                    );
                    // chat?
                  },
                  child: const Text("Contact seller"),
                ),
              ),
              const SizedBox(height: 10),

              // boton de compra
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
                  child: const Text("Buy"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
