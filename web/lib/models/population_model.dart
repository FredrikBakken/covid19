import 'package:xml/xml.dart';

class PopulationModel {
  String indicator;
  String country;
  String countryIso3Code;
  int date;
  int value;
  String unit;
  String obsStatus;
  String decimal;

  PopulationModel({
    this.indicator,
    this.country,
    this.countryIso3Code,
    this.date,
    this.value,
    this.unit,
    this.obsStatus,
    this.decimal,
  });

  factory PopulationModel.parse(XmlElement element) {
    return PopulationModel(
      indicator: element.findAllElements("wb:indicator").first?.text,
      country: element.findAllElements("wb:country").first?.text,
      countryIso3Code: element.findAllElements("wb:countryiso3code").first?.text,
      date: int.parse(element.findAllElements("wb:date").first?.text),
      value: int.parse(element.findAllElements("wb:value").first?.text),
      unit: element.findAllElements("wb:unit").first?.text,
      obsStatus: element.findAllElements("wb:obs_status").first?.text,
      decimal: element.findAllElements("wb:decimal").first?.text,
    );
  }
}
