import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:xml/xml.dart';

class QueryAPI {
  Future<dynamic> getCountries() async {
    final String countriesUrl = "https://api.covid19api.com/countries";
    dynamic response = await http.get(Uri.encodeFull(countriesUrl),
        headers: {"Accept": "application/json"});

    return json.decode(response.body);
  }

  Future<dynamic> getCases(String slug) async {
    final DateTime now = DateTime.now();
    final DateTime dayZero = now.subtract(Duration(days: 15));
    final DateTime yesterday = now.subtract(Duration(days: 1));

    final DateFormat formatter = new DateFormat('yyyy-MM-dd');
    final String fromDate = formatter.format(dayZero) + "T00:00:00Z";
    final String toDate = formatter.format(yesterday) + "T00:00:00Z";

    final String casesUrl =
        "https://api.covid19api.com/country/$slug/status/confirmed?from=$fromDate&to=$toDate";
    var response = await http
        .get(Uri.encodeFull(casesUrl), headers: {"Accept": "application/json"});

    return json.decode(response.body);
  }

  Future<List<dynamic>> getPopulation(String iso2) async {
    final String populationUrl =
        "https://api.worldbank.org/v2/country/$iso2/indicator/SP.POP.TOTL";
    var response = await http
        .get(Uri.encodeFull(populationUrl), headers: {"Accept": "text/xml"});
    String xmlResponse = response.body.substring(response.body.indexOf("<"));

    var document = XmlDocument.parse(xmlResponse);
    XmlElement feedElement = document.findAllElements("wb:data").first;
    return feedElement.findAllElements("wb:data").toList();
  }
}
