import 'package:flutter/material.dart';

class LeaveController {
  String? validate({
    required String? type,
    required DateTimeRange? range,
    required String reason,
    required bool halfDay,
    required String? halfSlot,
    required String? attachment,
  }) {

    if (type == null) {
      return "Leave type required";
    }

    if (range == null) {
      return "Date range required";
    }

    if (range.start.isAfter(range.end)) {
      return "Start date invalid";
    }

    if (reason.trim().isEmpty) {
      return "Reason required";
    }

    if (halfDay) {
      if (range.duration.inDays + 1 != 1) {
        return "Half day only for one day";
      }
      if (halfSlot == null) {
        return "Choose half day slot";
      }
    }

    if (type == "Sick Leave" || type == "Emergency Leave") {
      if (attachment == null) {
        return "Attachment required";
      }
    }

    return null;
  }
}
