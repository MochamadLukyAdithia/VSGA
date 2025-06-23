import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vsga/app/models/Tansaksi.dart';
import 'package:vsga/app/models/User.dart';
import 'package:vsga/app/service/pesanan_service.dart';

class CreateOrderScreen extends StatefulWidget {
  final User? user;

  const CreateOrderScreen({super.key, this.user});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final TransactionService _transactionService = TransactionService();

  // Form controllers
  final _customerNameController = TextEditingController();
  final _customerPhoneController = TextEditingController();
  final _customerAddressController = TextEditingController();
  final _locationController = TextEditingController();

  // Order items
  List<OrderItem> orderItems = [OrderItem()];

  // Loading states
  bool isLoadingLocation = false;
  bool isSubmitting = false;

  // Available products
  final List<Product> availableProducts = [
    Product(name: 'Roti Tawar Gandum', price: 15000),
    Product(name: 'Croissant Original', price: 25000),
    Product(name: 'Donat Coklat', price: 12000),
    Product(name: 'Roti Sobek', price: 18000),
    Product(name: 'Kue Lapis', price: 20000),
  ];

  @override
  void dispose() {
    _customerNameController.dispose();
    _customerPhoneController.dispose();
    _customerAddressController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() {
      isLoadingLocation = true;
    });

    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        // Location services are not enabled, show dialog to enable
        if (mounted) {
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Layanan Lokasi Tidak Aktif'),
                content: const Text(
                  'Silakan aktifkan layanan lokasi di pengaturan perangkat Anda.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('OK'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(context).pop();
                      await Geolocator.openLocationSettings();
                    },
                    child: const Text('Buka Pengaturan'),
                  ),
                ],
              );
            },
          );
        }
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Check location permissions
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            _showPermissionDialog(
              'Izin Lokasi Ditolak',
              'Aplikasi memerlukan izin lokasi untuk mendapatkan koordinat GPS. Silakan berikan izin lokasi.',
            );
          }
          setState(() {
            isLoadingLocation = false;
          });
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          _showPermissionDialog(
            'Izin Lokasi Ditolak Permanen',
            'Izin lokasi telah ditolak secara permanen. Silakan aktifkan izin lokasi melalui pengaturan aplikasi.',
            showSettings: true,
          );
        }
        setState(() {
          isLoadingLocation = false;
        });
        return;
      }

      // Get current position with timeout
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15), // Add timeout
      );

      setState(() {
        _locationController.text =
            '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
        isLoadingLocation = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Lokasi berhasil didapatkan!'),
                      Text(
                        'Lat: ${position.latitude.toStringAsFixed(6)}, Lng: ${position.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            backgroundColor: Color(0xFF8B4513),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      setState(() {
        isLoadingLocation = false;
      });

      String errorMessage = 'Gagal mendapatkan lokasi';
      if (e.toString().contains('timeout')) {
        errorMessage = 'Timeout - Pastikan GPS aktif dan sinyal kuat';
      } else if (e.toString().contains('PERMISSION_DENIED')) {
        errorMessage = 'Izin lokasi ditolak';
      } else if (e.toString().contains('POSITION_UNAVAILABLE')) {
        errorMessage = 'Lokasi tidak tersedia - Pastikan GPS aktif';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMessage)),
              ],
            ),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Coba Lagi',
              textColor: Colors.white,
              onPressed: _getCurrentLocation,
            ),
          ),
        );
      }
    }
  }

  void _showPermissionDialog(
    String title,
    String content, {
    bool showSettings = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            if (showSettings)
              TextButton(
                onPressed: () async {
                  Navigator.of(context).pop();
                  await Geolocator.openAppSettings();
                },
                child: const Text('Buka Pengaturan'),
              )
            else
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _getCurrentLocation();
                },
                child: const Text('Coba Lagi'),
              ),
          ],
        );
      },
    );
  }

  void _addOrderItem() {
    setState(() {
      orderItems.add(OrderItem());
    });
  }

  void _removeOrderItem(int index) {
    if (orderItems.length > 1) {
      setState(() {
        orderItems.removeAt(index);
      });
    }
  }

  int _calculateTotal() {
    int total = 0;
    for (var item in orderItems) {
      if (item.product != null && item.quantity > 0) {
        total += item.product!.price * item.quantity;
      }
    }
    return total;
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate order items
    final validItems = orderItems
        .where((item) => item.product != null && item.quantity > 0)
        .toList();

    if (validItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal harus ada 1 item pesanan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Silakan dapatkan lokasi terlebih dahulu!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Generate transaction ID
      final transactionId = 'TRX${DateTime.now().millisecondsSinceEpoch}';

      // Convert order items to transaction items
      final transactionItems = validItems
          .map(
            (item) => TransactionItem(
              productName: item.product!.name,
              quantity: item.quantity,
              price: item.product!.price,
            ),
          )
          .toList();

      // Create transaction
      final transaction = Transaction(
        id: transactionId,
        customerName: _customerNameController.text.trim(),
        customerPhone: _customerPhoneController.text.trim(),
        customerAddress: _customerAddressController.text.trim(),
        items: transactionItems,
        totalAmount: _calculateTotal(),
        status: TransactionStatus.pending,
        orderTime: DateTime.now(),
        gpsLocation: _locationController.text.trim(),
      );

      // Insert transaction
      await _transactionService.insertTransaction(transaction);

      setState(() {
        isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Pesanan berhasil dibuat!'),
            backgroundColor: Color(0xFF8B4513),
          ),
        );

        // Clear form
        _clearForm();
      }
    } catch (e) {
      setState(() {
        isSubmitting = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating order: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _clearForm() {
    _customerNameController.clear();
    _customerPhoneController.clear();
    _customerAddressController.clear();
    _locationController.clear();
    setState(() {
      orderItems = [OrderItem()];
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Buat Pesanan'),
        centerTitle: true,
        backgroundColor: Color(0xFF8B4513),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF8B4513), Colors.green.shade50],
          ),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Customer Information Section
                      _buildSectionCard(
                        title: 'Informasi Pelanggan',
                        icon: Icons.person,
                        children: [
                          TextFormField(
                            controller: _customerNameController,
                            decoration: const InputDecoration(
                              labelText: 'Nama Pelanggan',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Nama pelanggan harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerPhoneController,
                            decoration: const InputDecoration(
                              labelText: 'No. Telepon',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.phone),
                            ),
                            keyboardType: TextInputType.phone,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'No. telepon harus diisi';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _customerAddressController,
                            decoration: const InputDecoration(
                              labelText: 'Alamat',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.location_on),
                            ),
                            maxLines: 3,
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'Alamat harus diisi';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Location Section
                      _buildSectionCard(
                        title: 'Lokasi GPS',
                        icon: Icons.gps_fixed,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _locationController,
                                  decoration: InputDecoration(
                                    labelText:
                                        'Koordinat (Latitude, Longitude)',
                                    border: const OutlineInputBorder(),
                                    prefixIcon: const Icon(Icons.place),
                                    suffixIcon:
                                        _locationController.text.isNotEmpty
                                        ? const Icon(
                                            Icons.check_circle,
                                            color: Colors.green,
                                          )
                                        : null,
                                  ),
                                  readOnly: true,
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton.icon(
                                onPressed: isLoadingLocation
                                    ? null
                                    : _getCurrentLocation,
                                icon: isLoadingLocation
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Icon(Icons.my_location),
                                label: Text(
                                  isLoadingLocation
                                      ? 'Loading...'
                                      : 'Get Location',
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Color(0xFF8B4513),
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          if (_locationController.text.isEmpty)
                            Container(
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                border: Border.all(
                                  color: Colors.amber.shade300,
                                ),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.info,
                                    color: Colors.amber.shade700,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Pastikan GPS aktif dan berikan izin lokasi untuk mendapatkan koordinat yang akurat',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.amber.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Order Items Section
                      _buildSectionCard(
                        title: 'Item Pesanan',
                        icon: Icons.shopping_cart,
                        children: [
                          ...orderItems.asMap().entries.map((entry) {
                            int index = entry.key;
                            OrderItem item = entry.value;
                            return _buildOrderItemCard(item, index);
                          }).toList(),
                          const SizedBox(height: 8),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: _addOrderItem,
                              icon: const Icon(Icons.add),
                              label: const Text('Tambah Item'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green.shade600,
                                side: BorderSide(color: Colors.green.shade600),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Total Section
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade100,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade300),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total Pesanan:',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Rp ${_formatCurrency(_calculateTotal())}',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.green.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Submit Button
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : _submitOrder,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF8B4513),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text('Memproses...'),
                          ],
                        )
                      : const Text(
                          'Buat Pesanan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, color: Color(0xFF8B4513)),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderItem item, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Item ${index + 1}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (orderItems.length > 1)
                IconButton(
                  onPressed: () => _removeOrderItem(index),
                  icon: const Icon(Icons.delete, color: Colors.red),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<Product>(
            value: item.product,
            decoration: const InputDecoration(
              labelText: 'Pilih Produk',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            items: availableProducts.map((product) {
              return DropdownMenuItem<Product>(
                value: product,
                child: Text(
                  '${product.name} - Rp ${_formatCurrency(product.price)}',
                ),
              );
            }).toList(),
            onChanged: (Product? value) {
              setState(() {
                item.product = value;
              });
            },
          ),
          const SizedBox(height: 8),
          TextFormField(
            decoration: const InputDecoration(
              labelText: 'Jumlah',
              border: OutlineInputBorder(),
              isDense: true,
            ),
            keyboardType: TextInputType.number,
            initialValue: item.quantity > 0 ? item.quantity.toString() : '',
            onChanged: (value) {
              setState(() {
                item.quantity = int.tryParse(value) ?? 0;
              });
            },
          ),
          if (item.product != null && item.quantity > 0) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(
                  'Rp ${_formatCurrency(item.product!.price * item.quantity)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _formatCurrency(int amount) {
    return amount.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}

// Helper Classes
class OrderItem {
  Product? product;
  int quantity = 0;

  OrderItem({this.product, this.quantity = 0});
}

class Product {
  final String name;
  final int price;

  Product({required this.name, required this.price});
}
