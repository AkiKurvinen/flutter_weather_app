// ignore_for_file: prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:convert';

void main() => runApp(MaterialApp(
      title: "Weather",
      home: Home(),
    ));

class Home extends StatefulWidget {
  const Home({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() {
    return _HomeState();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class _HomeState extends State<Home> {
  var temp;
  var description;
  var currently;
  var humidity;
  var windSpeed;
  var mainCity = "tampere";
  final locationController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is removed from the
    // widget tree.
    locationController.dispose();
    super.dispose();
  }

  Future getWeather(aLocation, aUnits) async {
    String city = aLocation.toString();
    String units = aUnits == null ? 'metric' : aUnits.toString();
    String apikey = '';
    var url = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?q=$city&units=$units&appid=$apikey');

    final http.Response response = await http.get(url);
    final Map results = json.decode(response.body);

    if (response.statusCode == 200) {
      setState(() {
        if (locationController.text.toString() == "") {
          mainCity = "Tampere";
        } else {
          mainCity = locationController.text.toString().capitalize();
        }

        temp = results['main']['temp'];
        description = results['weather'][0]['description'];
        currently = results['weather'][0]['main'];
        humidity = results['main']['humidity'];
        windSpeed = results['wind']['speed'];
      });
    } else {
      var cityname = locationController.text.toString().capitalize();
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
  @override
  void initState() {
    super.initState();
    getWeather("tampere", "metric");
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
          Padding(
            padding: EdgeInsets.only(bottom: 50.0, left: 25, right: 25),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: locationController,
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
                    child: SizedBox(
                  width: 50,
                  height: 45,
                  child: ElevatedButton(
                    onPressed: () {
                      getWeather(locationController.text, null);
                    },
                    child: const Text('Set Location'),
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
