import 'dart:convert';
import 'package:http/http.dart' as http;
  
main() async {
  String _countriesUrl = "https://api.covid19api.com/countries";

  var response = await http.get(Uri.encodeFull(_countriesUrl), headers: {"Accept": "application/json"});
  var responseBody = json.decode(response.body);
  
  
  print(responseBody);
}
