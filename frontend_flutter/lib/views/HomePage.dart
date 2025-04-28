import 'package:flutter/material.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:frontend/views/RegisterPage.dart';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final List<Map<String, String>> initialProducts = [
    {
      'image': 'assets/images/BALCONNET.jpg',
      'description':
          "Découvrez notre collection de lingerie balconnet, alliant maintien optimal et mise en valeur naturelle de la silhouette."
    },
    {
      'image': 'assets/images/BANDEAU.jpg',
      'description':
          "Découvrez notre collection de lingerie bandeau, conçue pour offrir un soutien ferme tout en restant discrète sous vos vêtements."
    },
    {
      'image': 'assets/images/BIG-SIZES.jpg',
      'description':
          "Découvrez notre collection de lingerie grandes tailles, spécialement conçue pour offrir un maintien et un confort optimaux."
    },
  ];

  final List<Map<String, String>> allProducts = [
    {'image': 'assets/images/BALCONNET.jpg', 'description': 'Découvrez notre collection de lingerie balconnet, alliant maintien optimal et mise en valeur naturelle de la silhouette. Conçus pour offrir un galbe élégant, ces modèles rehaussent la poitrine tout en assurant un ajustement parfait. Idéals pour allier confort et raffinement, ils subliment chaque tenue avec élégance et assurance.'},
    {'image': 'assets/images/BANDEAU.jpg', 'description': 'Découvrez notre collection de lingerie bandeau, conçue pour offrir un soutien ferme tout en restant discrète sous vos vêtements. Grâce à leurs coques lisses, ces modèles garantissent une silhouette harmonieuse et un style épuré. Idéals pour sublimer vos tenues sans bretelles, ils allient confort et liberté de mouvement, que ce soit pour un look décontracté ou une occasion spéciale.'},
    {'image': 'assets/images/Bra Cups.jpg', 'description': 'Découvrez notre collection de lingerie Bra Cups, un modèle classique qui allie tradition et confort. Offrant un maintien optimal tout en respectant la silhouette naturelle, il constitue un choix privilégié dans les collections de lingerie. Élégant et fonctionnel, ce modèle intemporel reste un incontournable pour les femmes recherchant à la fois confort et style raffiné.'},
    {'image': 'assets/images/Push Up.jpg', 'description': 'Découvrez notre collection de lingerie Push Up, des coques conçues pour offrir un maintien optimal tout en sublimant subtilement votre décolleté. Légèrement rembourrées, elles apportent un volume naturel en rehaussant la poitrine tout en garantissant une forme harmonieuse.'},
    {'image': 'assets/images/Triangle Push Up.jpg', 'description': 'Découvrez nos Triangle Push Up, conçues pour offrir un maintien parfait et un effet rehaussant subtil. Leur forme triangle épouse délicatement la poitrine, lui conférant un galbe naturel. Idéales pour les femmes en quête dun look à la fois confortable et séduisant.'},
    {'image': 'assets/images/Triangle.jpg', 'description': 'Découvrez notre collection de lingerie Triangle, conçue pour offrir un maintien léger et un style naturel. Sa forme triangle épouse parfaitement la poitrine, créant un effet seconde peau tout en mettant en valeur vos courbes avec élégance. Idéale pour un look à la fois décontracté et raffiné.'},
    {'image': 'assets/images/Balconnet.jpg', 'description': 'Découvrez notre collection de lingerie balconnet, offrant un maintien optimal et un galbe élégant. Sa forme rehausse la poitrine, créant un effet arrondi et naturel, idéal pour sublimer les tenues les plus féminines. Nos modèles assurent un ajustement parfait et sont conçus pour les femmes recherchant à la fois style et soutien, pour une allure séduisante et confiante au quotidien.'},
    {'image': 'assets/images/bandeau.jpg', 'description': 'Découvrez notre collection de lingerie bandeau, conçue pour offrir un soutien ferme tout en restant discrète sous vos vêtements. Ces coques garantissent une forme lisse et harmonieuse pour un style minimaliste. Idéales pour sublimer vos tenues sans bretelles, elles assurent confort et liberté de mouvement, que ce soit pour un look décontracté ou une occasion spéciale.'},
    {'image': 'assets/images/Grandes Tailles.jpg', 'description': 'Découvrez notre collection de lingerie grandes tailles, spécialement conçue pour offrir un maintien et un confort optimaux, tout en épousant et sublimant vos formes. Nous nous engageons à répondre à toutes les tailles, alliant élégance et fonctionnalité. Nos modèles vous garantissent un soutien irréprochable, vous permettant de vous sentir belle et à l aise en toute circonstance.'},
    {'image': 'assets/images/Comfort Bra Cup.jpg', 'description': 'Découvrez notre collection de lingerie Comfort Bra Cup, conçue pour offrir un soutien doux et agréable. Grâce à leur conception ergonomique, ces coques s adaptent parfaitement à la forme naturelle de votre poitrine, assurant une silhouette harmonieuse sans compromettre le confort. Idéales pour un usage quotidien, elles vous permettent de vous sentir bien tout au long de la journée, tout en sublimant votre lingerie avec un maximum de confort.'},
    {'image': 'assets/images/Eco Friendly.jpg', 'description': 'Découvrez notre collection de lingerie Eco Friendly, pour un engagement en faveur de la planète sans compromis sur le style. Fabriquées à partir de matériaux durables et respectueux de l environnement, ces coques offrent un maintien et un confort équivalents à nos modèles traditionnels, tout en réduisant leur impact écologique. Avec notre lingerie Eco Friendly, adoptez un mode de vie plus durable tout en profitant de pièces élégantes et fonctionnelles, conçues pour sublimer vos courbes avec une conscience verte.'},
  ];

  bool _showAllProducts = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(context),
            SizedBox(height: 20),
            _buildMainSection(),
            SizedBox(height: 40),
            _buildProductGrid(),
            SizedBox(height: 20),
            _buildDiscoverMoreButton(),
            SizedBox(height: 40),
            _buildAboutUsSection(),
            SizedBox(height: 40),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

Widget _buildDiscoverMoreButton() {
  return ElevatedButton(
    onPressed: () {
      setState(() {
        _showAllProducts = !_showAllProducts;
      });
    },
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue.shade700,
      padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
    ), // ← cette parenthèse fermante manquait
    child: Text(
      _showAllProducts ? 'Voir moins' : 'Découvrir plus',
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    ),
  );
}


  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.blue.shade700,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FTE-Epaunova',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Icon(Icons.email, color: Colors.white),
              SizedBox(width: 5),
              Text('met@epaunova.com.tn', style: TextStyle(color: Colors.white)),
              SizedBox(width: 20),
              Icon(Icons.phone, color: Colors.white),
              SizedBox(width: 5),
              Text('+216 73 49 05 00', style: TextStyle(color: Colors.white)),
              SizedBox(width: 20),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  );
                },
                child: Text('se connecter', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => RegisterPage()),
                  );
                },
                child: Text("s'inscrire", style: TextStyle(color: Colors.white)),
                style: OutlinedButton.styleFrom(side: BorderSide(color: Colors.white)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMainSection() {
    return Container(
      height: 400,
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/bigPanel.jpg'),
          fit: BoxFit.cover,
        ),
      ),
      child: Center(
        // Add any content you want to display on top of the image
      ),
    );
  }

  Widget _buildAboutUsSection() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 50, vertical: 60),
      color: Colors.blue.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À propos de nous',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),
          Text(
            "Notre Mission",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "FTE-Epaunova est une entreprise spécialisée dans la conception et la fabrication de lingerie de haute qualité. "
                      "Depuis plus de 20 ans, nous nous engageons à offrir des produits qui allient confort, élégance et durabilité. "
                      "Notre mission est de mettre en valeur la beauté naturelle de chaque femme à travers nos collections soigneusement conçues.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
              SizedBox(width: 40),
              Expanded(
                child: Text(
                  "Chez FTE-Epaunova, nous croyons que chaque femme mérite des sous-vêtements qui allient soutien et assurance. "
                      "Grâce à une combinaison de qualité, de design et d'innovation, notre objectif est de révolutionner la façon dont les femmes perçoivent et expérimentent la lingerie.",
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
              ),
            ],
          ),
          SizedBox(height: 30),
        ],
      ),
    );
  }

  Widget _buildProductGrid() {
    final displayedProducts = _showAllProducts ? allProducts : initialProducts;
    
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8,
        ),
        itemCount: displayedProducts.length,
        itemBuilder: (context, index) {
          return ProductCard(product: displayedProducts[index]);
        },
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 40, horizontal: 50),
      color: Colors.blue.shade900,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "FTE-Epaunova",
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Route de Touza 5014 - Béni Hassen - Monastir - Tunisie",
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.phone, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("123-456-7890", style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.email, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text("info@fte-epaunova.com",
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
          SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Icon(Icons.facebook, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Icon(Icons.public, color: Colors.white, size: 24),
              SizedBox(width: 12),
              Icon(Icons.discord, color: Colors.white, size: 24),
            ],
          ),
          SizedBox(height: 30),
          Divider(color: Colors.white30, thickness: 0.5),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '© 2025 FTE-Epaunova. Tous droits réservés.',
                style: TextStyle(color: Colors.white70),
              ),
              Row(
                children: [
                  TextButton(
                    onPressed: () {},
                    child: Text("Politique de confidentialité",
                        style: TextStyle(color: Colors.white70)),
                  ),
                  SizedBox(width: 10),
                  TextButton(
                    onPressed: () {},
                    child: Text("Mentions légales",
                        style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ProductCard extends StatefulWidget {
  final Map<String, String> product;

  ProductCard({required this.product});

  @override
  _ProductCardState createState() => _ProductCardState();
}

class _ProductCardState extends State<ProductCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Card(
        elevation: _isHovered ? 10 : 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Image.asset(
                widget.product['image']!,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
              ),
            ),
            if (_isHovered)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(15),
                    color: Colors.black.withOpacity(0.6),
                  ),
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        widget.product['description']!,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
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