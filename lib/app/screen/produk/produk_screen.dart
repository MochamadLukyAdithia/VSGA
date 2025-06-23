import 'package:flutter/material.dart';
import 'package:vsga/app/models/Produk.dart';
import 'package:vsga/app/models/User.dart';
import 'package:vsga/app/service/produk_service.dart';

class ProductsScreen extends StatefulWidget {
  final User user;

  const ProductsScreen({super.key, required this.user});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  final ProductService _productService = ProductService();
  List<Product> products = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _initializeAndLoadProducts();
  }

  Future<void> _initializeAndLoadProducts() async {
    try {
      await _productService.initializeProductTable();
      await _loadProducts();
    } catch (e) {
      print('Error initializing: $e');
      _showSnackBar(context, 'Error menginisialisasi database');
    }
  }

  Future<void> _loadProducts() async {
    setState(() => isLoading = true);
    try {
      final loadedProducts = searchQuery.isEmpty
          ? await _productService.getAllProducts()
          : await _productService.searchProducts(searchQuery);

      setState(() {
        products = loadedProducts;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      print('Error loading products: $e');
      _showSnackBar(context, 'Error memuat produk');
    }
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kelola Produk'),
        centerTitle: true,
        backgroundColor: Colors.orange.shade600,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: Container(),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: _showSearchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshProducts,
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.orange.shade600, Colors.orange.shade50],
          ),
        ),
        child: isLoading
            ? _buildLoadingState()
            : products.isEmpty
            ? _buildEmptyState()
            : RefreshIndicator(
                onRefresh: _refreshProducts,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    return _buildProductCard(products[index]);
                  },
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddProductDialog(),
        backgroundColor: Colors.orange.shade600,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.orange),
          ),
          SizedBox(height: 16),
          Text(
            'Memuat produk...',
            style: TextStyle(fontSize: 16, color: Colors.orange),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bakery_dining, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            searchQuery.isEmpty ? 'Belum ada produk' : 'Produk tidak ditemukan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            searchQuery.isEmpty
                ? 'Tambahkan produk pertama Anda'
                : 'Coba kata kunci lain',
            style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
          ),
          if (searchQuery.isNotEmpty) ...[
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() => searchQuery = '');
                _loadProducts();
              },
              child: const Text('Tampilkan Semua Produk'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(Product product) {
    return Card(
      elevation: 6,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.orange.shade100,
                image: DecorationImage(
                  image: AssetImage(product.imageUrl),
                  fit: BoxFit.cover,
                  onError: (exception, stackTrace) {
                    // Handle image error
                  },
                ),
              ),
              child: product.imageUrl.startsWith('assets')
                  ? Icon(
                      Icons.bakery_dining,
                      size: 40,
                      color: Colors.orange.shade400,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Product Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    product.description,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Rp ${product.price.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange.shade700,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: product.stock > 10
                              ? Colors.green.shade100
                              : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Stok: ${product.stock}',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.stock > 10
                                ? Colors.green.shade700
                                : Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Menampilkan tanggal update
                  if (product.updatedAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Diperbarui: ${_formatDate(product.updatedAt!)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            // Action Buttons
            Column(
              children: [
                IconButton(
                  icon: Icon(Icons.edit, color: Colors.blue.shade600),
                  onPressed: () => _showEditProductDialog(product),
                ),
                IconButton(
                  icon: Icon(Icons.delete, color: Colors.red.shade600),
                  onPressed: () => _showDeleteConfirmation(product),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog() {
    final searchController = TextEditingController(text: searchQuery);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cari Produk'),
        content: TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Masukkan nama produk',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.search),
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => searchQuery = '');
              Navigator.pop(context);
              _loadProducts();
            },
            child: const Text('Reset'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() => searchQuery = searchController.text);
              Navigator.pop(context);
              _loadProducts();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cari'),
          ),
        ],
      ),
    );
  }

  void _showAddProductDialog() {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final descriptionController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tambah Produk Baru'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  stockController.text.isNotEmpty) {
                _addProduct(
                  nameController.text,
                  double.parse(priceController.text),
                  int.parse(stockController.text),
                  descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Tambah'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(Product product) {
    final nameController = TextEditingController(text: product.name);
    final priceController = TextEditingController(
      text: product.price.toString(),
    );
    final stockController = TextEditingController(
      text: product.stock.toString(),
    );
    final descriptionController = TextEditingController(
      text: product.description,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Produk'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Nama Produk',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                  prefixText: 'Rp ',
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: stockController,
                decoration: const InputDecoration(
                  labelText: 'Stok',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Deskripsi',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              if (nameController.text.isNotEmpty &&
                  priceController.text.isNotEmpty &&
                  stockController.text.isNotEmpty) {
                _updateProduct(
                  product,
                  nameController.text,
                  double.parse(priceController.text),
                  int.parse(stockController.text),
                  descriptionController.text,
                );
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Perbarui'),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: Text('Apakah Anda yakin ingin menghapus "${product.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteProduct(product);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade600,
              foregroundColor: Colors.white,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  Future<void> _addProduct(
    String name,
    double price,
    int stock,
    String description,
  ) async {
    try {
      final newProduct = Product(
        name: name,
        price: price,
        stock: stock,
        description: description,
        imageUrl: 'assets/images/default_product.jpg',
      );

      final createdProduct = await _productService.createProduct(newProduct);

      if (createdProduct != null) {
        _showSnackBar(context, 'Produk berhasil ditambahkan');
        await _loadProducts();
      } else {
        _showSnackBar(context, 'Gagal menambahkan produk');
      }
    } catch (e) {
      print('Error adding product: $e');
      _showSnackBar(context, 'Error menambahkan produk');
    }
  }

  Future<void> _updateProduct(
    Product originalProduct,
    String name,
    double price,
    int stock,
    String description,
  ) async {
    try {
      final updatedProduct = originalProduct.copyWith(
        name: name,
        price: price,
        stock: stock,
        description: description,
      );

      final success = await _productService.updateProduct(updatedProduct);

      if (success) {
        _showSnackBar(context, 'Produk berhasil diperbarui');
        await _loadProducts();
      } else {
        _showSnackBar(context, 'Gagal memperbarui produk');
      }
    } catch (e) {
      print('Error updating product: $e');
      _showSnackBar(context, 'Error memperbarui produk');
    }
  }

  Future<void> _deleteProduct(Product product) async {
    try {
      if (product.id != null) {
        final success = await _productService.deleteProduct(product.id!);

        if (success) {
          _showSnackBar(context, 'Produk berhasil dihapus');
          await _loadProducts();
        } else {
          _showSnackBar(context, 'Gagal menghapus produk');
        }
      }
    } catch (e) {
      print('Error deleting product: $e');
      _showSnackBar(context, 'Error menghapus produk');
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } catch (e) {
      return dateString;
    }
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade600,
      ),
    );
  }
}
