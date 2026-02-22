import 'package:flutter/material.dart';

abstract class AbstractDestinationConfig<T> {
  final T destination;
  final String label;
  final IconData icon;

  const AbstractDestinationConfig({
    required this.destination,
    required this.label,
    required this.icon,
  });
}
