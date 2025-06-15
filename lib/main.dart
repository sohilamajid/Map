import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'Map/presentation/views/map_screen.dart';

void main()async {
  WidgetsFlutterBinding.ensureInitialized();
  await Geolocator.isLocationServiceEnabled();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            home: const MapScreen(),
          );
        }

  }
