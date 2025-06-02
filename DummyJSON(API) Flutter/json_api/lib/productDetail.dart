import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:shimmer/shimmer.dart';

class ProductDetailPage extends StatefulWidget {
  final dynamic product;
  final bool isLoggedIn;

  ProductDetailPage({required this.product, required this.isLoggedIn});

  @override
  _ProductDetailPageState createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  List<dynamic> relatedProducts = [];
  List<dynamic> comments = [];
  bool isLoading = true;
  bool isCommentLoading = true;
  int selectedImageIndex = 0;

  @override
  void initState() {
    super.initState();
    widget.product['quantity'] = 1;
    fetchComments();
    fetchRelatedProducts();
  }

  Future<void> fetchRelatedProducts() async {
    final url = Uri.parse(
      'https://dummyjson.com/products/category/${widget.product['category']}',
    );
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          relatedProducts = data['products']
              .where((p) => p['id'] != widget.product['id'])
              .toList();
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> fetchComments() async {
    final productId = widget.product['id'];
    final url = Uri.parse('https://dummyjson.com/comments/post/$productId');
    try {
      final response = await http.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          comments = data['comments'] ?? [];
          isCommentLoading = false;
        });
      } else {
        setState(() => isCommentLoading = false);
      }
    } catch (e) {
      setState(() => isCommentLoading = false);
    }
  }

  Widget buildProductInfoRow(String label, String? value) {
    if (value == null || value.trim().isEmpty) return SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Text('$label: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(fontSize: 16),
              overflow: TextOverflow.fade,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildShimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: 140,
        margin: EdgeInsets.only(right: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Widget buildShimmerComment() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: ListTile(
        leading: CircleAvatar(backgroundColor: Colors.white),
        title: Container(height: 10, color: Colors.white),
        subtitle: Container(height: 10, margin: EdgeInsets.only(top: 5), color: Colors.white),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final dimensions = product['dimensions'];
    List<dynamic> imagesList = product['images'] ?? [product['thumbnail']];

    return Scaffold(
      appBar: AppBar(
        title: Text(product['title']),
        backgroundColor: Colors.white,
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(horizontal: 15, vertical: 10),
        color: Colors.white,
        child: widget.isLoggedIn
            ? Row(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      border: Border.all(color: Colors.grey.shade300),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.remove),
                          onPressed: () {
                            setState(() {
                              if (product['quantity'] > 1) {
                                product['quantity']--;
                              }
                            });
                          },
                        ),
                        Text(
                          '${product['quantity'] ?? 1}',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            setState(() {
                              product['quantity'] = (product['quantity'] ?? 1) + 1;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Added ${product['quantity']} item(s) to cart!')),
                          );
                        },
                        icon: Icon(Icons.shopping_cart, color: Colors.white),
                        label: Text('Add to Cart', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : Center(
                child: Text('Please log in to add to cart', style: TextStyle(fontSize: 16, color: Colors.red)),
              ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: Image.network(
                      imagesList[selectedImageIndex],
                      width: double.infinity,
                      height: 250,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return SizedBox(
                          height: 250,
                          child: Center(child: CircularProgressIndicator()),
                        );
                      },
                      errorBuilder: (context, error, stackTrace) =>
                          Container(height: 250, color: Colors.grey[200]),
                    ),
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 80,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: imagesList.length,
                    itemBuilder: (context, index) {
                      bool isSelected = index == selectedImageIndex;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            selectedImageIndex = index;
                          });
                        },
                        child: Container(
                          margin: EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isSelected ? Colors.orange : Colors.grey.shade300,
                              width: isSelected ? 3 : 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.network(
                              imagesList[index],
                              width: 80,
                              height: 80,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[200],
                                child: Icon(Icons.broken_image),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                SizedBox(height: 16),
                Text(product['title'], style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                SizedBox(height: 8),
                Text('\$${product['price']}', style: TextStyle(fontSize: 20, color: Colors.orange)),
                SizedBox(height: 8),
                Row(
                  children: [
                    RatingBarIndicator(
                      rating: product['rating']?.toDouble() ?? 0.0,
                      itemBuilder: (context, _) => Icon(Icons.star, color: Colors.yellow),
                      itemCount: 5,
                      itemSize: 22,
                    ),
                    SizedBox(width: 6),
                    Text('${product['rating']}', style: TextStyle(fontSize: 16)),
                  ],
                ),
                SizedBox(height: 12),
                buildProductInfoRow('Brand', product['brand']),
                buildProductInfoRow('SKU', product['sku']),
                buildProductInfoRow('Weight', product['weight'] != null ? '${product['weight']} kg' : ''),
                buildProductInfoRow('Quantity', product['stock']?.toString() ?? 'Not available'),
                if (dimensions != null)
                  buildProductInfoRow('Dimensions', '${dimensions['width']} x ${dimensions['height']} x ${dimensions['depth']} cm'),
                SizedBox(height: 16),
                Text(product['description'], style: TextStyle(fontSize: 16)),
                SizedBox(height: 30),
                Text('Comments', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                isCommentLoading
                    ? Column(children: List.generate(3, (_) => buildShimmerComment()))
                    : comments.isEmpty
                        ? Text('No comments available.')
                        : ListView.builder(
                            itemCount: comments.length,
                            shrinkWrap: true,
                            physics: NeverScrollableScrollPhysics(),
                            itemBuilder: (context, index) {
                              final comment = comments[index];
                              return ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(child: Icon(Icons.person, size: 18)),
                                title: Text(comment['user']['username']),
                                subtitle: Text(comment['body']),
                              );
                            },
                          ),
                SizedBox(height: 30),
                Text('Related Products', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                SizedBox(height: 10),
                isLoading
                    ? SizedBox(
                        height: 200,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          itemCount: 5,
                          itemBuilder: (_, __) => buildShimmerCard(),
                        ),
                      )
                    : relatedProducts.isEmpty
                        ? Text('No related products found.')
                        : SizedBox(
                            height: 200,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: relatedProducts.length,
                              itemBuilder: (context, index) {
                                final related = relatedProducts[index];
                                return GestureDetector(
                                  onTap: () {
                                    Navigator.pushReplacement(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ProductDetailPage(
                                          product: related,
                                          isLoggedIn: widget.isLoggedIn,
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    width: 140,
                                    margin: EdgeInsets.only(right: 10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                          borderRadius: BorderRadius.circular(10),
                                          child: Image.network(
                                            related['thumbnail'],
                                            width: 140,
                                            height: 120,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) =>
                                                Container(
                                              width: 140,
                                              height: 120,
                                              color: Colors.grey[200],
                                              child: Icon(Icons.broken_image),
                                            ),
                                          ),
                                        ),
                                        SizedBox(height: 5),
                                        Text(
                                          related['title'],
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        Text(
                                          '\$${related['price']}',
                                          style: TextStyle(color: Colors.orange),
                                        ),
                                        SizedBox(height: 2),
                                        RatingBarIndicator(
                                          rating: (related['rating'] ?? 0).toDouble(),
                                          itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
                                          itemCount: 5,
                                          itemSize: 16,
                                          direction: Axis.horizontal,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
              ],
            ),
          );
        },
      ),
    );
  }
}
