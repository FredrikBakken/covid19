import 'dart:convert';
import 'package:covid19/models/case_model.dart';
import 'package:covid19/models/country_model.dart';
import 'package:covid19/models/population_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:link_text/link_text.dart';
import 'package:xml/xml.dart';

class HomeView extends StatefulWidget {
  HomeView();

  @override
  _HomeViewState createState() => new _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _newCases;
  int _population;
  double _per100k;
  bool _searching = false;
  Color _limitColor = Colors.grey;

  CountryModel _selectedCountry;
  List countries = List<CountryModel>();
  List cases = List<CaseModel>();
  List populations = List<PopulationModel>();

  List blacklisted = ["", ""];

  Future getCountriesData() async {
    final String countriesUrl = "https://api.covid19api.com/countries";
    var response = await http.get(Uri.encodeFull(countriesUrl),
        headers: {"Accept": "application/json"});
    var responseBody = json.decode(response.body);

    setState(() {
      for (var responseObject in responseBody) {
        countries.add(CountryModel.fromJson(responseObject));
      }
      countries.sort((a, b) => a.country.compareTo(b.country));
    });
  }

  Future getNewCases(String selectedSlug) async {
    final DateTime now = DateTime.now();
    final DateTime dayZero = now.subtract(Duration(days: 15));
    final DateTime yesterday = now.subtract(Duration(days: 1));

    final DateFormat formatter = new DateFormat('yyyy-MM-dd');
    final String fromDate = formatter.format(dayZero) + "T00:00:00Z";
    final String toDate = formatter.format(yesterday) + "T00:00:00Z";

    final String casesUrl =
        "https://api.covid19api.com/country/$selectedSlug/status/confirmed?from=$fromDate&to=$toDate";
    var response = await http
        .get(Uri.encodeFull(casesUrl), headers: {"Accept": "application/json"});
    var responseBody = json.decode(response.body);

    setState(() {
      cases = List<CaseModel>();
      for (var responseObject in responseBody) {
        cases.add(CaseModel.fromJson(responseObject));
      }

      cases.sort((a, b) => a.cases.compareTo(b.cases));
      _newCases = cases.last.cases - cases.first.cases;
    });

    /*
    province_cases = {}
    provinces = cases.Province.unique().tolist()
    
    for province in provinces:
        selected_province = cases.loc[cases.Province == province]
        new_cases = new_cases = selected_province.Cases.max() - selected_province.Cases.min()
        province_cases[province] = new_cases
    
    fourteen_days_ago = day_0 + timedelta(days=1)
    
    return fourteen_days_ago, yesterday, province_cases
    */
  }

  Future getPopulation(String iso2) async {
    final String populationUrl =
        "https://api.worldbank.org/v2/country/$iso2/indicator/SP.POP.TOTL";
    var response = await http
        .get(Uri.encodeFull(populationUrl), headers: {"Accept": "text/xml"});
    String xmlResponse = response.body.substring(response.body.indexOf("<"));

    var document = XmlDocument.parse(xmlResponse);
    XmlElement feedElement = document.findAllElements("wb:data").first;
    List feedElements = feedElement.findAllElements("wb:data").toList();

    setState(() {
      populations = List<PopulationModel>();
      for (var element in feedElements) {
        populations.add(PopulationModel.parse(element));
      }

      populations.sort((a, b) => a.date.compareTo(b.date));
      _population = populations.last.value;
    });

    setState(() {
      print("New cases: $_newCases");
      print("Population: $_population");
      _per100k = ((_newCases / 2) / _population) * 100000;

      if (_per100k >= 20.0) {
        _limitColor = Colors.red;
      } else {
        _limitColor = Colors.green;
      }

      _searching = false;
    });
  }

  @override
  void initState() {
    super.initState();
    this.getCountriesData();
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: AppBar(
        title: Text("Covid-19 | Weekly Incidents per. 100K"),
      ),
      body: Column(
        children: [
          SizedBox(height: 24.0),
          Center(
            child: DropdownButton(
              hint: Text('Select country...'),
              items: countries.map((item) {
                return DropdownMenuItem(
                  child: Text(item.country),
                  value: item,
                );
              }).toList(),
              onChanged: (newSelection) async {
                setState(() {
                  _searching = true;
                  _selectedCountry = newSelection;
                });

                await this.getNewCases(_selectedCountry.slug);
                this.getPopulation(_selectedCountry.iso2);
              },
              value: _selectedCountry,
            ),
          ),
          SizedBox(height: 25.0),
          _searching ? CircularProgressIndicator() : SizedBox(),
          SizedBox(height: 25.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 200,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "POPULATION",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.0),
                    Text(
                      _population != null ? "$_population" : "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: _limitColor,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
              SizedBox(width: 18.0),
              Container(
                width: 200,
                height: 120,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "NEW CASES",
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.0),
                    Text(
                      _newCases != null ? "$_newCases" : "",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                decoration: BoxDecoration(
                    border: Border.all(
                      color: _limitColor,
                    ),
                    borderRadius: BorderRadius.all(Radius.circular(20))),
              ),
            ],
          ),
          SizedBox(height: 50.0),
          Container(
            width: 436,
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "WEEKLY INCIDENTS PER. 100K",
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  _per100k != null ? "$_per100k" : "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            decoration: BoxDecoration(
                border: Border.all(
                  color: _limitColor,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          SizedBox(height: 25.0),
          Text("Created by Fredrik Bakken."),
          SizedBox(height: 8.0),
          LinkText(
              text:
                  "Source code for the website can be found here: https://github.com/FredrikBakken/covid19/tree/master/web"),
        ],
      ),
    );
  }
}
