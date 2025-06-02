import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shimmer/shimmer.dart';

import 'productDetail.dart';

class Shop extends StatelessWidget {
  final bool isLoggedIn = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shop',
      theme: ThemeData(
        primarySwatch: Colors.orange,
        scaffoldBackgroundColor: Color(0xFFF7F7F7),
      ),
      home: ProductsScreen(isLoggedIn: isLoggedIn),
    );
  }
}

class ProductsScreen extends StatefulWidget {
  final bool isLoggedIn;
  ProductsScreen({required this.isLoggedIn});

  @override
  _ProductsScreenState createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _products = [];
  List<dynamic> _filteredProducts = [];
  List<String> _categories = ['All'];
  bool _isLoading = true;
  String? _error;

  TabController? _tabController;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    final url = Uri.parse('https://dummyjson.com/products');

    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final products = data['products'] as List<dynamic>;

        final categoriesSet = <String>{};
        for (var product in products) {
          final cat = product['category'] as String?;
          if (cat != null) categoriesSet.add(cat);
        }

        setState(() {
          _products = products;
          _categories = ['All', ...categoriesSet.toList()];
          _filteredProducts = _products;
          _tabController =
              TabController(length: _categories.length, vsync: this);
          _tabController!.addListener(() {
            if (_tabController!.indexIsChanging) {
              _filterProducts();
            }
          });
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load products';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _filterProducts() {
    final selectedCategory = _categories[_tabController?.index ?? 0];
    List<dynamic> tempList = _products;

    if (selectedCategory != 'All') {
      tempList =
          tempList.where((p) => p['category'] == selectedCategory).toList();
    }

    if (_searchQuery.isNotEmpty) {
      tempList = tempList
          .where((p) =>
              p['title']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()) ||
              p['description']
                  .toString()
                  .toLowerCase()
                  .contains(_searchQuery.toLowerCase()))
          .toList();
    }

    setState(() {
      _filteredProducts = tempList;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Widget buildSkeletonLoader() {
    return LayoutBuilder(
      builder: (context, constraints) {
        int crossAxisCount = 2;
        double width = constraints.maxWidth;
        if (width > 1200) {
          crossAxisCount = 5;
        } else if (width > 900) {
          crossAxisCount = 4;
        } else if (width > 600) {
          crossAxisCount = 3;
        }

        return GridView.builder(
          padding: EdgeInsets.all(12),
          itemCount: 10,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 0.65,
          ),
          itemBuilder: (_, __) => Shimmer.fromColors(
            baseColor: Colors.grey[300]!,
            highlightColor: Colors.grey[100]!,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius:
                            BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 14, width: 80, color: Colors.grey[300]),
                        SizedBox(height: 6),
                        Container(height: 14, width: 50, color: Colors.grey[300]),
                        SizedBox(height: 6),
                        Container(height: 12, width: 100, color: Colors.grey[300]),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 1,
          title: Row(
            children: [
              Text(
                'Shop',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: TextField(
                  onChanged: (value) {
                    _searchQuery = value;
                    _filterProducts();
                  },
                  decoration: InputDecoration(
                    hintText: 'Search products...',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[200],
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                    prefixIcon: Icon(Icons.search, color: Colors.grey[600]),
                  ),
                  style: TextStyle(color: Colors.black87),
                ),
              ),
            ],
          ),
          bottom: _isLoading || _error != null || _tabController == null
              ? null
              : TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: Colors.orange,
                  unselectedLabelColor: Colors.grey,
                  indicatorColor: Colors.orange,
                  tabs: _categories
                      .map((cat) =>
                          Tab(text: cat[0].toUpperCase() + cat.substring(1)))
                      .toList(),
                ),
        ),
        body: _isLoading
            ? buildSkeletonLoader()
            : _error != null
                ? Center(child: Text('Error: $_error'))
                : _filteredProducts.isEmpty
                    ? Center(child: Text('No products found'))
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          int crossAxisCount = 2;
                          double width = constraints.maxWidth;
                          if (width > 1200) {
                            crossAxisCount = 5;
                          } else if (width > 900) {
                            crossAxisCount = 4;
                          } else if (width > 600) {
                            crossAxisCount = 3;
                          }
                          return GridView.builder(
                            padding: EdgeInsets.all(12),
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: crossAxisCount,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 0.65,
                            ),
                            itemCount: _filteredProducts.length,
                            itemBuilder: (context, index) {
                              final product = _filteredProducts[index];
                              return ProductCard(
                                product: product,
                                isLoggedIn: widget.isLoggedIn,
                              );
                            },
                          );
                        },
                      ),
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final dynamic product;
  final bool isLoggedIn;

  ProductCard({required this.product, required this.isLoggedIn});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool isWishlisted = false;

  void toggleWishlist() {
    setState(() {
      isWishlisted = !isWishlisted;
    });
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final double rating = (product['rating'] ?? 0).toDouble();
    final int totalRatings = product['stock'] ?? 0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProductDetailPage(
              product: product,
              isLoggedIn: widget.isLoggedIn,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 8,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 1,
                  child: ClipRRect(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    child: Image.network(product['thumbnail'], fit: BoxFit.contain),
                  ),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: toggleWishlist,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isWishlisted ? Icons.favorite : Icons.favorite_border,
                        color: isWishlisted ? Colors.red : Colors.grey,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Text(
                product['title'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                '\$${product['price']}',
                style: TextStyle(
                  color: Colors.orange,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.star, color: Colors.yellow[700], size: 16),
                  SizedBox(width: 4),
                  Text(
                    rating.toStringAsFixed(1),
                    style: TextStyle(fontSize: 12),
                  ),
                  SizedBox(width: 8),
                  Text(
                    '($totalRatings ratings)',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
