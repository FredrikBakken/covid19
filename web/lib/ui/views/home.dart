import 'package:covid19/models/case_model.dart';
import 'package:covid19/models/country_model.dart';
import 'package:covid19/models/population_model.dart';
import 'package:covid19/services/query_api.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:link_text/link_text.dart';

class HomeView extends StatefulWidget {
  HomeView();

  @override
  _HomeViewState createState() => new _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  QueryAPI queryAPI = new QueryAPI();

  String _selectedProvince;
  Map<String, int> _newCases = Map<String, int>();
  Map<String, int> _populations = Map<String, int>();
  Map<String, double> _per100k = Map<String, double>();
  bool _searching = false;
  Color _limitColor = Colors.grey;

  CountryModel _selectedCountry;
  List<CountryModel> _countriesModelList = List<CountryModel>();
  List<CaseModel> _casesModelList = List<CaseModel>();
  List<PopulationModel> _populationModelList = List<PopulationModel>();

  List<String> _provinceSlugs = ["denmark"]; // , "france"];

  Future getCountriesData() async {
    var responseBody = await queryAPI.getCountries();

    setState(() {
      for (var responseObject in responseBody) {
        _countriesModelList.add(CountryModel.fromJson(responseObject));
      }
      _countriesModelList.sort((a, b) => a.country.compareTo(b.country));
    });
  }

  Future getNewCases(String slug) async {
    var responseBody = await queryAPI.getCases(slug);
    Set<dynamic> provinces;

    setState(() {
      _casesModelList = List<CaseModel>();
      for (var responseObject in responseBody) {
        _casesModelList.add(CaseModel.fromJson(responseObject));
      }

      _casesModelList.sort((a, b) => a.cases.compareTo(b.cases));

      provinces = _casesModelList.map((incident) => incident.province).toSet();

      _newCases[_selectedCountry.country] =
          _casesModelList.last.cases - _casesModelList.first.cases;
    });

    if (_provinceSlugs.contains(slug)) {
      _newCases = Map<String, int>();

      for (String province in provinces) {
        List<CaseModel> provinceCases = _casesModelList
            .where((incident) => incident.province == province)
            .toList();
        int newProvinceCases =
            provinceCases.last.cases - provinceCases.first.cases;

        setState(() {
          _newCases[province.trim() == ''
              ? _selectedCountry.country
              : province] = newProvinceCases;
        });
      }
    }
  }

  Future getPopulation(String slug, String iso2) async {
    if (_provinceSlugs.contains(slug)) {
      for (String province in _newCases.keys) {
        CountryModel provinceCountry = _countriesModelList
            .where((country) => country.country == province)
            .first;

        List feedElements = await queryAPI.getPopulation(provinceCountry.iso2);

        setState(() {
          _populationModelList = List<PopulationModel>();
          for (var element in feedElements) {
            _populationModelList.add(PopulationModel.parse(element));
          }

          _populationModelList.sort((a, b) => a.date.compareTo(b.date));
          _populations[province] = _populationModelList.last.value;
          _selectedProvince = _selectedCountry.country;
        });

        getPer100k(province);
      }
    } else {
      List feedElements = await queryAPI.getPopulation(iso2);

      setState(() {
        _populationModelList = List<PopulationModel>();
        for (var element in feedElements) {
          _populationModelList.add(PopulationModel.parse(element));
        }

        _populationModelList.sort((a, b) => a.date.compareTo(b.date));
        _populations[_selectedCountry.country] =
            _populationModelList.last.value;
        _selectedProvince = _selectedCountry.country;
      });

      getPer100k(_selectedProvince);
    }
  }

  void getPer100k(String province) {
    setState(() {
      _per100k[province] =
          ((_newCases[province] / 2) / _populations[province]) * 100000;

      if (_per100k[province] >= 20.0) {
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
          SizedBox(height: 16.0),
          Container(
            width: 396,
            child: DropdownSearch<CountryModel>(
              hint: 'Select country...',
              showSearchBox: true,
              selectedItem: _selectedCountry,
              onFind: (String filter) async => _countriesModelList,
              onChanged: (CountryModel selectedCountry) async {
                setState(() {
                  _searching = true;
                  _newCases = Map<String, int>();
                  _selectedCountry = selectedCountry;
                });
                await this.getNewCases(_selectedCountry.slug);
                this.getPopulation(
                    _selectedCountry.slug, _selectedCountry.iso2);
              },
            ),
          ),
          _newCases.isNotEmpty && _newCases.keys.length > 1
              ? Column(
                  children: [
                    SizedBox(height: 15.0),
                    Container(
                      width: 396,
                      child: DropdownSearch<String>(
                        label: 'Province',
                        showSearchBox: true,
                        selectedItem: _selectedProvince,
                        onFind: (String filter) async =>
                            _newCases.keys.toList()..sort(),
                        onChanged: (String selectedProvince) async {
                          setState(() {
                            _selectedProvince = selectedProvince;
                          });
                        },
                      ),
                    ),
                  ],
                )
              : SizedBox(),
          SizedBox(height: 15.0),
          _searching ? CircularProgressIndicator() : SizedBox(),
          SizedBox(height: 15.0),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 190,
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "POPULATION",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.0),
                    Text(
                      _populations.isNotEmpty
                          ? "${_populations[_selectedProvince]}"
                          : "",
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
                width: 190,
                height: 100,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "NEW CASES",
                      style: TextStyle(
                        fontSize: 16.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 24.0),
                    Text(
                      _newCases.isNotEmpty
                          ? "${_newCases[_selectedProvince]}"
                          : "",
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
          SizedBox(height: 24.0),
          Container(
            width: 396,
            height: 120,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  "WEEKLY INCIDENTS PER. 100K",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 24.0),
                Text(
                  _per100k.isNotEmpty ? "${_per100k[_selectedProvince]}" : "",
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
          SizedBox(height: 32.0),
          Text(
            "DISCLAIMER",
            style: TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8.0),
          Center(
            child: Text(
              "This website is only intended to provide information.",
            ),
          ),
          SizedBox(height: 8.0),
          Center(
            child: Text(
              "Please check the official statements before taking any actions.",
            ),
          ),
          SizedBox(height: 24.0),
          Center(
            child: Text(
              "Created by Fredrik Bakken.",
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(height: 8.0),
          Center(
            child: Text("Source code for the website can be found here:"),
          ),
          Center(
            child: LinkText(
                text:
                    "https://github.com/FredrikBakken/covid19/tree/master/web"),
          ),
        ],
      ),
    );
  }
}
