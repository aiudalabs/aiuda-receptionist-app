import 'package:cloud_firestore/cloud_firestore.dart';

/// Represents a time range with start and end times (e.g., "09:00" - "12:00")
class TimeRange {
  final String start; // Format: "HH:mm" (24h)
  final String end; // Format: "HH:mm" (24h)

  TimeRange({
    required this.start,
    required this.end,
  });

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      start: map['start'] ?? '09:00',
      end: map['end'] ?? '17:00',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'start': start,
      'end': end,
    };
  }

  /// Check if a given time falls within this range
  bool containsTime(String time) {
    return time.compareTo(start) >= 0 && time.compareTo(end) < 0;
  }

  /// Get duration in minutes
  int get durationMinutes {
    final startParts = start.split(':');
    final endParts = end.split(':');
    final startMinutes =
        int.parse(startParts[0]) * 60 + int.parse(startParts[1]);
    final endMinutes = int.parse(endParts[0]) * 60 + int.parse(endParts[1]);
    return endMinutes - startMinutes;
  }
}

/// Schedule for a single day (e.g., Monday)
class DaySchedule {
  final bool isAvailable;
  final List<TimeRange> slots; // Can have multiple ranges (morning, afternoon)

  DaySchedule({
    required this.isAvailable,
    this.slots = const [],
  });

  factory DaySchedule.fromMap(Map<String, dynamic> map) {
    final slotsData = map['slots'] as List<dynamic>? ?? [];
    return DaySchedule(
      isAvailable: map['isAvailable'] ?? false,
      slots: slotsData
          .map((slot) => TimeRange.fromMap(slot as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isAvailable': isAvailable,
      'slots': slots.map((slot) => slot.toMap()).toList(),
    };
  }

  /// Default working day (9 AM - 5 PM)
  factory DaySchedule.defaultWorkDay() {
    return DaySchedule(
      isAvailable: true,
      slots: [TimeRange(start: '09:00', end: '17:00')],
    );
  }

  /// Day off
  factory DaySchedule.dayOff() {
    return DaySchedule(isAvailable: false, slots: []);
  }

  DaySchedule copyWith({
    bool? isAvailable,
    List<TimeRange>? slots,
  }) {
    return DaySchedule(
      isAvailable: isAvailable ?? this.isAvailable,
      slots: slots ?? this.slots,
    );
  }
}

/// Exception for a specific date (holiday, day off, etc.)
class DateException {
  final DateTime date;
  final String reason;
  final bool isAvailable; // false = blocked, true = special availability

  DateException({
    required this.date,
    required this.reason,
    this.isAvailable = false,
  });

  factory DateException.fromMap(Map<String, dynamic> map) {
    return DateException(
      date: (map['date'] as Timestamp).toDate(),
      reason: map['reason'] ?? '',
      isAvailable: map['isAvailable'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': Timestamp.fromDate(date),
      'reason': reason,
      'isAvailable': isAvailable,
    };
  }
}

/// Days of the week keys
class WeekDays {
  static const String monday = 'monday';
  static const String tuesday = 'tuesday';
  static const String wednesday = 'wednesday';
  static const String thursday = 'thursday';
  static const String friday = 'friday';
  static const String saturday = 'saturday';
  static const String sunday = 'sunday';

  static const List<String> all = [
    monday,
    tuesday,
    wednesday,
    thursday,
    friday,
    saturday,
    sunday,
  ];

  static String fromDateTime(DateTime date) {
    return all[date.weekday - 1];
  }

  static String displayName(String day) {
    return day[0].toUpperCase() + day.substring(1);
  }
}

/// Main availability model for a provider
class AvailabilityModel {
  final String id;
  final String providerId;
  final String? businessId; // null = independent schedule
  final int slotDurationMinutes; // 15, 30, 45, 60
  final Map<String, DaySchedule> weeklySchedule;
  final List<DateException> exceptions;
  final DateTime updatedAt;

  AvailabilityModel({
    required this.id,
    required this.providerId,
    this.businessId,
    this.slotDurationMinutes = 30,
    required this.weeklySchedule,
    this.exceptions = const [],
    required this.updatedAt,
  });

  factory AvailabilityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    // Parse weekly schedule
    final scheduleData = data['weeklySchedule'] as Map<String, dynamic>? ?? {};
    final weeklySchedule = <String, DaySchedule>{};

    for (final day in WeekDays.all) {
      if (scheduleData.containsKey(day)) {
        weeklySchedule[day] =
            DaySchedule.fromMap(scheduleData[day] as Map<String, dynamic>);
      } else {
        // Default: Mon-Fri working, Sat-Sun off
        weeklySchedule[day] =
            (day == WeekDays.saturday || day == WeekDays.sunday)
                ? DaySchedule.dayOff()
                : DaySchedule.defaultWorkDay();
      }
    }

    // Parse exceptions
    final exceptionsData = data['exceptions'] as List<dynamic>? ?? [];
    final exceptions = exceptionsData
        .map((e) => DateException.fromMap(e as Map<String, dynamic>))
        .toList();

    return AvailabilityModel(
      id: doc.id,
      providerId: data['providerId'] ?? '',
      businessId: data['businessId'],
      slotDurationMinutes: data['slotDurationMinutes'] ?? 30,
      weeklySchedule: weeklySchedule,
      exceptions: exceptions,
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    final scheduleMap = <String, dynamic>{};
    weeklySchedule.forEach((day, schedule) {
      scheduleMap[day] = schedule.toMap();
    });

    return {
      'providerId': providerId,
      'businessId': businessId,
      'slotDurationMinutes': slotDurationMinutes,
      'weeklySchedule': scheduleMap,
      'exceptions': exceptions.map((e) => e.toMap()).toList(),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Create a default availability (Mon-Fri 9-5, Sat-Sun off)
  factory AvailabilityModel.defaultSchedule({
    required String providerId,
    String? businessId,
  }) {
    return AvailabilityModel(
      id: '',
      providerId: providerId,
      businessId: businessId,
      slotDurationMinutes: 30,
      weeklySchedule: {
        WeekDays.monday: DaySchedule.defaultWorkDay(),
        WeekDays.tuesday: DaySchedule.defaultWorkDay(),
        WeekDays.wednesday: DaySchedule.defaultWorkDay(),
        WeekDays.thursday: DaySchedule.defaultWorkDay(),
        WeekDays.friday: DaySchedule.defaultWorkDay(),
        WeekDays.saturday: DaySchedule.dayOff(),
        WeekDays.sunday: DaySchedule.dayOff(),
      },
      exceptions: [],
      updatedAt: DateTime.now(),
    );
  }

  /// Check if a specific date is blocked by an exception
  DateException? getExceptionForDate(DateTime date) {
    try {
      return exceptions.firstWhere(
        (e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if provider is available on a specific date
  bool isAvailableOnDate(DateTime date) {
    // First check exceptions
    final exception = getExceptionForDate(date);
    if (exception != null) {
      return exception.isAvailable;
    }

    // Fall back to weekly schedule
    final dayKey = WeekDays.fromDateTime(date);
    return weeklySchedule[dayKey]?.isAvailable ?? false;
  }

  /// Get schedule for a specific date (considering exceptions)
  DaySchedule? getScheduleForDate(DateTime date) {
    if (!isAvailableOnDate(date)) return null;

    final dayKey = WeekDays.fromDateTime(date);
    return weeklySchedule[dayKey];
  }

  /// Generate time slots for a specific date
  List<String> generateSlotsForDate(DateTime date) {
    final schedule = getScheduleForDate(date);
    if (schedule == null || !schedule.isAvailable) return [];

    final slots = <String>[];
    for (final range in schedule.slots) {
      var current = _parseTime(range.start);
      final end = _parseTime(range.end);

      while (current < end) {
        slots.add(_formatTime(current));
        current += slotDurationMinutes;
      }
    }

    return slots;
  }

  int _parseTime(String time) {
    final parts = time.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  String _formatTime(int minutes) {
    final hours = minutes ~/ 60;
    final mins = minutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${mins.toString().padLeft(2, '0')}';
  }

  AvailabilityModel copyWith({
    String? id,
    String? providerId,
    String? businessId,
    int? slotDurationMinutes,
    Map<String, DaySchedule>? weeklySchedule,
    List<DateException>? exceptions,
    DateTime? updatedAt,
  }) {
    return AvailabilityModel(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      businessId: businessId ?? this.businessId,
      slotDurationMinutes: slotDurationMinutes ?? this.slotDurationMinutes,
      weeklySchedule: weeklySchedule ?? this.weeklySchedule,
      exceptions: exceptions ?? this.exceptions,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
