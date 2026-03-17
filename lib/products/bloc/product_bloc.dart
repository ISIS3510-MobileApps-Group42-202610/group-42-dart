import 'package:flutter_bloc/flutter_bloc.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../repository/product_repository.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;

  ProductBloc({required this.repository}) : super(const ProductInitial()) {
    on<LoadPublicListings>(_onLoadPublicListings);
    on<LoadSellerProducts>(_onLoadSellerProducts);
    on<CreateProductRequested>(_onCreateProduct);
    on<UpdateProductRequested>(_onUpdateProduct);
    on<DeleteProductRequested>(_onDeleteProduct);
    on<MarkProductAsSoldRequested>(_onMarkAsSold);
    on<MarkProductAsAvailableRequested>(_onMarkAsAvailable);
  }

  Future<void> _onLoadPublicListings(
      LoadPublicListings event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      final publicProducts = await repository.getPublicListings();

      emit(ProductLoaded(
        myProducts: state.myProducts,
        publicProducts: publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }

  Future<void> _onLoadSellerProducts(
      LoadSellerProducts event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      final myProducts = await repository.getSellerProducts();

      emit(ProductLoaded(
        myProducts: myProducts,
        publicProducts: state.publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }

  Future<void> _onCreateProduct(
      CreateProductRequested event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      await repository.createProduct(
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
      );

      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();

      emit(ProductActionSuccess(
        message: 'Listing created successfully.',
        myProducts: myProducts,
        publicProducts: publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }

  Future<void> _onUpdateProduct(
      UpdateProductRequested event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      await repository.updateProduct(
        productId: event.productId,
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
      );

      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();

      emit(ProductActionSuccess(
        message: 'Listing updated successfully.',
        myProducts: myProducts,
        publicProducts: publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }

  Future<void> _onDeleteProduct(
      DeleteProductRequested event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      await repository.deleteProduct(event.productId);

      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();

      emit(ProductActionSuccess(
        message: 'Listing removed successfully.',
        myProducts: myProducts,
        publicProducts: publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }

  Future<void> _onMarkAsSold(
      MarkProductAsSoldRequested event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      await repository.markProductAsSold(event.productId);

      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();

      emit(ProductActionSuccess(
        message: 'Listing marked as sold.',
        myProducts: myProducts,
        publicProducts: publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }

  Future<void> _onMarkAsAvailable(
      MarkProductAsAvailableRequested event,
      Emitter<ProductState> emit,
      ) async {
    emit(ProductLoading(
      myProducts: state.myProducts,
      publicProducts: state.publicProducts,
    ));

    try {
      await repository.markProductAsAvailable(event.productId);

      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();

      emit(ProductActionSuccess(
        message: 'Listing marked as available.',
        myProducts: myProducts,
        publicProducts: publicProducts,
      ));
    } catch (e) {
      emit(ProductError(
        message: repository.extractMessage(e),
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ));
    }
  }
}