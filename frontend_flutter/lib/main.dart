import 'package:flutter/material.dart';
import 'package:frontend/providers/matiereProvider.dart';
import 'package:frontend/providers/salleProvider.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'providers/CommandeProvider.dart';
import 'package:frontend/providers/modeleProvider.dart';
import 'views/admin_home_page.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommandeProvider()),
        ChangeNotifierProvider(
            create: (context) => ModeleProvider()..fetchModeles()),
        ChangeNotifierProvider(create: (context) => SalleProvider()),
        ChangeNotifierProvider(create: (context) => MatiereProvider()),
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
      home: AdminHomePage(),
    );
  }
}
