import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/constants/strings.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/models/health_tip.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _userName = 'Patient';
  bool _isLoading = true;

  // Keep health tips as dummy data
  final List<HealthTip> healthTips = [
    HealthTip(
      id: 'tip1',
      title: 'Stay Hydrated',
      content: 'Drink 8 glasses of water daily',
      createdAt: DateTime.now(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _getUserData();
  }

  Future<void> _getUserData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      User? user = _auth.currentUser;
      if (user != null) {
        // Get user data from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('patients').doc(user.uid).get();

        if (userDoc.exists) {
          Map<String, dynamic> userData =
              userDoc.data() as Map<String, dynamic>;
          setState(() {
            _userName = userData['name'] ?? 'Patient';
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: ${e.toString()}')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          AppStrings.appName,
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.pushNamed(context, RouteNames.search),
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed:
                () =>
                    Navigator.pushNamed(context, RouteNames.profileManagement),
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _auth.signOut();
              // ignore: use_build_context_synchronously
              Navigator.pushNamedAndRemoveUntil(
                context,
                RouteNames.login,
                (route) => false,
              );
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
                    _userName,
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
                Navigator.pushNamed(context, RouteNames.profileManagement);
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
                // ignore: use_build_context_synchronously
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  RouteNames.login,
                  (route) => false,
                );
              },
            ),
            ListTile(
              leading: Icon(Icons.chat, color: AppColors.error),
              title: Text('Doc Bot', style: GoogleFonts.poppins()),
              onTap: () async {
                Navigator.pushNamed(context, RouteNames.aiAssistant);
              },
            ),
          ],
        ),
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(AppSizes.defaultPadding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Welcome Message
                    FadeInDown(
                      child: Text(
                        'Hello, $_userName!',
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
                              'Messages',
                              Icons.message,
                            ),
                            _buildActionButton(
                              context,
                              'Book Appointment',
                              Icons.calendar_today,
                            ),
                            _buildActionButton(
                              context,
                              'Appointments',
                              Icons.event,
                            ),
                            _buildActionButton(
                              context,
                              'Health Records',
                              Icons.medical_services,
                            ),
                            _buildActionButton(
                              context,
                              'Profile',
                              Icons.person,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.largePadding),

                    // Recommended Doctors
                    FadeInLeft(
                      child: Text(
                        'Recommended Doctors',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.defaultPadding),
                    StreamBuilder<QuerySnapshot>(
                      stream:
                          _firestore
                              .collection('doctors')
                              .orderBy('rating', descending: true)
                              .limit(5)
                              .snapshots(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(AppSizes.defaultPadding),
                              child: CircularProgressIndicator(
                                color: AppColors.primary,
                              ),
                            ),
                          );
                        }

                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading doctors',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                          return Center(
                            child: Text(
                              'No doctors found',
                              style: GoogleFonts.poppins(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          );
                        }

                        return Column(
                          children:
                              snapshot.data!.docs.asMap().entries.map((entry) {
                                int index = entry.key;
                                DocumentSnapshot doc = entry.value;
                                Map<String, dynamic> data =
                                    doc.data() as Map<String, dynamic>;

                                Doctor doctor = Doctor(
                                  id: doc.id,
                                  name: data['name'] ?? 'Unknown Doctor',
                                  email: data['email'] ?? '',
                                  specialty:
                                      data['specialty'] ?? 'General Physician',
                                  qualifications: data['qualifications'] ?? '',
                                  clinicAddress: data['clinicAddress'] ?? '',
                                  workingHours: Map<String, String>.from(
                                    data['workingHours'] ??
                                        {'Monday': '9:00-17:00'},
                                  ),
                                );

                                return FadeInRight(
                                  delay: Duration(milliseconds: index * 100),
                                  child: GestureDetector(
                                    onTap:
                                        () => Navigator.pushNamed(
                                          context,
                                          RouteNames.doctorProfileView,
                                          arguments: {'id': doctor.id},
                                        ),
                                    child: CustomCard(
                                      child: ListTile(
                                        title: Text(
                                          doctor.name,
                                          style: GoogleFonts.poppins(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        subtitle: Text(
                                          doctor.specialty,
                                          style: GoogleFonts.poppins(),
                                        ),
                                        trailing: const Icon(
                                          Icons.arrow_forward_ios,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        );
                      },
                    ),
                    const SizedBox(height: AppSizes.largePadding),

                    // Health Tips (kept as dummy data)
                    FadeInUp(
                      child: Text(
                        'Health Tips',
                        style: GoogleFonts.poppins(
                          fontSize: 20,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSizes.defaultPadding),
                    Column(
                      children:
                          healthTips
                              .map(
                                (tip) => FadeInDown(
                                  child: CustomCard(
                                    child: ListTile(
                                      title: Text(
                                        tip.title,
                                        style: GoogleFonts.poppins(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      subtitle: Text(
                                        tip.content,
                                        style: GoogleFonts.poppins(),
                                      ),
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                    ),
                  ],
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
          if (label == 'Book Appointment') {
            Navigator.pushNamed(context, RouteNames.search);
          } else if (label == 'Appointments') {
            Navigator.pushNamed(context, RouteNames.appointments);
          } else if (label == 'Messages') {
            Navigator.pushNamed(context, RouteNames.messagesList);
          } else if (label == 'Health Records') {
            Navigator.pushNamed(context, RouteNames.healthRecords);
          } else if (label == 'Profile') {
            Navigator.pushNamed(context, RouteNames.profileManagement);
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
