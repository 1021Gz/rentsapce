import 'package:flutter/material.dart';

class AvailabilityStore {
  AvailabilityStore._();
  static final instance = AvailabilityStore._();

  final open = List<bool>.filled(7, true);
  final starts = List<TimeOfDay>.filled(7, const TimeOfDay(hour: 9, minute: 0));
  final ends = List<TimeOfDay>.filled(7, const TimeOfDay(hour: 18, minute: 0));

  bool accepts(DateTime date, int startMinutes, int endMinutes) {
    final dayIndex = date.weekday - 1;
    final openMinutes = starts[dayIndex].hour * 60 + starts[dayIndex].minute;
    final closeMinutes = ends[dayIndex].hour * 60 + ends[dayIndex].minute;
    return open[dayIndex] &&
        startMinutes >= openMinutes &&
        endMinutes <= closeMinutes;
  }
}
