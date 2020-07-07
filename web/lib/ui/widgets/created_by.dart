import 'package:flutter/material.dart';
import 'package:link_text/link_text.dart';
import 'package:url_launcher/url_launcher.dart';

Widget createdBy() {
  String githubUrl = "https://github.com/FredrikBakken/covid19/tree/master/web";

  return Column(
    children: [
      Text(
        "Created by Fredrik Bakken.",
        style: TextStyle(
          fontWeight: FontWeight.bold,
        ),
      ),
      SizedBox(height: 8.0),
      Text("Source code for the website can be found here:"),
      GestureDetector(
        child: LinkText(text: githubUrl),
        onTap: () => launch(githubUrl),
      ),
    ],
  );
}
