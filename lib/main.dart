// ignore_for_file: prefer_const_constructors, unnecessary_brace_in_string_interps

import 'package:basic_weather_app/weather.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() => runApp(MaterialApp(
      title: "Weather",
      home: Home(),
    ));
