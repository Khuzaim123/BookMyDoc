import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DoctorEarningsScreen extends StatefulWidget {
  const DoctorEarningsScreen({super.key});

  @override
  State<DoctorEarningsScreen> createState() => _DoctorEarningsScreenState();
}

class _DoctorEarningsScreenState extends State<DoctorEarningsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  // Dummy data
  final Doctor doctor = Doctor(
    id: 'doc1',
    name: 'Dr. John Smith',
    email: 'john@example.com',
    specialty: 'Cardiologist',
    qualifications: 'MD, PhD',
    clinicAddress: '123 Heart St',
    workingHours: {'Monday': '9:00-17:00'},
    commissionRate: 10.0,
  );

  final List<Appointment> appointments = [
    Appointment(
      id: 'app1',
      patientId: 'patient1',
      doctorId: 'doc1',
      dateTime: DateTime.now().subtract(const Duration(days: 5)),
      status: AppointmentStatus.completed,
      fee: 100.0,
      isPaid: true,
    ),
    Appointment(
      id: 'app2',
      patientId: 'patient2',
      doctorId: 'doc1',
      dateTime: DateTime.now().subtract(const Duration(days: 10)),
      status: AppointmentStatus.completed,
      fee: 120.0,
      isPaid: true,
    ),
  ];

  double _calculateEarnings() {
    final filteredAppointments = appointments.where((app) =>
    app.status == AppointmentStatus.completed &&
        app.dateTime.isAfter(_startDate) &&
        app.dateTime.isBefore(_endDate.add(const Duration(days: 1)))).toList();
    return filteredAppointments.fold(0.0, (sum, app) => sum + app.fee);
  }

  double _calculateCommission(double totalEarnings) {
    return (doctor.commissionRate! / 100) * totalEarnings;
  }

  @override
  Widget build(BuildContext context) {
    final totalEarnings = _calculateEarnings();
    final commission = _calculateCommission(totalEarnings);
    final netEarnings = totalEarnings - commission;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'My Earnings',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Filter
            FadeInDown(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'From',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _startDate = picked);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(
                          _startDate.toString().substring(0, 10),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'To',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      ElevatedButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() => _endDate = picked);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          foregroundColor: AppColors.primary,
                        ),
                        child: Text(
                          _endDate.toString().substring(0, 10),
                          style: GoogleFonts.poppins(),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Earnings Summary
            FadeInUp(
              child: CustomCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.defaultPadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Earnings Summary',
                        style: GoogleFonts.poppins(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: AppSizes.defaultPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Earnings:',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            '\$${totalEarnings.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.smallPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Commission (${doctor.commissionRate}%):',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            '-\$${commission.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.bold, color: AppColors.error),
                          ),
                        ],
                      ),
                      const Divider(height: AppSizes.defaultPadding),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Net Earnings:',
                            style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '\$${netEarnings.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Earnings Details
            FadeInUp(
              child: Text(
                'Earnings Details',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: AppSizes.defaultPadding),
            appointments
                .where((app) =>
            app.status == AppointmentStatus.completed &&
                app.dateTime.isAfter(_startDate) &&
                app.dateTime.isBefore(_endDate.add(const Duration(days: 1))))
                .isEmpty
                ? Center(
              child: FadeInUp(
                child: Text(
                  'No earnings in this period',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              ),
            )
                : Column(
              children: appointments
                  .where((app) =>
              app.status == AppointmentStatus.completed &&
                  app.dateTime.isAfter(_startDate) &&
                  app.dateTime.isBefore(_endDate.add(const Duration(days: 1))))
                  .map((app) {
                final commissionForApp = (doctor.commissionRate! / 100) * app.fee;
                return FadeInUp(
                  child: CustomCard(
                    child: ListTile(
                      title: Text(
                        'Appointment on ${app.dateTime.toString().substring(0, 10)}',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Fee: \$${app.fee.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(),
                          ),
                          Text(
                            'Commission: -\$${commissionForApp.toStringAsFixed(2)}',
                            style: GoogleFonts.poppins(color: AppColors.error),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}