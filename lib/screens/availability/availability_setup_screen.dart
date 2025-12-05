import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/availability_model.dart';
import '../../services/availability_service.dart';
import '../../services/auth_service.dart';
import 'calendar_exceptions_screen.dart';

class AvailabilitySetupScreen extends StatefulWidget {
  final String? businessId;
  final String? businessName;

  const AvailabilitySetupScreen({
    super.key,
    this.businessId,
    this.businessName,
  });

  @override
  State<AvailabilitySetupScreen> createState() =>
      _AvailabilitySetupScreenState();
}

class _AvailabilitySetupScreenState extends State<AvailabilitySetupScreen> {
  final _availabilityService = AvailabilityService();
  AvailabilityModel? _availability;
  bool _isLoading = true;
  bool _isSaving = false;

  final List<int> _slotDurations = [15, 30, 45, 60];

  @override
  void initState() {
    super.initState();
    _loadAvailability();
  }

  Future<void> _loadAvailability() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final userId = authService.currentUser?.uid;

    if (userId == null) return;

    setState(() => _isLoading = true);

    try {
      final availability = await _availabilityService.getOrCreateAvailability(
        userId,
        businessId: widget.businessId,
      );
      if (mounted) {
        setState(() {
          _availability = availability;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading availability: $e')),
        );
      }
    }
  }

  Future<void> _saveAvailability() async {
    if (_availability == null) return;

    setState(() => _isSaving = true);

    try {
      await _availabilityService.saveAvailability(_availability!);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Availability saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _updateDaySchedule(String day, DaySchedule schedule) {
    if (_availability == null) return;

    final updatedSchedule =
        Map<String, DaySchedule>.from(_availability!.weeklySchedule);
    updatedSchedule[day] = schedule;

    setState(() {
      _availability = _availability!.copyWith(weeklySchedule: updatedSchedule);
    });
  }

  void _updateSlotDuration(int minutes) {
    if (_availability == null) return;

    setState(() {
      _availability = _availability!.copyWith(slotDurationMinutes: minutes);
    });
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.businessName != null
        ? '${widget.businessName} Hours'
        : 'My Availability';

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_month),
            tooltip: 'Manage Exceptions',
            onPressed: _availability == null
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CalendarExceptionsScreen(
                          availability: _availability!,
                          onUpdated: (updated) {
                            setState(() => _availability = updated);
                          },
                        ),
                      ),
                    );
                  },
          ),
          IconButton(
            icon: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            onPressed: _isSaving ? null : _saveAvailability,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _availability == null
              ? const Center(child: Text('Unable to load availability'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Slot duration selector
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Appointment Duration',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Default length for each appointment slot',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: Colors.grey[600],
                                  ),
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<int>(
                              segments: _slotDurations.map((duration) {
                                return ButtonSegment(
                                  value: duration,
                                  label: Text('$duration min'),
                                );
                              }).toList(),
                              selected: {_availability!.slotDurationMinutes},
                              onSelectionChanged: (selected) {
                                _updateSlotDuration(selected.first);
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Weekly schedule
                    Text(
                      'Weekly Schedule',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Set your working hours for each day',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey[600],
                          ),
                    ),
                    const SizedBox(height: 16),

                    // Day cards
                    ...WeekDays.all.map((day) {
                      final schedule = _availability!.weeklySchedule[day] ??
                          DaySchedule.dayOff();
                      return _DayScheduleCard(
                        day: day,
                        schedule: schedule,
                        onChanged: (newSchedule) =>
                            _updateDaySchedule(day, newSchedule),
                      );
                    }),

                    const SizedBox(height: 16),

                    // Exceptions info card
                    Card(
                      color: Colors.orange[50],
                      child: ListTile(
                        leading:
                            Icon(Icons.event_busy, color: Colors.orange[700]),
                        title: Text(
                          'Blocked Dates',
                          style: TextStyle(color: Colors.orange[900]),
                        ),
                        subtitle: Text(
                          '${_availability!.exceptions.length} exceptions set',
                          style: TextStyle(color: Colors.orange[800]),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CalendarExceptionsScreen(
                                availability: _availability!,
                                onUpdated: (updated) {
                                  setState(() => _availability = updated);
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Save button
                    FilledButton(
                      onPressed: _isSaving ? null : _saveAvailability,
                      child: _isSaving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Changes'),
                    ),
                  ],
                ),
    );
  }
}

class _DayScheduleCard extends StatelessWidget {
  final String day;
  final DaySchedule schedule;
  final ValueChanged<DaySchedule> onChanged;

  const _DayScheduleCard({
    required this.day,
    required this.schedule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    WeekDays.displayName(day),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ),
                Switch(
                  value: schedule.isAvailable,
                  onChanged: (value) {
                    if (value) {
                      onChanged(DaySchedule.defaultWorkDay());
                    } else {
                      onChanged(DaySchedule.dayOff());
                    }
                  },
                ),
              ],
            ),
            if (schedule.isAvailable && schedule.slots.isNotEmpty) ...[
              const Divider(),
              ...schedule.slots.asMap().entries.map((entry) {
                final index = entry.key;
                final slot = entry.value;
                return _TimeRangeRow(
                  slot: slot,
                  onChanged: (newSlot) {
                    final newSlots = List<TimeRange>.from(schedule.slots);
                    newSlots[index] = newSlot;
                    onChanged(schedule.copyWith(slots: newSlots));
                  },
                  onRemove: schedule.slots.length > 1
                      ? () {
                          final newSlots = List<TimeRange>.from(schedule.slots);
                          newSlots.removeAt(index);
                          onChanged(schedule.copyWith(slots: newSlots));
                        }
                      : null,
                );
              }),
              TextButton.icon(
                onPressed: () {
                  final lastSlot = schedule.slots.last;
                  final newSlots = List<TimeRange>.from(schedule.slots);
                  newSlots.add(TimeRange(start: lastSlot.end, end: '18:00'));
                  onChanged(schedule.copyWith(slots: newSlots));
                },
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add time slot'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _TimeRangeRow extends StatelessWidget {
  final TimeRange slot;
  final ValueChanged<TimeRange> onChanged;
  final VoidCallback? onRemove;

  const _TimeRangeRow({
    required this.slot,
    required this.onChanged,
    this.onRemove,
  });

  Future<void> _selectTime(BuildContext context, bool isStart) async {
    final parts = (isStart ? slot.start : slot.end).split(':');
    final initialTime = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      final timeString =
          '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
      if (isStart) {
        onChanged(TimeRange(start: timeString, end: slot.end));
      } else {
        onChanged(TimeRange(start: slot.start, end: timeString));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () => _selectTime(context, true),
              child: Text(slot.start),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Text('to'),
          ),
          Expanded(
            child: OutlinedButton(
              onPressed: () => _selectTime(context, false),
              child: Text(slot.end),
            ),
          ),
          if (onRemove != null)
            IconButton(
              icon: const Icon(Icons.remove_circle_outline, size: 20),
              color: Colors.red,
              onPressed: onRemove,
            ),
        ],
      ),
    );
  }
}
