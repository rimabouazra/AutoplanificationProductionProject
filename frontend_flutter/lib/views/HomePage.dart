import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:frontend/views/RegisterPage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> products = [
    {
      'image': 'assets/images/BALCONNET.jpg',
      'title': 'Balconnet',
      'description': 'Elegant support with a natural silhouette.',
    },
    {
      'image': 'assets/images/BANDEAU.jpg',
      'title': 'Bandeau',
      'description': 'Seamless support for a discreet look.',
    },
    {
      'image': 'assets/images/BIG-SIZES.jpg',
      'title': 'Grandes Tailles',
      'description': 'Comfort and style for every curve.',
    },
    {
      'image': 'assets/images/Push Up.jpg',
      'title': 'Push Up',
      'description': 'Subtle lift with stunning elegance.',
    },
    {
      'image': 'assets/images/Eco Friendly.jpg',
      'title': 'Eco Friendly',
      'description': 'Sustainable style without compromise.',
    },
  ];

  final List<Map<String, String>> carouselItems = [
    {
      'image': 'assets/images/hero1.jpg',
      'title': 'Timeless Elegance',
      'subtitle': 'Discover our latest lingerie collection.',
    },
    {
      'image': 'assets/images/hero2.jpg',
      'title': 'Effortless Comfort',
      'subtitle': 'Crafted for your everyday luxury.',
    },
    {
      'image': 'assets/images/hero3.jpg',
      'title': 'Sustainable Style',
      'subtitle': 'Eco-conscious designs for a better tomorrow.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(context),
          SliverToBoxAdapter(child: _buildHeroCarousel()),
          SliverToBoxAdapter(child: _buildCollectionsSection()),
          SliverToBoxAdapter(child: _buildAboutSection()),
          SliverToBoxAdapter(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 100, horizontal: 40),
              color: Colors.grey[50],
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Notre philosophie',
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 3,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Allier confort exceptionnel\net esthétique intemporelle',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w300,
                      height: 1.3,
                    ),
                  ),
                  SizedBox(height: 40),
                  Divider(height: 1, color: Colors.grey[300]),
                  SizedBox(height: 40),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          "Depuis 1998, nous concevons des pièces uniques qui célèbrent "
                              "la féminité à travers des matières nobles et des coupes architecturales.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                      SizedBox(width: 60),
                      Expanded(
                        child: Text(
                          "Chaque collection est le fruit d'un savoir-faire artisanal et d'une "
                              "attention minutieuse portée aux détails qui font la différence.",
                          style: TextStyle(
                            fontSize: 16,
                            height: 1.8,
                            color: Colors.grey[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(child: _buildFooter()),

        ],
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 80,
      floating: true,
      pinned: true,
      backgroundColor: Colors.white.withOpacity(0.95),
      elevation: 0,
      title: FadeInDown(
        child: Text(
          'FTE-Epaunova',
          style: TextStyle(
            fontFamily: 'PlayfairDisplay',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Colors.blueGrey[900],
          ),
        ),
      ),
      actions: [
        _buildNavButton('Contact', Icons.email, () {}),
        _buildNavButton('Login', Icons.login, () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => LoginPage()));
        }),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: FadeInRight(
            child: ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => RegisterPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueGrey[800],
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
              child: Text(
                'Join Us',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNavButton(String label, IconData icon, VoidCallback onPressed) {
    return FadeInRight(
      child: TextButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20, color: Colors.blueGrey[700]),
        label: Text(
          label,
          style: TextStyle(color: Colors.blueGrey[700], fontSize: 16),
        ),
      ),
    );
  }

  Widget _buildHeroCarousel() {
    return SizedBox(
      height: 600,
      child: CarouselSlider(
        options: CarouselOptions(
          autoPlay: true,
          aspectRatio: 16 / 9,
          enlargeCenterPage: true,
          viewportFraction: 1.0,
          autoPlayInterval: Duration(seconds: 5),
        ),
        items: carouselItems.map((item) {
          return FadeIn(
            child: Stack(
              children: [
                Image.asset(
                  item['image']!,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                ),
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                    ),
                  ),
                ),
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      FadeInUp(
                        child: Text(
                          item['title']!,
                          style: TextStyle(
                            fontFamily: 'PlayfairDisplay',
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            shadows: [Shadow(blurRadius: 10, color: Colors.black45)],
                          ),
                        ),
                      ),
                      SizedBox(height: 16),
                      FadeInUp(
                        delay: Duration(milliseconds: 200),
                        child: Text(
                          item['subtitle']!,
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white70,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                      FadeInUp(
                        delay: Duration(milliseconds: 400),
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.blueGrey[900],
                            padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                          ),
                          child: Text(
                            'Shop Now',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCollectionsSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 20),
      child: Column(
        children: [
          FadeInDown(
            child: Text(
              'Our Collections',
              style: TextStyle(
                fontFamily: 'PlayfairDisplay',
                fontSize: 36,
                fontWeight: FontWeight.w700,
                color: Colors.blueGrey[900],
              ),
            ),
          ),
          SizedBox(height: 40),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 1200
                  ? 4
                  : MediaQuery.of(context).size.width > 800
                      ? 3
                      : 2,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return FadeInUp(
                delay: Duration(milliseconds: index * 100),
                child: ProductCard(product: products[index]),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 80, horizontal: 40),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blueGrey[50]!, Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: FadeInLeft(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'About Us',
                    style: TextStyle(
                      fontFamily: 'PlayfairDisplay',
                      fontSize: 36,
                      fontWeight: FontWeight.w700,
                      color: Colors.blueGrey[900],
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'FTE-Epaunova is dedicated to crafting lingerie that blends elegance, comfort, and sustainability. For over two decades, we’ve empowered women with designs that celebrate their natural beauty.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey[700],
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 20),
                  Text(
                    'Our mission is to redefine lingerie with innovative designs and eco-conscious materials, ensuring every piece feels as good as it looks.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.blueGrey[700],
                      height: 1.6,
                    ),
                  ),
                  SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blueGrey[800],
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                    ),
                    child: Text(
                      'Learn More',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(width: 40),
          Expanded(
            child: FadeInRight(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.asset(
                  'assets/images/about.jpg',
                  fit: BoxFit.cover,
                  height: 400,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 60, horizontal: 40),
      color: Colors.blueGrey[900],
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: FadeInLeft(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'FTE-Epaunova',
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Crafting elegance and comfort since 2005.',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FadeInRight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Connect',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      _buildFooterLink(Icons.email, 'info@fte-epaunova.com'),
                      _buildFooterLink(Icons.phone, '+216 73 49 05 00'),
                      _buildFooterLink(Icons.location_on, 'Monastir, Tunisia'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: FadeInRight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay Updated',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 20),
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Your Email',
                          hintStyle: TextStyle(color: Colors.white70),
                          filled: true,
                          fillColor: Colors.white.withOpacity(0.1),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(30),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(Icons.send, color: Colors.white70),
                            onPressed: () {},
                          ),
                        ),
                        style: TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 40),
          Divider(color: Colors.white30),
          SizedBox(height: 20),
          Text(
            '© 2025 FTE-Epaunova. All rights reserved.',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterLink(IconData icon, String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, color: Colors.white70, size: 20),
          SizedBox(width: 10),
          Text(text, style: TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, String> product;

  const ProductCard({super.key, required this.product});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Card(
          elevation: 6,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          clipBehavior: Clip.antiAlias,
          child: Stack(
            children: [
              Image.asset(
                widget.product['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withOpacity(0.7), Colors.transparent],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.product['title']!,
                        style: TextStyle(
                          fontFamily: 'PlayfairDisplay',
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        widget.product['description']!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white70,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.blueGrey[900],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: Text(
                          'Explore',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}