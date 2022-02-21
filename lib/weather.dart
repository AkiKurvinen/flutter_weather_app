// ignore_for_file: prefer_const_constructors, unnecessary_brace_in_string_interps

import 'package:basic_weather_app/weather.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

import 'apikey.dart';

class Weather extends StatefulWidget {
  const Weather({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _WeatherState();
  }
}

extension StringExtension on String {
  String capitalizeText() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class _WeatherState extends State<Weather> {
  var temp;
  var description;
  var currently;
  var humidity;
  var windSpeed;
  var mainCity = "tampere";
  late Position _currentPosition;
  late TextEditingController _inputController;
  bool isButtonActive = false;

  String topBarText = 'Current Weather';
  @override
  void initState() {
    super.initState();
    getWeather(mainCity, null, null, null);

    _inputController = TextEditingController();
    _inputController.addListener(() {
      final isButtonActive = _inputController.text.isNotEmpty;
      setState(() => this.isButtonActive = isButtonActive);
    });
  }

  int _selectedIndex = 0;
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
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
    String city = aLocation.toString();
    String units = aUnits == null ? 'metric' : aUnits.toString();
    String apikey = getApikey();

    var url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=$units&appid=$apikey');
    if (lat != null && lon != null) {
      url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?lat=${lat}&lon=${lon}&units=$units&appid=$apikey');
    }

    final http.Response response = await http.get(url);
    final Map results = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        if (_inputController.text.toString() == "") {
          mainCity = "Tampere";
        } else {
          mainCity = _inputController.text.toString().capitalizeText();
        }

        temp = results['main']['temp'];
        description =
            results['weather'][0]['description'].toString().capitalizeText();
        currently = results['weather'][0]['main'].toString().capitalizeText();
        humidity = results['main']['humidity'];
        windSpeed = results['wind']['speed'];
        if (lat != null && lon != null) {
          mainCity = results['name'];
        }
      });
    } else {
      var cityname = _inputController.text.toString().capitalizeText();

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
          Container(
            height: MediaQuery.of(context).size.height / 3,
            width: MediaQuery.of(context).size.width,
            color: Color.fromARGB(255, 0, 180, 126),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              // ignore: prefer_const_literals_to_create_immutables
              children: <Widget>[
                Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                      mainCity
                          .toString(), // != null ? city.toString() + "\u00B0C" : "Tampere",
                      style: (TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600))),
                ),
                Text(temp != null ? temp.toString() + "\u00B0C" : "Loading",
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24.0,
                        fontWeight: FontWeight.w600)),
                Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                      currently != null ? currently.toString() : "Loading",
                      style: (TextStyle(
                          color: Colors.white,
                          fontSize: 18.0,
                          fontWeight: FontWeight.w600))),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.all(20.0),
              child: ListView(
                // ignore: prefer_const_literals_to_create_immutables
                children: <Widget>[
                  ListTile(
                    leading: SizedBox(
                      width: 30,
                      child: Center(
                        child: FaIcon(
                          FontAwesomeIcons.thermometerHalf,
                        ),
                      ),
                    ),
                    title: Text("Temperature"),
                    trailing: Text(
                        temp != null ? temp.toString() + "\u00B0C" : "Loading"),
                  ),
                  ListTile(
                    leading: FaIcon(FontAwesomeIcons.cloud),
                    title: Text("Weather"),
                    trailing: Text(description != null
                        ? description.toString()
                        : "Loading"),
                  ),
                  ListTile(
                    leading: FaIcon(FontAwesomeIcons.water),
                    title: Text("Humidity"),
                    trailing: Text(
                        humidity != null ? humidity.toString() : "Loading"),
                  ),
                  ListTile(
                    leading: FaIcon(FontAwesomeIcons.wind),
                    title: Text("Wind"),
                    trailing: Text(windSpeed != null
                        ? windSpeed.toString() + " m/s"
                        : "Loading"),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [],
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
                                getWeather(
                                    _inputController.text, null, null, null);
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
