import 'package:flutter/material.dart';
import 'package:frontend/providers/MachineProvider.dart';
import 'package:frontend/providers/ProduitProvider.dart';
import 'package:frontend/providers/matiereProvider.dart';
import 'package:frontend/providers/salleProvider.dart';
import 'package:frontend/views/LoginPage.dart';
import 'package:frontend/views/RegisterPage.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/CommandeProvider.dart';
import 'package:frontend/providers/modeleProvider.dart';
import 'package:frontend/providers/client_provider.dart';
import 'views/admin_home_page.dart';
import 'views/HomePage.dart';

import 'package:frontend/providers/PlanificationProvider .dart';
import 'package:frontend/providers/userProvider.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CommandeProvider()),
        ChangeNotifierProvider(
            create: (context) => ModeleProvider()..fetchModeles()),
        ChangeNotifierProvider(create: (context) => SalleProvider()),
        ChangeNotifierProvider(create: (context) => MatiereProvider()),
        ChangeNotifierProvider(create: (context) => MachineProvider()),

        ChangeNotifierProvider(create: (context) => ProduitProvider()),
        ChangeNotifierProvider(create: (context) => ClientProvider()),

        ChangeNotifierProvider(
          create: (context) => PlanificationProvider(
            Provider.of<CommandeProvider>(context, listen: false),
            Provider.of<MatiereProvider>(context, listen: false),
          ),
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Admin Space',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      supportedLocales: [
        Locale('en', 'US'), // Support for English
        Locale('fr', 'FR'), // Support for French
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate, // Add localization delegate
        GlobalWidgetsLocalizations.delegate, // Add widget localization delegate
        GlobalCupertinoLocalizations
            .delegate, // Add Cupertino localization delegate
      ],
      routes: {
        '/login': (context) => LoginPage(),
        '/register': (context) => RegisterPage(),
        '/adminHome': (context) => AdminHomePage(),
      },
      home: HomePage(),
    );
  }
}