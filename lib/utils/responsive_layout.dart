// Responsive layout helpers for my-pocket
import 'package:flutter/material.dart';

bool isMobile(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width < 600;
}

bool isTablet(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 600 && width < 1024;
}

bool isDesktop(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  return width >= 1024;
}
