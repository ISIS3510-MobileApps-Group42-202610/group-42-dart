import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../theme/app_theme.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../models/product_dto.dart';

class CreateEditProductScreen extends StatefulWidget {
  final ProductDto? product;

  const CreateEditProductScreen({
    super.key,
    this.product,
  });

  @override
  State<CreateEditProductScreen> createState() =>
      _CreateEditProductScreenState();
}

class _CreateEditProductScreenState extends State<CreateEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  final List<String> _categories = const [
    'Electronics',
    'Books',
    'Other',
  ];

  late String _selectedCategory;

  bool get _isEditing => widget.product != null;

  @override
  void initState() {
    super.initState();

    _titleController = TextEditingController(
      text: widget.product?.title ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.product?.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.product?.price.toString() ?? '',
    );
    _selectedCategory = _mapApiCategoryToUi(
      widget.product?.category ?? 'other',
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  String _mapApiCategoryToUi(String apiCategory) {
    switch (apiCategory.toLowerCase()) {
      case 'textbook':
        return 'Books';
      case 'electronics':
        return 'Electronics';
      case 'other':
      default:
        return 'Other';
    }
  }

  String? _requiredValidator(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter $fieldName';
    }
    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a price';
    }

    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed <= 0) {
      return 'Please enter a valid price';
    }

    return null;
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final price = double.parse(_priceController.text.trim());

    if (_isEditing) {
      context.read<ProductBloc>().add(
        UpdateProductRequested(
          productId: widget.product!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
        ),
      );
    } else {
      context.read<ProductBloc>().add(
        CreateProductRequested(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
        ),
      );
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit listing' : 'Create listing'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _isEditing ? 'Update your listing' : 'Post a new listing',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: 24),

                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Title'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  decoration: uniInputDecoration(
                    hint: 'Enter the listing title',
                    icon: Icons.inventory_2_outlined,
                  ),
                  validator: (value) => _requiredValidator(value, 'a title'),
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Product description'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  decoration: uniInputDecoration(
                    hint: 'Describe what you are selling',
                    icon: Icons.description_outlined,
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'a description'),
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Selling price'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  decoration: uniInputDecoration(
                    hint: 'Enter the selling price',
                    icon: Icons.attach_money_outlined,
                  ),
                  validator: _priceValidator,
                ),
                const SizedBox(height: 16),

                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Category'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCategory,
                  decoration: uniInputDecoration(
                    hint: 'Select a category',
                    icon: Icons.category_outlined,
                  ),
                  items: _categories
                      .map(
                        (category) => DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCategory = value);
                  },
                ),
                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: _submit,
                    child: Text(_isEditing ? 'Save changes' : 'Publish listing'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}