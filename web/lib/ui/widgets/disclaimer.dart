import 'package:flutter/material.dart';

Widget disclaimer() {
  return Column(
    children: [
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
    ],
  );
}
