import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:xml/xml.dart';

class QueryAPI {
  Future<dynamic> getCountries() async {
    final String countriesUrl = "https://api.covid19api.com/countries";
    dynamic response = await http.get(Uri.encodeFull(countriesUrl),
        headers: {"Accept": "application/json"});

    return json.decode(response.body);
  }

  Future<dynamic> getCases(String slug, String fromDate, String toDate) async {
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
