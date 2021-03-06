import 'package:covid19/models/case_model.dart';
import 'package:covid19/models/country_model.dart';
import 'package:covid19/models/population_model.dart';
import 'package:covid19/services/query_api.dart';
import 'package:covid19/ui/widgets/created_by.dart';
import 'package:covid19/ui/widgets/disclaimer.dart';
import 'package:covid19/utils/country_filters.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class HomeView extends StatefulWidget {
  HomeView();

  @override
  _HomeViewState createState() => new _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  CountryFilters countryFilters = new CountryFilters();
  QueryAPI queryAPI = new QueryAPI();

  String _selectedProvince;
  bool _searching = false;

  Map<String, int> _newCases = Map<String, int>();
  Map<String, int> _populations = Map<String, int>();
  Map<String, double> _per100k = Map<String, double>();
  Map<String, Color> _limitColor = Map<String, Color>();

  CountryModel _selectedCountry;
  List<CountryModel> _countriesModelList = List<CountryModel>();
  List<CountryModel> _countriesModelListView = List<CountryModel>();
  List<CaseModel> _casesModelList = List<CaseModel>();
  List<PopulationModel> _populationModelList = List<PopulationModel>();

  Future getCountriesData() async {
    var responseBody = await queryAPI.getCountries();

    setState(() {
      for (var responseObject in responseBody) {
        CountryModel country = CountryModel.fromJson(responseObject);
        _countriesModelList.add(country);

        if (!countryFilters.filteredCountries.containsKey(country.country)) {
          _countriesModelListView.add(country);
        }
      }
      _countriesModelListView.sort((a, b) => a.country.compareTo(b.country));
    });
  }

  Future getNewCases(String slug) async {
    final DateTime now = DateTime.now();
    final DateTime dayZero = now.subtract(Duration(days: 15));
    final DateTime yesterday = now.subtract(Duration(days: 1));

    final DateFormat formatter = new DateFormat('yyyy-MM-dd');
    final String fromDate = formatter.format(dayZero) + "T00:00:00Z";
    final String toDate = formatter.format(yesterday) + "T00:00:00Z";

    var responseBody = await queryAPI.getCases(slug, fromDate, toDate);
    //print(responseBody); // Debug

    Set<dynamic> provinces;

    setState(() {
      _newCases = Map<String, int>();
      _casesModelList = List<CaseModel>();

      for (dynamic responseObject in responseBody)
        _casesModelList.add(CaseModel.fromJson(responseObject));
      _casesModelList.sort((a, b) => a.cases.compareTo(b.cases));
    });

    if (countryFilters.exceptionCountries
        .containsKey(_selectedCountry.country)) {
      int startCases = _casesModelList
          .where((incident) => incident.date == fromDate)
          .toList()
          .map((incident) => incident.cases)
          .reduce((a, b) => a + b);
      int stopCases = _casesModelList
          .where((incident) => incident.date == toDate)
          .toList()
          .map((incident) => incident.cases)
          .reduce((a, b) => a + b);

      setState(() {
        _newCases[_selectedCountry.country] = stopCases - startCases;
      });
    } else {
      provinces = _casesModelList.map((incident) => incident.province).toSet();

      for (String province in provinces) {
        List<CaseModel> provinceCases = _casesModelList
            .where((incident) => incident.province == province)
            .toList();
        int newProvinceCases =
            provinceCases.last.cases - provinceCases.first.cases;

        //print(newProvinceCases); // Debug

        setState(() {
          _newCases[province.trim() == ''
              ? _selectedCountry.country
              : province] = newProvinceCases;
        });
      }
    }
  }

  Future getPopulation(String slug, String iso2) async {
    List<String> toRemove = [];

    for (String province in _newCases.keys) {
      try {
        CountryModel provinceCountry = _countriesModelList
            .where((country) => country.country == province)
            .first;

        List feedElements = await queryAPI.getPopulation(provinceCountry.iso2);
        //print(feedElements); // Debug

        setState(() {
          _populationModelList = List<PopulationModel>();
          for (var element in feedElements) {
            try {
              _populationModelList.add(PopulationModel.parse(element));
            } catch (e) {
              continue;
            }
          }
          _populationModelList.sort((a, b) => a.date.compareTo(b.date));
          _populations[province] = _populationModelList.last.value;

          //print(province); // Debug
          //print(_populationModelList.last.value); // Debug

          _selectedProvince = _selectedCountry.country;
        });

        getPer100k(province);
      } catch (e) {
        toRemove.add(province);
      }
    }

    for (String provinceToRemove in toRemove) {
      setState(() {
        _newCases.remove(provinceToRemove);
      });
    }

    setState(() {
      _searching = false;
    });
  }

  void getPer100k(String province) {
    setState(() {
      _per100k[province] =
          ((_newCases[province] / 2) / _populations[province]) * 100000;

      if (_per100k[province] >= 20.0) {
        _limitColor[province] = Colors.red;
      } else {
        _limitColor[province] = Colors.green;
      }
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
              onFind: (_) async => _countriesModelListView,
              onChanged: (CountryModel selectedCountry) async {
                //print(selectedCountry.country); // Debug
                setState(() {
                  _searching = true;
                  _newCases = Map<String, int>();
                  _populations = Map<String, int>();
                  _per100k = Map<String, double>();
                  _limitColor = Map<String, Color>();
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
                        onFind: (_) async => _newCases.keys.toList()..sort(),
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
                    SizedBox(height: 16.0),
                    Text(
                      _populations.isNotEmpty && _populations != null
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
                      color: _limitColor.isNotEmpty
                          ? _limitColor[_selectedProvince]
                          : Colors.grey,
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
                    SizedBox(height: 16.0),
                    Text(
                      _newCases.isNotEmpty && _newCases != null
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
                      color: _limitColor.isNotEmpty
                          ? _limitColor[_selectedProvince]
                          : Colors.grey,
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
                  "WEEKLY INCIDENTS",
                  style: TextStyle(
                    fontSize: 20.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16.0),
                Text(
                  _per100k.isNotEmpty && _per100k != null
                      ? _per100k[_selectedProvince] == 0
                          ? "0"
                          : "${_per100k[_selectedProvince].toStringAsFixed(3)}"
                      : "",
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 12.0),
                Text(
                  _per100k.isNotEmpty && _per100k != null
                      ? _per100k[_selectedProvince] == 0
                          ? "new cases per. 100k citizen"
                          : "new cases per. 100k citizen"
                      : "",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            decoration: BoxDecoration(
                border: Border.all(
                  color: _limitColor.isNotEmpty
                      ? _limitColor[_selectedProvince]
                      : Colors.grey,
                ),
                borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
          SizedBox(height: 32.0),
          disclaimer(),
          SizedBox(height: 24.0),
          createdBy(),
        ],
      ),
    );
  }
}
