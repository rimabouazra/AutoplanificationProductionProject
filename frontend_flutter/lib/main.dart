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

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

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
      navigatorKey: navigatorKey, // ✅ Assign the navigatorKey here
      debugShowCheckedModeBanner: false,
      title: "Projet d'auto-planification",
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      supportedLocales: [
        Locale('en', 'US'),
        Locale('fr', 'FR'),
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
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
