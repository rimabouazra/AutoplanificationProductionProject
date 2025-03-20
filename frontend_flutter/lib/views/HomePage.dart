import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  final List<Map<String, String>> products = [
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            SizedBox(height: 20),
            _buildMainSection(),
            SizedBox(height: 40),
            _buildProductGrid(),
            SizedBox(height: 40),
            _buildAboutUsSection(),
            SizedBox(height: 40),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
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
                onPressed: () {},
                child: Text('Sign In', style: TextStyle(color: Colors.white)),
              ),
              SizedBox(width: 10),
              OutlinedButton(
                onPressed: () {},
                child: Text('Sign Up', style: TextStyle(color: Colors.white)),
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
      color: Colors.blue.shade900, // Fond bleu foncé pour un style élégant
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Titre principal
          Text(
            'À propos de nous',
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 20),

          // Sous-titre
          Text(
            "Notre Mission",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 20),

          // Texte en deux colonnes
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
              SizedBox(width: 40), // Espacement entre les colonnes
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
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GridView.builder(
        shrinkWrap: true,
        physics: NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.8, // Adjusted for better card proportions
        ),
        itemCount: products.length,
        itemBuilder: (context, index) {
          return ProductCard(product: products[index]);
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
          // Nom et adresse
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

          // Réseaux sociaux
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

          // Droits d'auteur et politique
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
  }}

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