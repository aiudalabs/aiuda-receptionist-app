import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/user_model.dart';
import '../../models/service_model.dart';
import '../../services/appointment_service.dart';
import '../client/my_appointments_screen.dart';

/// Step 3: Confirm Booking
class BookingConfirmationScreen extends StatefulWidget {
  final UserModel client;
  final UserModel provider;
  final ServiceModel service;
  final DateTime date;
  final String time;
  final String? businessId;

  const BookingConfirmationScreen({
    super.key,
    required this.client,
    required this.provider,
    required this.service,
    required this.date,
    required this.time,
    this.businessId,
  });

  @override
  State<BookingConfirmationScreen> createState() =>
      _BookingConfirmationScreenState();
}

class _BookingConfirmationScreenState extends State<BookingConfirmationScreen> {
  final _appointmentService = AppointmentService();
  final _notesController = TextEditingController();
  bool _isBooking = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _confirmBooking() async {
    setState(() => _isBooking = true);

    try {
      await _appointmentService.createAppointment(
        client: widget.client,
        provider: widget.provider,
        service: widget.service,
        date: widget.date,
        time: widget.time,
        businessId: widget.businessId,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      if (mounted) {
        // Navigate to appointments screen
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MyAppointmentsScreen(),
          ),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Appointment booked successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBooking = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('EEEE, MMMM d, y');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Confirm Booking'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Provider info
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundImage: widget.provider.profileImageUrl != null
                        ? NetworkImage(widget.provider.profileImageUrl!)
                        : null,
                    child: widget.provider.profileImageUrl == null
                        ? Text(
                            widget.provider.businessName.isNotEmpty
                                ? widget.provider.businessName[0].toUpperCase()
                                : 'P',
                            style: const TextStyle(fontSize: 24),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.provider.businessName.isNotEmpty
                              ? widget.provider.businessName
                              : 'Provider',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        if (widget.provider.professionalInfo?.title != null)
                          Text(
                            widget.provider.professionalInfo!.title,
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Appointment details
          const Text(
            'Appointment Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),

          Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.spa,
                  label: 'Service',
                  value: widget.service.name,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.calendar_today,
                  label: 'Date',
                  value: dateFormat.format(widget.date),
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.access_time,
                  label: 'Time',
                  value: widget.time,
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.timer,
                  label: 'Duration',
                  value: '${widget.service.durationMinutes} minutes',
                ),
                const Divider(height: 1),
                _DetailRow(
                  icon: Icons.attach_money,
                  label: 'Price',
                  value: '\$${widget.service.price.toStringAsFixed(2)}',
                  valueColor: Colors.green[700],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Notes
          TextField(
            controller: _notesController,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              hintText: 'Add any special requests or notes...',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Info card
          Card(
            color: Colors.blue[50],
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Your appointment is pending confirmation from the provider.',
                      style: TextStyle(
                        color: Colors.blue[900],
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Confirm button
          FilledButton(
            onPressed: _isBooking ? null : _confirmBooking,
            child: _isBooking
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Text('Confirm Booking'),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey[600]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: valueColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
