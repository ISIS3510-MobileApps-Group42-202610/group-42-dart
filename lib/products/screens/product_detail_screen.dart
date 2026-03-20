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

  @override
  Widget build(BuildContext context) {
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
      appBar: AppBar(
        title: const Text("Product details"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

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
            const SizedBox(height: 20),

            // descripcion
            Text(
              product.description,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),

            // categoria
            Text(
              "Category: ${product.category}",
            ),
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
                onPressed: () {
                  context.read<ProductBloc>().add(BuyProductRequested(product.id));
                },
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