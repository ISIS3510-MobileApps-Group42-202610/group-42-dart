import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../auth/auth.dart';
import '../../theme/app_theme.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../bloc/product_state.dart';
import '../models/product_dto.dart';
import '../widgets/product_card.dart';
import 'create_edit_product_screen.dart';

class SellerProductsScreen extends StatefulWidget {
  const SellerProductsScreen({super.key});

  @override
  State<SellerProductsScreen> createState() =>
      _SellerProductsScreenState();
}

class _SellerProductsScreenState
    extends State<SellerProductsScreen> {
  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback(
          (_) {
        context.read<ProductBloc>().add(
          const LoadSellerProducts(),
        );

        context.read<ProductBloc>().add(
          const SyncPendingProductsRequested(),
        );
      },
    );
  }

  Future<void> _refreshProducts() async {
    setState(() {
      _isRefreshing = true;
    });

    context.read<ProductBloc>().add(
      const LoadSellerProducts(),
    );

    context.read<ProductBloc>().add(
      const SyncPendingProductsRequested(),
    );

    await context.read<ProductBloc>().stream
        .firstWhere(
          (state) => state is! ProductLoading,
    );

    if (!mounted) return;

    setState(() {
      _isRefreshing = false;
    });
  }

  void _openCreateScreen() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child:
          const CreateEditProductScreen(),
        ),
      ),
    );
  }

  void _openEditScreen(
      ProductDto product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<ProductBloc>(),
          child: CreateEditProductScreen(
            product: product,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState =
        context.watch<AuthBloc>().state;

    final user =
    authState is AuthAuthenticated
        ? authState.user
        : null;

    return BlocListener<
        ProductBloc,
        ProductState>(
      listener: (context, state) {
        if (state
        is ProductActionSuccess) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content:
              Text(state.message),
            ),
          );
        }

        if (state is ProductError) {
          ScaffoldMessenger.of(context)
              .showSnackBar(
            SnackBar(
              content:
              Text(state.message),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text(
            'My listings',
          ),
          actions: [
            IconButton(
              tooltip:
              'Reload my listings',
              onPressed:
              _refreshProducts,
              icon:
              const Icon(Icons.refresh),
            ),
          ],
        ),
        floatingActionButton:
        FloatingActionButton.extended(
          onPressed:
          _openCreateScreen,
          backgroundColor:
          AppColors.primaryBlue,
          foregroundColor:
          Colors.white,
          icon: const Icon(Icons.add),
          label:
          const Text('Create listing'),
        ),
        body: Stack(
          children: [
            SafeArea(
              child: Padding(
                padding:
                const EdgeInsets.all(
                  20,
                ),
                child: BlocBuilder<
                    ProductBloc,
                    ProductState>(
                  builder:
                      (context, state) {
                    final myProducts =
                        state.myProducts;

                    final activeListings =
                    myProducts
                        .where(
                          (
                          product,
                          ) =>
                      product
                          .active,
                    )
                        .toList();

                    final soldListings =
                    myProducts
                        .where(
                          (
                          product,
                          ) =>
                      !product
                          .active,
                    )
                        .toList();

                    if ((state
                    is ProductInitial ||
                        state
                        is ProductLoading) &&
                        myProducts
                            .isEmpty) {
                      return const Center(
                        child:
                        CircularProgressIndicator(),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh:
                      _refreshProducts,
                      child: ListView(
                        physics:
                        const AlwaysScrollableScrollPhysics(),
                        children: [
                          Text(
                            'Seller dashboard',
                            style: Theme.of(
                                context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                              fontWeight:
                              FontWeight
                                  .bold,
                              color: AppColors
                                  .labelDark,
                            ),
                          ),

                          const SizedBox(
                            height: 6,
                          ),

                          Text(
                            user == null
                                ? 'Manage your listings'
                                : 'Welcome, ${user.name}. Manage your listings and inventory status.',
                            style:
                            const TextStyle(
                              color:
                              Colors.grey,
                            ),
                          ),

                          const SizedBox(
                            height: 20,
                          ),

                          Row(
                            children: [
                              Expanded(
                                child:
                                _StatCard(
                                  label:
                                  'Active listings',
                                  value:
                                  activeListings.length.toString(),
                                  icon: Icons
                                      .storefront_outlined,
                                ),
                              ),

                              const SizedBox(
                                width: 12,
                              ),

                              Expanded(
                                child:
                                _StatCard(
                                  label:
                                  'Sold listings',
                                  value:
                                  soldListings.length.toString(),
                                  icon: Icons
                                      .sell_outlined,
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(
                            height: 24,
                          ),

                          if (myProducts
                              .isEmpty) ...[
                            SizedBox(
                              height:
                              MediaQuery.of(
                                context,
                              )
                                  .size
                                  .height *
                                  0.5,
                              child:
                              Center(
                                child:
                                Column(
                                  mainAxisSize:
                                  MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons
                                          .inventory_2_outlined,
                                      size:
                                      72,
                                      color:
                                      Colors.grey,
                                    ),

                                    const SizedBox(
                                      height:
                                      12,
                                    ),

                                    const Text(
                                      'You have no listings yet.',
                                      style:
                                      TextStyle(
                                        fontSize:
                                        18,
                                        fontWeight:
                                        FontWeight.w700,
                                      ),
                                    ),

                                    const SizedBox(
                                      height:
                                      6,
                                    ),

                                    const Text(
                                      'Create your first listing to start selling.',
                                      style:
                                      TextStyle(
                                        color:
                                        Colors.grey,
                                      ),
                                      textAlign:
                                      TextAlign.center,
                                    ),

                                  ],
                                ),
                              ),
                            ),
                          ] else ...[
                            _SectionHeader(
                              title:
                              'Active listings',
                              subtitle:
                              'Products currently visible to other users in search.',
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            if (activeListings
                                .isEmpty)
                              const _EmptySection(
                                message:
                                'You have no active listings.',
                              )
                            else
                              ...activeListings
                                  .map(
                                    (
                                    product,
                                    ) =>
                                    ProductCard(
                                      product:
                                      product,
                                      onEdit:
                                          () =>
                                          _openEditScreen(
                                            product,
                                          ),
                                      onToggleStatus:
                                          () {
                                        context
                                            .read<
                                            ProductBloc>()
                                            .add(
                                          MarkProductAsSoldRequested(
                                            productId:
                                            product.id,
                                          ),
                                        );
                                      },
                                      onDelete:
                                          () {
                                        context
                                            .read<
                                            ProductBloc>()
                                            .add(
                                          DeleteProductRequested(
                                            productId:
                                            product.id,
                                          ),
                                        );
                                      },
                                    ),
                              ),

                            const SizedBox(
                              height: 24,
                            ),

                            _SectionHeader(
                              title:
                              'Sold listings',
                              subtitle:
                              'Keep track of the latest status of your inventory.',
                            ),

                            const SizedBox(
                              height: 12,
                            ),

                            if (soldListings
                                .isEmpty)
                              const _EmptySection(
                                message:
                                'No sold listings yet.',
                              )
                            else
                              ...soldListings
                                  .map(
                                    (
                                    product,
                                    ) =>
                                    ProductCard(
                                      product:
                                      product,
                                      onEdit:
                                          () =>
                                          _openEditScreen(
                                            product,
                                          ),
                                      onToggleStatus:
                                          () {
                                        context
                                            .read<
                                            ProductBloc>()
                                            .add(
                                          MarkProductAsAvailableRequested(
                                            productId:
                                            product.id,
                                          ),
                                        );
                                      },
                                      onDelete:
                                          () {
                                        context
                                            .read<
                                            ProductBloc>()
                                            .add(
                                          DeleteProductRequested(
                                            productId:
                                            product.id,
                                          ),
                                        );
                                      },
                                    ),
                              ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
            if (_isRefreshing)
              Container(
                color: Colors.black
                    .withOpacity(0.12),
                child: const Center(
                  child: Card(
                    child: Padding(
                      padding:
                      EdgeInsets.all(
                        20,
                      ),
                      child:
                      CircularProgressIndicator(),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor:
              AppColors.primaryBlue
                  .withOpacity(0.12),
              child: Icon(
                icon,
                color:
                AppColors.primaryBlue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment:
                CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style:
                    const TextStyle(
                      fontSize: 22,
                      fontWeight:
                      FontWeight.w800,
                    ),
                  ),
                  Text(
                    label,
                    style:
                    const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment:
      CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(
            fontWeight:
            FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _EmptySection extends StatelessWidget {
  final String message;

  const _EmptySection({
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding:
        const EdgeInsets.all(18),
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.grey,
          ),
        ),
      ),
    );
  }
}