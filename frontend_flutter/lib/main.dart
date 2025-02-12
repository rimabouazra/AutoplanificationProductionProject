import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';

import 'providers/CommandeProvider.dart';
import 'views/AddCommandePage.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => CommandeProvider()),
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
      title: 'Commande App',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      supportedLocales: [
        Locale('en', 'US'),  // Support for English
        Locale('fr', 'FR'),  // Support for French
      ],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,  // Add localization delegate
        GlobalWidgetsLocalizations.delegate,  // Add widget localization delegate
        GlobalCupertinoLocalizations.delegate,  // Add Cupertino localization delegate
      ],
      home: AddCommandePage(),
    );
  }
}
