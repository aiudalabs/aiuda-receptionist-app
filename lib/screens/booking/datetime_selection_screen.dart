import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/appointment_service.dart';
import '../../services/auth_service.dart';
import 'booking_confirmation_screen.dart';

/// Step 2: Select Date and Time
class DateTimeSelectionScreen extends StatefulWidget {
  final UserModel provider;
  final ServiceModel service;
  final String? businessId;

  const DateTimeSelectionScreen({
    super.key,
    required this.provider,
    required this.service,
    this.businessId,
  });

  @override
  State<DateTimeSelectionScreen> createState() =>
      _DateTimeSelectionScreenState();
}

class _DateTimeSelectionScreenState extends State<DateTimeSelectionScreen> {
  final _appointmentService = AppointmentService();

  DateTime _selectedDate = DateTime.now();
  String? _selectedTime;
  List<String> _availableSlots = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableSlots();
  }

  Future<void> _loadAvailableSlots() async {
    setState(() => _isLoading = true);

    try {
      final slots = await _appointmentService.getAvailableSlots(
        widget.provider.id,
        _selectedDate,
        businessId: widget.businessId,
      );

      if (mounted) {
        setState(() {
          _availableSlots = slots;
          _selectedTime = null; // Reset selection when date changes
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onDateSelected(DateTime selectedDay, DateTime focusedDay) {
    setState(() {
      _selectedDate = selectedDay;
    });
    _loadAvailableSlots();
  }

  void _continue() async {
    if (_selectedTime == null) return;

    final authService = Provider.of<AuthService>(context, listen: false);
    final client = await authService.getUserProfile(
      authService.currentUser?.uid ?? '',
    );

    if (client == null || !mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationScreen(
          client: client,
          provider: widget.provider,
          service: widget.service,
          date: _selectedDate,
          time: _selectedTime!,
          businessId: widget.businessId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Date & Time'),
      ),
      body: Column(
        children: [
          // Calendar
          TableCalendar(
            firstDay: DateTime.now(),
            lastDay: DateTime.now().add(const Duration(days: 90)),
            focusedDay: _selectedDate,
            selectedDayPredicate: (day) => isSameDay(_selectedDate, day),
            onDaySelected: _onDateSelected,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Month'},
            headerStyle: const HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
            ),
          ),

          const Divider(),

          // Time slots
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _availableSlots.isEmpty
                    ? Center(
                        child: Text(
                          'No available slots for this date',
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      )
                    : _buildTimeSlots(),
          ),

          // Continue button
          if (_selectedTime != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: const Text('Continue'),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTimeSlots() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 2.5,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _availableSlots.length,
      itemBuilder: (context, index) {
        final slot = _availableSlots[index];
        final isSelected = slot == _selectedTime;

        return OutlinedButton(
          onPressed: () {
            setState(() => _selectedTime = slot);
          },
          style: OutlinedButton.styleFrom(
            backgroundColor:
                isSelected ? Theme.of(context).colorScheme.primary : null,
            foregroundColor: isSelected ? Colors.white : null,
          ),
          child: Text(slot),
        );
      },
    );
  }
}
