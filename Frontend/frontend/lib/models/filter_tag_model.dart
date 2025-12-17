import 'package:flutter/material.dart';

/// Model cho Tag Filter
class FilterTag {
  final String id;
  final String label;
  final IconData? icon;

  FilterTag({
    required this.id,
    required this.label,
    this.icon,
  });
}
