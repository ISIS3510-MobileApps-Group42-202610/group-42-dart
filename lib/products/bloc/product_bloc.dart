import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:dio/dio.dart';
import '../../analytics/bloc/analytics_bloc.dart';
import '../../analytics/bloc/analytics_event.dart';
import 'product_event.dart';
import 'product_state.dart';
import '../repository/product_repository.dart';
import '../models/product_dto.dart';

class ProductBloc extends Bloc<ProductEvent, ProductState> {
  final ProductRepository repository;
  final AnalyticsBloc analyticsBloc;

  ProductBloc(this.analyticsBloc, {required this.repository})
    : super(const ProductInitial()) {
    on<LoadPublicListings>(_onLoadPublicListings);
    on<BuyProductRequested>(_onBuyProduct);
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
    emit(
      ProductLoading(
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ),
    );

    try {
      final publicProducts = await repository.getPublicListings();
      emit(
        ProductLoaded(
          myProducts: state.myProducts,
          publicProducts: publicProducts,
        ),
      );
      // Si ocurre un cache exception
    } on CacheException catch (e) {
      emit(
        ProductOfflineFromCache(
          message: e.message,
          isPublicListings: true,
          myProducts: state.myProducts,
          publicProducts: e.cachedListings,
        ),
      );
      // Si ocurre un error de autenticación
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        emit(
          ProductUnauthorized(
            myProducts: state.myProducts,
            publicProducts: state.publicProducts,
          ),
        );
        return;
      }

      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onLoadSellerProducts(
    LoadSellerProducts event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      ProductLoading(
        myProducts: state.myProducts,
        publicProducts: state.publicProducts,
      ),
    );

    try {
      final myProducts = await repository.getSellerProducts();
      emit(
        ProductLoaded(
          myProducts: myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    } on CacheException catch (e) {
      // No hay conexion, hay cache
      emit(
        ProductOfflineFromCache(
          message: e.message,
          isPublicListings: false,
          myProducts: e.cachedListings,
          publicProducts: state.publicProducts,
        ),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        emit(
          ProductUnauthorized(
            myProducts: state.myProducts,
            publicProducts: state.publicProducts,
          ),
        );
        return;
      }

      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onBuyProduct(
    BuyProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    final List<ProductDto> previousPublicList = List.from(state.publicProducts);

    emit(
      ProductLoading(
        myProducts: List.from(state.myProducts),
        publicProducts: List.from(state.publicProducts),
      ),
    );

    try {
      final product = state.publicProducts.cast<ProductDto?>().firstWhere(
        (p) => p?.id == event.productId,
        orElse: () => null,
      );

      await repository.buyProduct(event.productId);

      print("Send transaction_completed for ${event.productId}");
      analyticsBloc.add(
        TrackBusinessEvent(
          eventName: 'transaction_completed',
          listingId: event.productId,
          metadata: {
            "price": product?.price ?? 0,
            "category": product?.category ?? "unknown",
          },
        ),
      );

      try {
        await repository.markProductAsSold(event.productId);
      } catch (_) {}

      final serverPublic = await repository.getPublicListings();
      final serverMy = await repository.getSellerProducts();

      final List<ProductDto> combinedPublicList = List.from(serverPublic);
      final bool existsInServer = combinedPublicList.any(
        (p) => p.id == event.productId,
      );

      if (!existsInServer) {
        try {
          final boughtProduct = previousPublicList.firstWhere(
            (p) => p.id == event.productId,
          );
          combinedPublicList.add(boughtProduct.copyWith(active: false));
        } catch (_) {}
      } else {
        for (int i = 0; i < combinedPublicList.length; i++) {
          if (combinedPublicList[i].id == event.productId) {
            combinedPublicList[i] = combinedPublicList[i].copyWith(
              active: false,
            );
          }
        }
      }

      emit(
        ProductActionSuccess(
          message: 'Product bought successfully.',
          myProducts: serverMy,
          publicProducts: combinedPublicList,
        ),
      );

      emit(
        ProductLoaded(myProducts: serverMy, publicProducts: combinedPublicList),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onCreateProduct(
    CreateProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      ProductLoading(
        myProducts: List.from(state.myProducts),
        publicProducts: List.from(state.publicProducts),
      ),
    );
    try {
      final imageUrls = await repository.uploadImages(event.imageFiles);
      await repository.createProduct(
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
        condition: event.condition,
        imageUrls: imageUrls,
      );
      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();
      emit(
        ProductActionSuccess(
          message: 'Listing created successfully.',
          myProducts: myProducts,
          publicProducts: publicProducts,
        ),
      );
      emit(
        ProductLoaded(myProducts: myProducts, publicProducts: publicProducts),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onUpdateProduct(
    UpdateProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      ProductLoading(
        myProducts: List.from(state.myProducts),
        publicProducts: List.from(state.publicProducts),
      ),
    );
    try {
      List<String>? newImageUrls;
      if (event.newImageFiles.isNotEmpty) {
        newImageUrls = await repository.uploadImages(event.newImageFiles);
      }
      await repository.updateProduct(
        productId: event.productId,
        title: event.title,
        description: event.description,
        price: event.price,
        category: event.category,
        condition: event.condition,
        newImageUrls: newImageUrls,
        removedImageIds: event.removedImageIds.isNotEmpty
            ? event.removedImageIds
            : null,
      );
      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();
      emit(
        ProductActionSuccess(
          message: 'Listing updated successfully.',
          myProducts: myProducts,
          publicProducts: publicProducts,
        ),
      );
      emit(
        ProductLoaded(myProducts: myProducts, publicProducts: publicProducts),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onDeleteProduct(
    DeleteProductRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      ProductLoading(
        myProducts: List.from(state.myProducts),
        publicProducts: List.from(state.publicProducts),
      ),
    );
    try {
      await repository.deleteProduct(event.productId);
      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();
      emit(
        ProductActionSuccess(
          message: 'Listing removed successfully.',
          myProducts: myProducts,
          publicProducts: publicProducts,
        ),
      );
      emit(
        ProductLoaded(myProducts: myProducts, publicProducts: publicProducts),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onMarkAsSold(
    MarkProductAsSoldRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      ProductLoading(
        myProducts: List.from(state.myProducts),
        publicProducts: List.from(state.publicProducts),
      ),
    );
    try {
      await repository.markProductAsSold(event.productId);
      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();
      emit(
        ProductActionSuccess(
          message: 'Listing marked as sold.',
          myProducts: myProducts,
          publicProducts: publicProducts,
        ),
      );
      emit(
        ProductLoaded(myProducts: myProducts, publicProducts: publicProducts),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }

  Future<void> _onMarkAsAvailable(
    MarkProductAsAvailableRequested event,
    Emitter<ProductState> emit,
  ) async {
    emit(
      ProductLoading(
        myProducts: List.from(state.myProducts),
        publicProducts: List.from(state.publicProducts),
      ),
    );
    try {
      await repository.markProductAsAvailable(event.productId);
      final myProducts = await repository.getSellerProducts();
      final publicProducts = await repository.getPublicListings();
      emit(
        ProductActionSuccess(
          message: 'Listing marked as available.',
          myProducts: myProducts,
          publicProducts: publicProducts,
        ),
      );
      emit(
        ProductLoaded(myProducts: myProducts, publicProducts: publicProducts),
      );
    } catch (e) {
      emit(
        ProductError(
          message: repository.extractMessage(e),
          myProducts: state.myProducts,
          publicProducts: state.publicProducts,
        ),
      );
    }
  }
}
