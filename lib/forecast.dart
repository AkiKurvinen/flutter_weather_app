// ignore_for_file: prefer_const_constructors, unnecessary_brace_in_string_interps
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:geolocator/geolocator.dart';
import 'dart:convert';
import 'apikey.dart';
import 'package:simple_moment/simple_moment.dart';

class Forecast extends StatefulWidget {
  const Forecast({Key? key}) : super(key: key);
  @override
  State<StatefulWidget> createState() {
    return _ForecastState();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}

class WeatherObject {
  Moment? date;
  double? temp;
  String? weather;
  int? humidity;
  double? wind;
  String? icon;

  WeatherObject(
      this.date, this.temp, this.weather, this.humidity, this.wind, this.icon);

  factory WeatherObject.fromJson(dynamic json) {
    return WeatherObject(
        Moment.parse(json['dt_txt'].toString()),
        json['main']['temp'] as double,
        json['weather'][0]['description'] as String,
        json['main']['humidity'] as int,
        json['wind']['speed'] as double,
        json['weather'][0]['icon'] as String);
  }
}

class _ForecastState extends State<Forecast> {
  var temp = 0.0;
  var description = 'n/a';
  var currently = 'n/a';
  var humidity = 0;
  var windSpeed = 0.0;
  var mainCity = "tampere";
  late Position _currentPosition;
  late TextEditingController _inputController;
  bool isButtonActive = false;
  late List<dynamic> entries = [];

  final List<int> colorCodes = <int>[600, 200];

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
    String city = '';

    if (aLocation != '') {
      city = aLocation.toString();
    }

    String units = 'metric';
    String apikey = getApikey();

    var url = Uri.parse('https://api.openweathermap.org/');

    if (lat != null && lon != null) {
      url = Uri.parse(
          'https://api.openweathermap.org/data/2.5/forecast?lat=${lat}&lon=${lon}&units=${units}&appid=$apikey');
    } else if (city != '') {
      mainCity = city;
      var cityCoordUrl = Uri.parse(
          'https://api.openweathermap.org/geo/1.0/direct?q=$city&limit=1&appid=$apikey');

      final http.Response response = await http.get(cityCoordUrl);

      if (response.body.toString().length < 10) {
        Fluttertoast.showToast(msg: response.statusCode.toString());
      }
      var results;

      try {
        results = json.decode(response.body);
      } on FormatException catch (e) {
        Fluttertoast.showToast(
          msg: e.toString(),
        );
      }

      var cityLat = results[0]['lat'].toString();
      var cityLon = results[0]['lon'].toString();

      if (response.statusCode == 200) {
        url = Uri.parse(
            'https://api.openweathermap.org/data/2.5/forecast?lat=${cityLat}&lon=${cityLon}&units=metric&appid=$apikey');
      } else {
        Fluttertoast.showToast(
          msg: response.statusCode.toString(),
        );
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
          Padding(
            padding: const EdgeInsets.all(8),
            child: Center(
              child: Text(
                mainCity,
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: const <Widget>[
                Expanded(
                  flex: 5,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Icon'),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Date & Time'),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Temp.'),
                  ),
                ),
                Expanded(
                  flex: 8,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Humidity'),
                  ),
                ),
                Expanded(
                  flex: 10,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Text('Wind'),
                  ),
                ),
                Expanded(
                  flex: 15,
                  child: Padding(
                    padding: EdgeInsets.only(left: 16.0),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Weather'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
                padding: const EdgeInsets.all(0),
                itemCount: entries.length,
                itemBuilder: (BuildContext context, int index) {
                  return Container(
                      color: Colors.amber[colorCodes[
                          int.parse(entries[index].date.format("dd")) % 2]],
                      child: Center(
                        child: Padding(
                          padding: EdgeInsets.all(12.0),
                          child: Row(
                            children: <Widget>[
                              Expanded(
                                flex: 5,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Image.network(
                                    'https://openweathermap.org/img/wn/${entries[index].icon.toString()}.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(entries[index]
                                      .date
                                      .format("dd.MM'. at' HH:mm")),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(entries[index]
                                          .temp
                                          .toString()
                                          .replaceAll(".", ",") +
                                      ' °C'),
                                ),
                              ),
                              Expanded(
                                flex: 8,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(entries[index]
                                          .humidity
                                          .toString()
                                          .replaceAll(".", ",") +
                                      ' %'),
                                ),
                              ),
                              Expanded(
                                flex: 10,
                                child: Align(
                                  alignment: Alignment.centerRight,
                                  child: Text(entries[index]
                                          .wind
                                          .toString()
                                          .replaceAll(".", ",") +
                                      ' m/s'),
                                ),
                              ),
                              Expanded(
                                flex: 15,
                                child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: Padding(
                                      padding: EdgeInsets.only(left: 16.0),
                                      child: Text(entries[index]
                                          .weather
                                          .toString()
                                          .capitalize()),
                                    )),
                              ),
                            ],
                          ),
                        ),
                      ));
                }),
          ),
          Padding(
            padding:
                EdgeInsets.only(bottom: 70.0, left: 25, right: 25, top: 10),
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
