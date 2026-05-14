import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../bloc/product_bloc.dart';
import '../bloc/product_event.dart';
import '../models/product_dto.dart';
import '../widgets/image_grid.dart';
import '../utils/price_formatter.dart';

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
  static const int maxImageCount = 4;
  static const int minTitleLength = 3;
  static const int maxTitleLength = 50;

  static const int minDescriptionLength = 20;
  static const int maxDescriptionLength = 500;

  static const double minPrice = 1000;
  static const double maxPrice = 10000000;

  final _formKey = GlobalKey<FormState>();
  final picker = ImagePicker(); // image picker de flutter que facilita el manejo de galeria y camara

  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _priceController;

  final List<String> _categories = const [
    'Electronics',
    'Books',
    'Other',
  ];

  final List<String> _conditions = const [
    'New',
    'Like new',
    'Good',
    'Fair',
  ];

  late String _selectedCategory;
  late String _selectedCondition;

  // imagenes locales (mientras el usuario crea el listing)
  final List<File> newImageFiles = [];

  // Imagenes que ya existen (solo para cuando el usuario esta editando)
  late List<ProductImageDto> existingImages;

  // Imagenes (id) de imgs que el usuario quiere remover del listing
  final List<int> removedImageIds = [];

  bool get _isEditing => widget.product != null;

  List<ProductImageDto> get visibleExistingImages =>
      existingImages.where((img) => !removedImageIds.contains(img.id)).toList();

  int get currentImageCount => visibleExistingImages.length + newImageFiles.length;

  bool get canAddMoreImages => currentImageCount < maxImageCount;

  void _showImageLimitReachedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('You can upload up to 4 pictures only.'),
      ),
    );
  }

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
      text: widget.product != null
          ? formatDigitsWithApostrophes(widget.product!.price.round().toString())
          : '',
    );
    _selectedCategory = _mapApiCategoryToUi(
      widget.product?.category ?? 'other',
    );
    _selectedCondition = _mapApiConditionToUi(
      widget.product?.condition ?? 'good',
    );
    existingImages = List.of(widget.product?.images ?? []);
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

  String _mapApiConditionToUi(String apiCondition) {
    switch (apiCondition.toLowerCase()) {
      case 'new':
        return 'New';
      case 'like_new':
        return 'Like new';
      case 'good':
        return 'Good';
      case 'fair':
        return 'Fair';
      default:
        return 'Good';
    }
  }

  String _cleanText(String value) {
    return value.trim().replaceAll(RegExp(r'\s+'), ' ');
  }

  bool _hasLetterOrNumber(String value) {
    return RegExp(r'[A-Za-zÀ-ÿ0-9]').hasMatch(value);
  }

  String? _titleValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a title';
    }

    final title = _cleanText(value);

    if (title.length < minTitleLength) {
      return 'Title must be at least $minTitleLength characters';
    }

    if (title.length > maxTitleLength) {
      return 'Title cannot be longer than $maxTitleLength characters';
    }

    if (!_hasLetterOrNumber(title)) {
      return 'Title must contain letters or numbers';
    }

    return null;
  }

  String? _descriptionValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a description';
    }

    final description = _cleanText(value);

    if (description.length < minDescriptionLength) {
      return 'Description must be at least $minDescriptionLength characters';
    }

    if (description.length > maxDescriptionLength) {
      return 'Description cannot be longer than $maxDescriptionLength characters';
    }

    if (!_hasLetterOrNumber(description)) {
      return 'Description must contain letters or numbers';
    }

    return null;
  }

  String? _priceValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter a price';
    }

    final price = parseFormattedPrice(value);

    if (price <= 0) {
      return 'Please enter a valid price';
    }

    if (price < minPrice) {
      return 'Price must be at least ${formatPriceWithApostrophes(minPrice)}';
    }

    if (price > maxPrice) {
      return 'Price cannot be higher than ${formatPriceWithApostrophes(maxPrice)}';
    }

    return null;
  }

  // ========================
  // Escoger imagenes


  // Escoger imagenes con camara
  Future<void> pickFromCamera() async {
    if (!canAddMoreImages) {
      _showImageLimitReachedMessage();
      return;
    }

    final picked = await picker.pickImage(
      source: ImageSource.camera, // el source es la camara del selular (SENSOR)
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null && canAddMoreImages) {
      setState(() => newImageFiles.add(File(picked.path)));
    }
  }

  // Escoger imagenes con la galeria del celular
  Future<void> pickFromGallery() async {
    if (!canAddMoreImages) {
      _showImageLimitReachedMessage();
      return;
    }

    final picked = await picker.pickImage(
      source: ImageSource.gallery, // el source es la galeria
      imageQuality: 80,
      maxWidth: 1200,
    );
    if (picked != null && canAddMoreImages) {
      setState(() => newImageFiles.add(File(picked.path)));
    }
  }

  // Mostrar el dialogo para escoger la fuente d elas imagenes (camara o galeria)
  void showImageSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                pickFromCamera();
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () {
                Navigator.pop(context);
                pickFromGallery();
              },
            ),
          ],
        ),
      ),
    );
  }

  // quital img de la lista de imagenes
  void removeNewImage(int index) {
    setState(() => newImageFiles.removeAt(index));
  }

  // quitar el img que ya existe (ponerlas en removed)
  void removeExistingImage(int imageId) {
    setState(() => removedImageIds.add(imageId));
  }

  // submit

  void submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (currentImageCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one product photo.'),
        ),
      );
      return;
    }

    final price = parseFormattedPrice(_priceController.text);

    if (_isEditing) {
      context.read<ProductBloc>().add(
        UpdateProductRequested(
          productId: widget.product!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
          condition: _selectedCondition,
          newImageFiles: newImageFiles,
          removedImageIds: removedImageIds,
        ),
      );
    } else {
      context.read<ProductBloc>().add(
        CreateProductRequested(
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          price: price,
          category: _selectedCategory,
          condition: _selectedCondition,
          imageFiles: newImageFiles,
        ),
      );
    }

    Navigator.pop(context);
  }

  // widget

  @override
  Widget build(BuildContext context) {
    // quitar las imagenes removidas
    final visibleExisting = visibleExistingImages;

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

                // fotos
                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Product photos'),
                ),
                const SizedBox(height: 8),
                ImageGrid(
                  existingImages: visibleExisting,
                  newFiles: newImageFiles,
                  onAddTap: showImageSourceSheet, // boton de add photo
                  onRemoveExisting: removeExistingImage,
                  onRemoveNew: removeNewImage,
                ),
                const SizedBox(height: 16),

                // titulo
                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Title'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _titleController,
                  maxLength: maxTitleLength,
                  textInputAction: TextInputAction.next,
                  decoration: uniInputDecoration(
                    hint: 'Enter the listing title',
                    icon: Icons.inventory_2_outlined,
                  ),
                  validator: _titleValidator,
                ),
                const SizedBox(height: 16),

                // descripcion
                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Product description'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  maxLines: 4,
                  maxLength: maxDescriptionLength,
                  textInputAction: TextInputAction.next,
                  decoration: uniInputDecoration(
                    hint: 'Describe what you are selling',
                    icon: Icons.description_outlined,
                  ),
                  validator: _descriptionValidator,
                ),
                const SizedBox(height: 16),

                // precio
                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Selling price'),
                ),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    ApostropheThousandsInputFormatter(),
                  ],
                  decoration: uniInputDecoration(
                    hint: "1'000",
                    icon: Icons.attach_money_outlined,
                  ),
                  validator: _priceValidator,
                ),
                const SizedBox(height: 16),

                // categoria
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
                const SizedBox(height: 16),

                // condicion
                Align(
                  alignment: Alignment.centerLeft,
                  child: fieldLabel('Condition'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: _selectedCondition,
                  decoration: uniInputDecoration(
                    hint: 'Select the product condition',
                    icon: Icons.verified_outlined,
                  ),
                  items: _conditions
                      .map(
                        (condition) => DropdownMenuItem<String>(
                      value: condition,
                      child: Text(condition),
                    ),
                  )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _selectedCondition = value);
                  },
                ),
                const SizedBox(height: 28),

                // submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: primaryButtonStyle(),
                    onPressed: submit,
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