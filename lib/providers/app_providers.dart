import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:poolqapp/Provider/AuthProviders.dart';
import 'package:poolqapp/Provider/homeProvider.dart';

class AppProviders extends StatelessWidget {
  final Widget child;

  const AppProviders({
    Key? key,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<DataProvider>(
          create: (context) => DataProvider(),
        ),
        ChangeNotifierProvider<AuthProviders>(
          create: (context) => AuthProviders(),
        ),
        // Add additional providers here
      ],
      child: child,
    );
  }
} 