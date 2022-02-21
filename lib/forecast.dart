// ignore_for_file: prefer_const_constructors, unnecessary_brace_in_string_interps

import 'dart:html';

import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'apikey.dart';
import 'dart:developer';

class Forecast extends StatefulWidget {
  const Forecast({Key? key, String? data}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _ForecastState();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class WeatherObject {
  String? date;
  double? temp;
  String? weather;
  int? humidity;
  double? wind;
  String? icon;

  WeatherObject(
      this.date, this.temp, this.weather, this.humidity, this.wind, this.icon);

  factory WeatherObject.fromJson(dynamic json) {
    Fluttertoast.showToast(msg: 'factory');
    return WeatherObject(
        json['dt_txt'] as String,
        json['main']['temp'] as double,
        json['weather'][0]['description'] as String,
        json['main']['humidity'] as int,
        json['wind']['speed'] as double,
        json['weather'][0]['icon'] as String);
  }
}

class _ForecastState extends State<Forecast> {
  var temp;
  var description;
  var currently;
  var humidity;
  var windSpeed;
  var mainCity = "tampere";
  late Position _currentPosition;
  late TextEditingController _inputController;
  bool isButtonActive = false;

  late List<dynamic> entries = [
    /*
    WeatherObject(
      date: '10.02.2022',
      temp: -3.0,
      weather: 'Clouds?',
      humidity: 90,
      wind: 5,
      icon: '01d',
    ),
    WeatherObject(
      date: '11.02.2022',
      temp: -4.0,
      weather: 'Rain?',
      humidity: 100,
      wind: 6,
      icon: '01d',
    ),
    */
  ];

  final List<int> colorCodes = <int>[600, 500, 400, 300, 200, 100];

  @override
  void initState() {
    super.initState();
    getWeather(mainCity, "metric", null, null);
    _inputController = TextEditingController();
    _inputController.addListener(() {
      final isButtonActive = _inputController.text.isNotEmpty;
      setState(() => this.isButtonActive = isButtonActive);
    });
  }

  Future<Position> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    _currentPosition = await Geolocator.getCurrentPosition();
    String lat = _currentPosition.latitude.toString();
    String lon = _currentPosition.longitude.toString();
    getWeather(null, "metric", lat, lon);

    return _currentPosition;
  }

  Future getWeather(aLocation, aUnits, lat, lon) async {
    String city = 'tampere';

    if (aLocation != '') {
      city = aLocation.toString();
    }
    String units = 'metric';
    String apikey = getApikey();

    var url;

    if (lat != null && lon != null) {
      url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=metric&appid=$apikey');
    } else if (mainCity != '') {
      var cityCoordUrl = Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apikey');

      final http.Response response = await http.get(cityCoordUrl);
      var results;
      var decodeSucceeded = false;
      try {
        results = json.decode(response.body);
        decodeSucceeded = true;
      } on FormatException catch (e) {
        Fluttertoast.showToast(
          msg: 'catch JSON error ',
        );
      }

      // final Map results = json.decode(response.body.toString());
      var cityLat = results[0]['lon'].toString();
      var cityLon = results[0]['lat'].toString();

      if (response.statusCode == 200) {
        url = Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?lat=${cityLat}&lon=${cityLon}&units=metric&appid=$apikey');
      } else {
        var cityname = _inputController.text.toString().capitalize();

        setState(() {
          mainCity = '"$cityname"';
          temp = 0;
          description = "--";
          currently = results['message'];
          humidity = 0;
          windSpeed = 0;
        });
      }
    } else {
      url = Uri.parse('https://api.openweathermap.org/data/2.5/forecast');
    }
    final http.Response response = await http.get(url);
    final Map results = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        if (_inputController.text.toString() == "") {
          mainCity = results['city']['name'].toString();
        } else {
          mainCity = _inputController.text.toString().capitalize();
        }

//   final List<WeatherObject> entries = [

        try {
          List<dynamic> newEntries = results['list']
              .map((json) => WeatherObject.fromJson(json))
              .toList();
          entries = newEntries;
        } catch (e) {
          Fluttertoast.showToast(msg: e.toString());
        }

        /*
        temp = results['main']['temp'];
        description =
        results['weather'][0]['description'].toString().capitalize();
        currently = results['weather'][0]['main'].toString().capitalize();
        humidity = results['main']['humidity'];
        windSpeed = results['wind']['speed'];
        if (lat != null && lon != null) {
          mainCity = results['city']['name'].toString();
        }
        */
      });
    } else {
      var cityname = _inputController.text.toString().capitalize();

      setState(() {
        mainCity = '"$cityname"';
        temp = 0;
        description = "--";
        currently = results['message'];
        humidity = 0;
        windSpeed = 0;
      });
    }
  }

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: <Widget>[
          Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                    color: Colors.amber[colorCodes[index % 6]],
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(entries[index].date.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Text(entries[index].temp.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Text(entries[index].humidity.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Text(entries[index].wind.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Text(entries[index].weather.toString()),
                            ],
                          ),
                          Column(
                            children: [
                              Text(entries[index].icon.toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                }),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: 70.0, left: 25, right: 25),
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _inputController,
                    obscureText: false,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Location',
                    ),
                  ),
                ),
                SizedBox(
                  width: 10,
                  height: 10,
                ),
                Expanded(
                    flex: 2,
                    child: SizedBox(
                      width: 50,
                      height: 45,
                      child: ElevatedButton(
                        child: const Text('Set Location'),
                        onPressed: isButtonActive
                            ? () {
                                setState(() => isButtonActive = false);
                                getWeather(_inputController.text, "metric",
                                    null, null);
                              }
                            : null,
                      ),
                    )),
                SizedBox(
                  width: 10,
                  height: 10,
                ),
                Expanded(
                    flex: 1,
                    child: SizedBox(
                      width: 50,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: () {
                          _determinePosition();
                        },
                        child: FaIcon(FontAwesomeIcons.searchLocation),
                      ),
                    )),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
