import 'package:flutter/material.dart';
import '../../models/availability_model.dart';
import '../../services/availability_service.dart';

class CalendarExceptionsScreen extends StatefulWidget {
  final AvailabilityModel availability;
  final ValueChanged<AvailabilityModel> onUpdated;

  const CalendarExceptionsScreen({
    super.key,
    required this.availability,
    required this.onUpdated,
  });

  @override
  State<CalendarExceptionsScreen> createState() =>
      _CalendarExceptionsScreenState();
}

class _CalendarExceptionsScreenState extends State<CalendarExceptionsScreen> {
  final _availabilityService = AvailabilityService();
  late AvailabilityModel _availability;
  DateTime _focusedMonth = DateTime.now();
  bool _isLoading = false;

  final List<String> _commonReasons = [
    'Holiday',
    'Day Off',
    'Vacation',
    'Personal',
    'Medical',
    'Training',
    'Other',
  ];

  @override
  void initState() {
    super.initState();
    _availability = widget.availability;
  }

  Future<void> _addException(DateTime date, String reason) async {
    setState(() => _isLoading = true);

    try {
      final exception = DateException(
        date: date,
        reason: reason,
        isAvailable: false,
      );

      await _availabilityService.addException(_availability.id, exception);

      final updatedExceptions =
          List<DateException>.from(_availability.exceptions)..add(exception);

      setState(() {
        _availability = _availability.copyWith(exceptions: updatedExceptions);
      });
      widget.onUpdated(_availability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Blocked ${_formatDate(date)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _removeException(DateTime date) async {
    setState(() => _isLoading = true);

    try {
      await _availabilityService.removeException(_availability.id, date);

      final updatedExceptions = _availability.exceptions
          .where((e) =>
              e.date.year != date.year ||
              e.date.month != date.month ||
              e.date.day != date.day)
          .toList();

      setState(() {
        _availability = _availability.copyWith(exceptions: updatedExceptions);
      });
      widget.onUpdated(_availability);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Unblocked ${_formatDate(date)}'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAddExceptionDialog(DateTime date) {
    final reasonController = TextEditingController();
    String? selectedReason;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Block ${_formatDate(date)}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Select a reason:'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _commonReasons.map((reason) {
                return ChoiceChip(
                  label: Text(reason),
                  selected: selectedReason == reason,
                  onSelected: (selected) {
                    Navigator.pop(context);
                    if (reason == 'Other') {
                      _showCustomReasonDialog(date);
                    } else {
                      _addException(date, reason);
                    }
                  },
                );
              }).toList(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showCustomReasonDialog(DateTime date) {
    final controller = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Custom Reason'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            hintText: 'Enter reason...',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(context);
              if (controller.text.isNotEmpty) {
                _addException(date, controller.text);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  DateException? _getExceptionForDate(DateTime date) {
    try {
      return _availability.exceptions.firstWhere(
        (e) =>
            e.date.year == date.year &&
            e.date.month == date.month &&
            e.date.day == date.day,
      );
    } catch (e) {
      return null;
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Dates'),
      ),
      body: Column(
        children: [
          // Month navigation
          Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month - 1,
                        );
                      });
                    },
                  ),
                  Text(
                    '${_getMonthName(_focusedMonth.month)} ${_focusedMonth.year}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () {
                      setState(() {
                        _focusedMonth = DateTime(
                          _focusedMonth.year,
                          _focusedMonth.month + 1,
                        );
                      });
                    },
                  ),
                ],
              ),
            ),
          ),

          // Calendar grid
          Expanded(
            child: Card(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: _buildCalendarGrid(),
              ),
            ),
          ),

          // Upcoming exceptions list
          if (_availability.exceptions.isNotEmpty) ...[
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Text(
                    'Blocked Dates',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 120,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _upcomingExceptions.length,
                itemBuilder: (context, index) {
                  final exception = _upcomingExceptions[index];
                  return Card(
                    margin: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 140,
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _formatDate(exception.date),
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            exception.reason,
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Colors.grey[600],
                                    ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: () => _removeException(exception.date),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              visualDensity: VisualDensity.compact,
                            ),
                            child: const Text('Remove'),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  List<DateException> get _upcomingExceptions {
    final now = DateTime.now();
    final upcoming = _availability.exceptions
        .where((e) => e.date.isAfter(now) || _isSameDay(e.date, now))
        .toList()
      ..sort((a, b) => a.date.compareTo(b.date));
    return upcoming;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  String _getMonthName(int month) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return months[month - 1];
  }

  Widget _buildCalendarGrid() {
    final firstDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedMonth.year, _focusedMonth.month + 1, 0);
    final startOffset = firstDayOfMonth.weekday % 7; // Sunday = 0
    final daysInMonth = lastDayOfMonth.day;
    final today = DateTime.now();

    return Column(
      children: [
        // Day headers
        Row(
          children: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat']
              .map((day) => Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[600],
                            ),
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 8),

        // Calendar days
        Expanded(
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
            ),
            itemCount: 42, // 6 weeks
            itemBuilder: (context, index) {
              final dayOffset = index - startOffset + 1;

              if (dayOffset < 1 || dayOffset > daysInMonth) {
                return const SizedBox.shrink();
              }

              final date =
                  DateTime(_focusedMonth.year, _focusedMonth.month, dayOffset);
              final isToday = _isSameDay(date, today);
              final isPast =
                  date.isBefore(DateTime(today.year, today.month, today.day));
              final exception = _getExceptionForDate(date);
              final isBlocked = exception != null && !exception.isAvailable;
              final dayKey = WeekDays.fromDateTime(date);
              final isWorkingDay =
                  _availability.weeklySchedule[dayKey]?.isAvailable ?? false;

              return InkWell(
                onTap: isPast
                    ? null
                    : () {
                        if (isBlocked) {
                          _removeException(date);
                        } else {
                          _showAddExceptionDialog(date);
                        }
                      },
                child: Container(
                  margin: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: isBlocked
                        ? Colors.red[100]
                        : isToday
                            ? Theme.of(context).colorScheme.primaryContainer
                            : null,
                    border: Border.all(
                      color: isToday
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[300]!,
                      width: isToday ? 2 : 1,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Stack(
                    children: [
                      Center(
                        child: Text(
                          '$dayOffset',
                          style: TextStyle(
                            color: isPast
                                ? Colors.grey[400]
                                : isBlocked
                                    ? Colors.red[800]
                                    : null,
                            fontWeight: isToday ? FontWeight.bold : null,
                          ),
                        ),
                      ),
                      if (!isWorkingDay && !isBlocked)
                        Positioned(
                          bottom: 2,
                          left: 0,
                          right: 0,
                          child: Center(
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.grey[400],
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      if (isBlocked)
                        Positioned(
                          top: 2,
                          right: 2,
                          child: Icon(
                            Icons.block,
                            size: 12,
                            color: Colors.red[700],
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
