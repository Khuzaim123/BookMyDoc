import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:bookmydoc2/widgets/custom_text_field.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Doctor> allDoctors = [
    Doctor(
      id: 'doc1',
      name: 'Dr. John Smith',
      email: 'john@example.com',
      specialty: 'Cardiologist',
      qualifications: 'MD, PhD',
      clinicAddress: '123 Heart St',
      workingHours: {'Monday': '9:00-17:00'},
    ),
    Doctor(
      id: 'doc2',
      name: 'Dr. Jane Doe',
      email: 'jane@example.com',
      specialty: 'Dentist',
      qualifications: 'DDS',
      clinicAddress: '456 Smile Ave',
      workingHours: {'Tuesday': '10:00-18:00'},
    ),
    Doctor(
      id: 'doc3',
      name: 'Dr. Emily Brown',
      email: 'emily@example.com',
      specialty: 'Pediatrician',
      qualifications: 'MD',
      clinicAddress: '789 Child Rd',
      workingHours: {'Wednesday': '8:00-16:00'},
    ),
  ];
  List<Doctor> filteredDoctors = [];

  @override
  void initState() {
    super.initState();
    filteredDoctors = allDoctors; // Initially show all doctors
    _searchController.addListener(_filterDoctors);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDoctors = allDoctors.where((doctor) {
        return doctor.name.toLowerCase().contains(query) ||
            doctor.specialty.toLowerCase().contains(query);
      }).toList();
    });
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
        title: Text('Search Doctors', style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          children: [
            // Search Bar
            FadeInDown(
              child: CustomTextField(
                hintText: 'Search by name or specialty',
                controller: _searchController,
                keyboardType: TextInputType.text,
              ),
            ),
            const SizedBox(height: AppSizes.largePadding),

            // Results
            Expanded(
              child: filteredDoctors.isEmpty
                  ? Center(
                child: Text(
                  'No doctors found',
                  style: GoogleFonts.poppins(color: AppColors.textSecondary),
                ),
              )
                  : ListView.builder(
                itemCount: filteredDoctors.length,
                itemBuilder: (context, index) {
                  final doctor = filteredDoctors[index];
                  return FadeInUp(
                    delay: Duration(milliseconds: index * 100),
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(context , '${RouteNames.doctorProfile}?id=${doctor.id}'),
                      child: CustomCard(
                        child: ListTile(
                          title: Text(doctor.name, style: GoogleFonts.poppins(fontWeight: FontWeight.bold)),
                          subtitle: Text(doctor.specialty, style: GoogleFonts.poppins()),
                          trailing: const Icon(Icons.arrow_forward_ios, color: AppColors.primary),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}