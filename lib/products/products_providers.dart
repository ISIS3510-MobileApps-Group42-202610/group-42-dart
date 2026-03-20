import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../analytics/bloc/analytics_bloc.dart';
import 'bloc/product_bloc.dart';
import 'data/products_api_client.dart';
import 'repository/product_repository.dart';

class ProductsProviders extends StatelessWidget {
  final Widget child;
  final Dio dio;

  const ProductsProviders({
    super.key,
    required this.child,
    required this.dio,
  });

  @override
  Widget build(BuildContext context) {
    final apiClient = ProductsApiClient(dio: dio);
    final repository = ProductRepository(apiClient: apiClient);

    return RepositoryProvider<ProductRepository>.value(
      value: repository,
      child: BlocProvider<ProductBloc>(
        create: (context) => ProductBloc(
          context.read<AnalyticsBloc>(),
          repository: repository,
        ),
        child: child,
      ),
    );
  }
}
