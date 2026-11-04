import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const RentSpaceApp());
}

class ResponsiveFrame extends StatelessWidget {
  final Widget child;

  const ResponsiveFrame({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return Container(
            color: Colors.grey.shade200,
            alignment: Alignment.topCenter,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 450),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(20),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: child,
            ),
          );
        }
        return child;
      },
    );
  }
}

class RentSpaceApp extends StatelessWidget {
  const RentSpaceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RentSpace',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const LoginScreen(),
    );
  }
}
