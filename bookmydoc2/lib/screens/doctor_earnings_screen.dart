import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DoctorEarningsScreen extends StatefulWidget {
  const DoctorEarningsScreen({super.key});

  @override
  State<DoctorEarningsScreen> createState() => _DoctorEarningsScreenState();
}

class _DoctorEarningsScreenState extends State<DoctorEarningsScreen> {
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Doctor? doctor;
  List<Appointment> appointments = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchEarningsData();
  }

  Future<void> _fetchEarningsData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');
      // Fetch doctor info
      final docSnap =
          await _firestore.collection('doctors').doc(user.uid).get();
      if (!docSnap.exists) throw Exception('Doctor profile not found');
      final docData = docSnap.data()!;
      doctor = Doctor(
        id: user.uid,
        name: docData['name'] ?? '',
        email: docData['email'] ?? '',
        specialty: docData['specialty'] ?? '',
        qualifications: docData['qualifications'] ?? '',
        clinicAddress: docData['clinicAddress'] ?? '',
        workingHours: Map<String, String>.from(docData['workingHours'] ?? {}),
        commissionRate: (docData['commissionRate'] ?? 0.0).toDouble(),
      );
      // Fetch completed appointments in date range
      final query =
          await _firestore
              .collection('appointments')
              .where('doctorId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'completed')
              .where('startTime', isGreaterThanOrEqualTo: _startDate)
              .where(
                'startTime',
                isLessThanOrEqualTo: _endDate.add(const Duration(days: 1)),
              )
              .orderBy('startTime', descending: true)
              .get();
      appointments =
          query.docs.map((doc) {
            final data = doc.data();
            return Appointment(
              id: doc.id,
              patientId: data['patientId'],
              doctorId: data['doctorId'],
              dateTime: (data['startTime'] as Timestamp).toDate(),
              status: AppointmentStatus.completed,
              fee: (data['fee'] ?? 0.0).toDouble(),
              isPaid: data['isPaid'] ?? false,
            );
          }).toList();
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      // Use dummy doctor and dummy appointments if Firestore fails
      final user = _auth.currentUser;
      doctor = Doctor(
        id: user?.uid ?? 'dummy',
        name: user?.displayName ?? user?.email ?? 'Dr. Dummy',
        email: user?.email ?? '',
        specialty: 'General',
        qualifications: 'MBBS',
        clinicAddress: 'N/A',
        workingHours: {},
        commissionRate: 0.0,
      );
      appointments = [
        Appointment(
          id: 'dummy1',
          patientId: 'dummyPatient',
          doctorId: doctor!.id,
          dateTime: DateTime.now(),
          status: AppointmentStatus.completed,
          fee: 0.0,
          isPaid: false,
        ),
      ];
      setState(() {
        _isLoading = false;
        _error = null; // So the normal UI is shown
      });
    }
  }

  double _calculateEarnings() {
    return appointments.fold(0.0, (sum, app) => sum + app.fee);
  }

  double _calculateCommission(double totalEarnings) {
    if (doctor == null) return 0.0;
    return ((doctor!.commissionRate ?? 0.0) / 100) * totalEarnings;
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
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      FirebaseAuth.instance.currentUser?.displayName ??
                          FirebaseAuth.instance.currentUser?.email ??
                          'Dr. Unknown',
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "Total Earnings: \$0.00",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Commission: \$0.00",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        color: AppColors.error,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Net Earnings: \$0.00",
                      style: GoogleFonts.poppins(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "No real earnings data (dummy mode)",
                      style: GoogleFonts.poppins(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
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
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
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
                                style: GoogleFonts.poppins(
                                  fontWeight: FontWeight.w600,
                                ),
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
                                  backgroundColor: AppColors.primary
                                      .withOpacity(0.1),
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
                          padding: const EdgeInsets.all(
                            AppSizes.defaultPadding,
                          ),
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
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Earnings:',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  Text(
                                    '\$${totalEarnings.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.smallPadding),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Commission (${doctor?.commissionRate?.toStringAsFixed(2)}%):',
                                    style: GoogleFonts.poppins(),
                                  ),
                                  Text(
                                    '-\$${commission.toStringAsFixed(2)}',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.bold,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                              const Divider(height: AppSizes.defaultPadding),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Net Earnings:',
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                    ),
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
                    appointments.isEmpty
                        ? Center(
                          child: FadeInUp(
                            child: Text(
                              'No earnings in this period',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        )
                        : Column(
                          children:
                              appointments.map((app) {
                                final commissionForApp =
                                    (doctor?.commissionRate ?? 0.0) /
                                    100 *
                                    app.fee;
                                return FadeInUp(
                                  child: CustomCard(
                                    child: ListTile(
                                      title: Text(
                                        'Appointment on ${app.dateTime.toString().substring(0, 10)}',
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Fee: \$${app.fee.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(),
                                          ),
                                          Text(
                                            'Commission: -\$${commissionForApp.toStringAsFixed(2)}',
                                            style: GoogleFonts.poppins(
                                              color: AppColors.error,
                                            ),
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
