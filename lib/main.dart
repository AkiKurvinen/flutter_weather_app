// ignore_for_file: prefer_const_constructors, unnecessary_brace_in_string_interps

import 'package:basic_weather_app/weather.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'weather.dart';
import 'forecast.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _MyAppState();
  }
}

class _MyAppState extends State<MyApp> {
  String topBarText = 'Current Weather';
  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<String> _products = ['Laptop'];
  @override
  Widget build(BuildContext context) {
    Widget child = Weather();
    switch (_selectedIndex) {
      case 0:
        topBarText = 'Current Weather';
        child = Weather();
        break;

      case 1:
        topBarText = 'Forecast';
        child = Forecast();
        break;
    }

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          iconTheme: IconThemeData(
            color: Colors.black, //change your color here
          ),
          title: Text(topBarText),
          centerTitle: true,
        ),
        body: child,
        bottomNavigationBar: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Current Weather',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.emoji_nature),
              label: 'Forecast',
            ),
          ],
          currentIndex: _selectedIndex,
          selectedItemColor: Color.fromARGB(255, 0, 180, 126),
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}
