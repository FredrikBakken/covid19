class CaseModel {
  String country;
  String countryCode;
  String province;
  String city;
  String cityCode;
  String lat;
  String lon;
  int cases;
  String status;
  String date;

  CaseModel({
    this.country,
    this.countryCode,
    this.province,
    this.city,
    this.cityCode,
    this.lat,
    this.lon,
    this.cases,
    this.status,
    this.date,
  });

  factory CaseModel.fromJson(Map<String, dynamic> json) => CaseModel(
    country:     json['Country'],
    countryCode: json['CountryCode'],
    province:    json['Province'],
    city:        json['City'],
    cityCode:    json['CityCode'],
    lat:         json['Lat'],
    lon:         json['Lon'],
    cases:       json['Cases'],
    status:      json['Status'],
    date:        json['Date'],
  );

  Map<String, dynamic> toJson() => {
    'Country':     country,
    'CountryCode': countryCode,
    'Province':    province,
    'City':        city,
    'CityCode':    cityCode,
    'Lat':         lat,
    'Lon':         lon,
    'Cases':       cases,
    'Status':      status,
    'Date':        date,
  };
}
