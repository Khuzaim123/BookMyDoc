import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/appointment.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/message.dart';
import 'package:bookmydoc2/models/patient.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:bookmydoc2/screens/appointment_detail_screen.dart';

class DoctorHomeScreen extends StatefulWidget {
  const DoctorHomeScreen({super.key});

  @override
  State<DoctorHomeScreen> createState() => _DoctorHomeScreenState();
}

class _DoctorHomeScreenState extends State<DoctorHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Doctor? doctor;
  List<Appointment> upcomingAppointments = [];
  List<Patient> patients = [];
  List<Message> recentMessages = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      final user = _auth.currentUser;
      if (user == null) {
        setState(() {
          errorMessage = 'No user logged in';
          isLoading = false;
        });
        return;
      }

      // Fetch doctor data
      final doctorDoc =
          await _firestore.collection('doctors').doc(user.uid).get();
      if (!doctorDoc.exists) {
        setState(() {
          errorMessage = 'Doctor profile not found';
          isLoading = false;
        });
        return;
      }

      final doctorData = doctorDoc.data()!;
      doctor = Doctor(
        id: user.uid,
        name: doctorData['name'] ?? '',
        email: doctorData['email'] ?? '',
        specialty: doctorData['specialty'] ?? '',
        qualifications: doctorData['qualifications'] ?? '',
        clinicAddress: doctorData['clinicAddress'] ?? '',
        workingHours: Map<String, String>.from(
          doctorData['workingHours'] ?? {},
        ),
        commissionRate: (doctorData['commissionRate'] ?? 0).toDouble(),
      );

      // Fetch upcoming appointments
      final appointmentsQuery =
          await _firestore
              .collection('appointments')
              .where('doctorId', isEqualTo: user.uid)
              .where('status', isEqualTo: 'booked')
              .where('dateTime', isGreaterThan: DateTime.now())
              .orderBy('dateTime')
              .limit(5)
              .get();

      upcomingAppointments =
          appointmentsQuery.docs.map((doc) {
            final data = doc.data();
            return Appointment(
              id: doc.id,
              patientId: data['patientId'],
              doctorId: data['doctorId'],
              dateTime: data['dateTime'].toDate(),
              status: AppointmentStatus.booked,
              fee: (data['fee'] ?? 0).toDouble(),
              isPaid: data['isPaid'] ?? false,
            );
          }).toList();

      // Fetch patients for these appointments
      final patientIds =
          upcomingAppointments.map((a) => a.patientId).toSet().toList();
      patients = [];
      for (final pid in patientIds) {
        final pdoc = await _firestore.collection('patients').doc(pid).get();
        if (pdoc.exists) {
          final pdata = pdoc.data()!;
          patients.add(
            Patient(
              id: pid,
              name: pdata['name'] ?? '',
              email: pdata['email'] ?? '',
              phone: pdata['phone'] ?? '',
            ),
          );
        }
      }

      // Fetch recent messages
      final messagesQuery =
          await _firestore
              .collection('messages')
              .where('receiverId', isEqualTo: user.uid)
              .orderBy('timestamp', descending: true)
              .limit(5)
              .get();

      recentMessages =
          messagesQuery.docs.map((doc) {
            final data = doc.data();
            return Message(
              id: doc.id,
              senderId: data['senderId'],
              receiverId: data['receiverId'],
              content: data['content'],
              timestamp: (data['timestamp'] as Timestamp).toDate(),
              isRead: data['isRead'] ?? false,
              type:
                  data['type'] == 'image'
                      ? MessageType.image
                      : data['type'] == 'pdf'
                      ? MessageType.pdf
                      : MessageType.text,
              fileName: data['fileName'],
            );
          }).toList();

      setState(() {
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Error fetching data: ${e.toString()}';
        isLoading = false;
      });
    }
  }

  Future<void> _refreshData() async {
    await _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.primary),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () => Navigator.pushNamed(context, RouteNames.doctorProfile),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, RouteNames.login);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Error signing out: ${e.toString()}'),
                    ),
                  );
                }
              }
            },
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppColors.cardBackground,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: AppColors.primary),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_circle, size: 48, color: Colors.white),
                  const SizedBox(height: 8),
                  Text(
                    doctor?.name ?? 'Doctor',
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.person, color: AppColors.primaryDark),
              title: Text('Profile', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(
                  context,
                  RouteNames.doctorProfile,
                  arguments: {'id': doctor?.id, 'isOwnProfile': true},
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.info_outline, color: AppColors.primaryDark),
              title: Text('About Us', style: GoogleFonts.poppins()),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, RouteNames.aboutUs);
              },
            ),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Logout', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pop(context);
                await _auth.signOut();
                if (mounted) {
                  Navigator.pushReplacementNamed(context, RouteNames.login);
                }
              },
            ),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSizes.defaultPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(AppSizes.defaultPadding),
                  margin: const EdgeInsets.only(
                    bottom: AppSizes.defaultPadding,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.red),
                      const SizedBox(width: AppSizes.smallPadding),
                      Expanded(
                        child: Text(
                          errorMessage!,
                          style: GoogleFonts.poppins(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              // Greeting
              FadeInDown(
                child:
                    doctor == null
                        ? const SizedBox.shrink()
                        : Text(
                          'Hello, ${doctor!.name}!',
                          style: GoogleFonts.poppins(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
              ),
              const SizedBox(height: AppSizes.smallPadding),

              // Quick Actions (Refined UI)
              FadeInUp(
                child: Center(
                  child: Wrap(
                    spacing: AppSizes.largePadding,
                    runSpacing: AppSizes.largePadding,
                    alignment: WrapAlignment.center,
                    children: [
                      _buildActionButton(
                        context,
                        'Appointments',
                        Icons.calendar_today,
                      ),
                      _buildActionButton(context, 'Messages', Icons.message),
                      _buildActionButton(
                        context,
                        'Availability',
                        Icons.schedule,
                      ),
                      _buildActionButton(
                        context,
                        'Earnings',
                        Icons.account_balance_wallet,
                      ),
                      _buildActionButton(
                        context,
                        'Records',
                        Icons.medical_services,
                      ),
                      _buildActionButton(context, 'Profile', Icons.person),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.largePadding),

              // Upcoming Appointments
              FadeInLeft(
                child: Text(
                  'Upcoming Appointments',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.defaultPadding),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : upcomingAppointments.isEmpty
                  ? FadeInUp(
                    child: Center(
                      child: Text(
                        'No upcoming appointments',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        upcomingAppointments.map((appointment) {
                          final patient = patients.firstWhere(
                            (p) => p.id == appointment.patientId,
                            orElse:
                                () => Patient(
                                  id: '',
                                  name: 'Unknown',
                                  email: '',
                                  phone: '',
                                ),
                          );
                          return FadeInRight(
                            child: CustomCard(
                              child: ListTile(
                                title: Text(
                                  'Patient: ${patient.name}',
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  'Time: ${appointment.dateTime.toString().substring(0, 16)}',
                                  style: GoogleFonts.poppins(),
                                ),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  color: AppColors.primary,
                                ),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AppointmentDetailScreen(
                                            appointment: appointment,
                                            isDoctor: true, // Doctor view
                                          ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                  ),
              const SizedBox(height: AppSizes.largePadding),

              // Recent Messages
              FadeInLeft(
                child: Text(
                  'Recent Messages',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              const SizedBox(height: AppSizes.defaultPadding),
              isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : recentMessages.isEmpty
                  ? FadeInUp(
                    child: Center(
                      child: Text(
                        'No recent messages',
                        style: GoogleFonts.poppins(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ),
                  )
                  : Column(
                    children:
                        recentMessages.map((message) {
                          final patient = patients.firstWhere(
                            (p) => p.id == message.senderId,
                            orElse:
                                () => Patient(
                                  id: '',
                                  name: 'Unknown',
                                  email: '',
                                  phone: '',
                                ),
                          );
                          return FadeInRight(
                            child: CustomCard(
                              child: ListTile(
                                title: Text(
                                  patient.name,
                                  style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                subtitle: Text(
                                  message.content,
                                  style: GoogleFonts.poppins(),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing:
                                    message.isRead
                                        ? null
                                        : const Icon(
                                          Icons.circle,
                                          color: AppColors.primary,
                                          size: 10,
                                        ),
                                onTap: () {
                                  Navigator.pushNamed(
                                    context,
                                    RouteNames.doctorMessage,
                                    arguments: {'id': message.senderId},
                                  );
                                },
                              ),
                            ),
                          );
                        }).toList(),
                  ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(BuildContext context, String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.all(AppSizes.smallPadding),
      child: _HoverableActionButton(
        label: label,
        icon: icon,
        onTap: () {
          if (label == 'Appointments') {
            Navigator.pushNamed(context, RouteNames.doctorAppointments);
          } else if (label == 'Messages') {
            Navigator.pushNamed(context, RouteNames.doctorMessagesList);
          } else if (label == 'Availability') {
            Navigator.pushNamed(
              context,
              RouteNames.doctorAvailability,
              arguments: {'id': doctor!.id},
            );
          } else if (label == 'Earnings') {
            Navigator.pushNamed(context, RouteNames.doctorEarnings);
          } else if (label == 'Records') {
            Navigator.pushNamed(context, RouteNames.doctorPatientRecords);
          } else if (label == 'Profile') {
            Navigator.pushNamed(
              context,
              RouteNames.doctorProfile,
              arguments: {'id': doctor!.id, 'isOwnProfile': true},
            );
          }
        },
      ),
    );
  }
}

class _HoverableActionButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _HoverableActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_HoverableActionButton> createState() => _HoverableActionButtonState();
}

class _HoverableActionButtonState extends State<_HoverableActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _hovering ? 1.05 : 1.0,
          duration: const Duration(milliseconds: 150),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 150,
            height: 90,
            decoration: BoxDecoration(
              color: AppColors.cardBackground,
              borderRadius: BorderRadius.circular(AppSizes.buttonRadius),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadowColor,
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
              border: Border.all(color: AppColors.primary.withOpacity(0.08)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.icon,
                  size: 36,
                  color: _hovering ? AppColors.accent : AppColors.primaryDark,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
