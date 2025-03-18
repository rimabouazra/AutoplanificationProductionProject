import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildHeader(),
            _buildMainSection(context),
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      color: Colors.blue.shade900,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'FTE-Epaunova',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          Row(
            children: [
              Text(' met@epaunova.com.tn', style: TextStyle(color: Colors.white)),
              SizedBox(width: 10),
              Text('+216 73 49 05 00', style: TextStyle(color: Colors.white)),
              SizedBox(width: 20),
              TextButton(
                onPressed: () {},
                child: Text('Sign In', style: TextStyle(color: Colors.white)),
              ),
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

  Widget _buildMainSection(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6, // 60% de la hauteur de l'écran
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/braCup.jpg'),
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: EdgeInsets.all(20),
      color: Colors.blue.shade900,
      child: Column(
        children: [
          Text(
            '© 2025 Nom de la Société. Tous droits réservés.',
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }
}