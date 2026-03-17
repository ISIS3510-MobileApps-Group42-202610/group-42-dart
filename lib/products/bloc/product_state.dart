import 'package:equatable/equatable.dart';
import '../models/product_dto.dart';

abstract class ProductState extends Equatable {
  final List<ProductDto> myProducts;
  final List<ProductDto> publicProducts;

  const ProductState({
    this.myProducts = const [],
    this.publicProducts = const [],
  });

  @override
  List<Object?> get props => [myProducts, publicProducts];
}

class ProductInitial extends ProductState {
  const ProductInitial();
}

class ProductLoading extends ProductState {
  const ProductLoading({
    super.myProducts,
    super.publicProducts,
  });
}

class ProductLoaded extends ProductState {
  const ProductLoaded({
    required super.myProducts,
    required super.publicProducts,
  });
}

class ProductActionSuccess extends ProductState {
  final String message;

  const ProductActionSuccess({
    required this.message,
    required super.myProducts,
    required super.publicProducts,
  });

  @override
  List<Object?> get props => [message, myProducts, publicProducts];
}

class ProductError extends ProductState {
  final String message;

  const ProductError({
    required this.message,
    super.myProducts,
    super.publicProducts,
  });

  @override
  List<Object?> get props => [message, myProducts, publicProducts];
}