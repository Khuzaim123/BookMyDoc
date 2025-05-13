import 'package:animate_do/animate_do.dart';
import 'package:bookmydoc2/constants/colors.dart';
import 'package:bookmydoc2/constants/sizes.dart';
import 'package:bookmydoc2/models/doctor.dart';
import 'package:bookmydoc2/routes.dart';
import 'package:bookmydoc2/widgets/custom_card.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  List<Doctor> allDoctors = [];
  List<Doctor> filteredDoctors = [];
  String? selectedSpecialty;
  bool _isLoading = true;
  String? _errorMessage;
  
  // Get unique specialties for filter options
  List<String> get specialties {
    final specialtySet = allDoctors.map((doctor) => doctor.specialty).toSet();
    return ['All Specialties', ...specialtySet];
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_filterDoctors);
    _fetchDoctors();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchDoctors() async {
  setState(() {
    _isLoading = true;
    _errorMessage = null;
  });

  try {
    // Reference to the "doctors" collection in Firestore
    final QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection('doctors')
        .get();

    // Convert the query documents to Doctor objects
    final List<Doctor> doctors = [];
    
    for (var doc in querySnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      
      // Convert workingHours from Firestore to Map<String, String>
      final Map<String, dynamic> firestoreWorkingHours = data['workingHours'] ?? {};
      final Map<String, String> workingHours = firestoreWorkingHours.map(
        (key, value) => MapEntry(key, value.toString()),
      );
      
      // Create Doctor object with data from doctors collection
      Doctor doctor = Doctor(
        id: doc.id,
        name: data['name'] ?? 'Unknown Doctor',
        email: data['email'] ?? '',
        specialty: data['specialty'] ?? 'General Practitioner',
        qualifications: data['qualifications'] ?? '',
        clinicAddress: data['clinicAddress'] ?? '',
        workingHours: workingHours,
        rating: (data['rating'] as num?)?.toDouble(),
        experience: (data['experience'] as num?)?.toDouble(), 
        consultationFee: (data['consultationFee'] as num?)?.toDouble(),
        commissionRate: (data['commissionRate'] as num?)?.toDouble(),
      );
      
      doctors.add(doctor);
    }

    setState(() {
      allDoctors = doctors;
      filteredDoctors = doctors;
      _isLoading = false;
    });
  } catch (e) {
    setState(() {
      _errorMessage = 'Failed to load doctors: ${e.toString()}';
      _isLoading = false;
    });
    print('Error fetching doctors: $e');
  }
}



  void _filterDoctors() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredDoctors = allDoctors.where((doctor) {
        // If specialty is selected (and not "All Specialties"), filter by it
        bool matchesSpecialty = selectedSpecialty == null || 
                               selectedSpecialty == 'All Specialties' || 
                               doctor.specialty == selectedSpecialty;
        
        // Text search filter
        bool matchesQuery = doctor.name.toLowerCase().contains(query) ||
                          doctor.specialty.toLowerCase().contains(query);
        
        return matchesSpecialty && matchesQuery;
      }).toList();
    });
  }
  
  void _showSpecialtyFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Filter by Specialty',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: specialties.length,
            itemBuilder: (context, index) {
              final specialty = specialties[index];
              return ListTile(
                title: Text(specialty, style: GoogleFonts.poppins()),
                trailing: selectedSpecialty == specialty 
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  setState(() {
                    selectedSpecialty = specialty == 'All Specialties' ? null : specialty;
                  });
                  _filterDoctors();
                  Navigator.pop(context);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.poppins(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Find a Doctor',
          style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
        actions: [
          // Add a refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchDoctors,
            tooltip: 'Refresh doctors list',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(AppSizes.defaultPadding),
        child: Column(
          children: [
            // Search bar with filter button
            FadeInDown(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search doctors by name or specialty',
                        hintStyle: GoogleFonts.poppins(color: AppColors.textSecondary),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primary),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(color: AppColors.primary, width: 2),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton(
                    icon: const Icon(Icons.filter_list, color: AppColors.primary),
                    onPressed: _showSpecialtyFilterDialog,
                    tooltip: 'Filter by specialty',
                  ),
                ],
              ),
            ),
            
            // Active filter chip (shown only when a specialty is selected)
            if (selectedSpecialty != null && selectedSpecialty != 'All Specialties')
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: FadeInDown(
                  child: Row(
                    children: [
                      Chip(
                        label: Text(
                          selectedSpecialty!,
                          style: GoogleFonts.poppins(color: Colors.white),
                        ),
                        backgroundColor: AppColors.primary,
                        deleteIconColor: Colors.white,
                        onDeleted: () {
                          setState(() {
                            selectedSpecialty = null;
                          });
                          _filterDoctors();
                        },
                      ),
                    ],
                  ),
                ),
              ),
            
            const SizedBox(height: AppSizes.defaultPadding),
            
            // Results
            Expanded(
              child: _isLoading 
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, size: 48, color: Colors.red),
                          const SizedBox(height: 16),
                          Text(
                            'Error loading doctors',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage!,
                            style: GoogleFonts.poppins(color: AppColors.textSecondary),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _fetchDoctors,
                            child: Text('Try Again', style: GoogleFonts.poppins()),
                          ),
                        ],
                      ),
                    )
                  : filteredDoctors.isEmpty
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
                              onTap: () => Navigator.pushNamed(
                                context,
                                RouteNames.doctorProfile,
                                arguments: {'id': doctor.id, 'isOwnProfile': false}
                              ),
                              child: CustomCard(
                                child: ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.primary,
                                    child: Text(
                                      doctor.name.substring(0, 1),
                                      style: const TextStyle(color: Colors.white),
                                    ),
                                  ),
                                  title: Text(
                                    doctor.name,
                                    style: GoogleFonts.poppins(fontWeight: FontWeight.bold)
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        doctor.specialty,
                                        style: GoogleFonts.poppins(),
                                      ),
                                      if (doctor.rating != null)
                                        Row(
                                          children: [
                                            const Icon(Icons.star, color: Colors.amber, size: 16),
                                            Text(
                                              ' ${doctor.rating}',
                                              style: GoogleFonts.poppins(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(
                                    Icons.arrow_forward_ios,
                                    color: AppColors.primary,
                                  ),
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