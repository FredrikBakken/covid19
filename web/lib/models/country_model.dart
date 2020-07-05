class CountryModel {
  String country;
  String slug;
  String iso2;

  CountryModel({
    this.country,
    this.slug,
    this.iso2,
  });

  factory CountryModel.fromJson(Map<String, dynamic> json) => CountryModel(
    country: json['Country'],
    slug: json['Slug'],
    iso2: json['ISO2'],
  );

  Map<String, dynamic> toJson() => {
    'Country': country,
    'Slug': slug,
    'ISO2': iso2,
  };
}
