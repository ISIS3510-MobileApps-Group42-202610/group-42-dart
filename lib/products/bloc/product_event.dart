import 'dart:io';

import 'package:equatable/equatable.dart';

abstract class ProductEvent extends Equatable {
  const ProductEvent();

  @override
  List<Object?> get props => [];
}

class LoadPublicListings extends ProductEvent {
  const LoadPublicListings();
}

class LoadSellerProducts extends ProductEvent {
  const LoadSellerProducts();
}

class CreateProductRequested extends ProductEvent {
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<File> imageFiles;

  const CreateProductRequested({
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    required this.imageFiles,
  });

  @override
  List<Object?> get props => [title, description, price, category, condition, imageFiles];
}

class UpdateProductRequested extends ProductEvent {
  final String productId;
  final String title;
  final String description;
  final double price;
  final String category;
  final String condition;
  final List<File> newImageFiles;
  final List<int> removedImageIds;

  const UpdateProductRequested({
    required this.productId,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.condition,
    this.newImageFiles = const [],
    this.removedImageIds = const [],
  });

  @override
  List<Object?> get props => [
    productId,
    title,
    description,
    price,
    category,
    condition,
    newImageFiles,
    removedImageIds,
  ];
}

class DeleteProductRequested extends ProductEvent {
  final String productId;

  const DeleteProductRequested({
    required this.productId,
  });

  @override
  List<Object?> get props => [productId];
}

class MarkProductAsSoldRequested extends ProductEvent {
  final String productId;

  const MarkProductAsSoldRequested({
    required this.productId,
  });

  @override
  List<Object?> get props => [productId];
}

class MarkProductAsAvailableRequested extends ProductEvent {
  final String productId;

  const MarkProductAsAvailableRequested({
    required this.productId,
  });

  @override
  List<Object?> get props => [productId];
}
