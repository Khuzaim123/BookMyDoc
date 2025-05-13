import 'package:flutter/material.dart';
import 'package:bookmydoc2/screens/appointment_booking_screen.dart';
import 'package:bookmydoc2/screens/appointments_screen.dart';
import 'package:bookmydoc2/screens/doctor_appointments_screen.dart';
import 'package:bookmydoc2/screens/doctor_availability_screen.dart';
import 'package:bookmydoc2/screens/doctor_earnings_screen.dart';
import 'package:bookmydoc2/screens/doctor_home_screen.dart';
import 'package:bookmydoc2/screens/doctor_message_screen.dart';
import 'package:bookmydoc2/screens/doctor_messages_list_screen.dart';
import 'package:bookmydoc2/screens/doctor_patient_records_screen.dart';
import 'package:bookmydoc2/screens/doctor_profile_screen.dart';
import 'package:bookmydoc2/screens/forgot_password_screen.dart';
import 'package:bookmydoc2/screens/health_records_screen.dart';
import 'package:bookmydoc2/screens/home_screen.dart';
import 'package:bookmydoc2/screens/login_screen.dart';
import 'package:bookmydoc2/screens/message_screen.dart';
import 'package:bookmydoc2/screens/messages_list_screen.dart';
import 'package:bookmydoc2/screens/profile_management_screen.dart';
import 'package:bookmydoc2/screens/search_screen.dart';
import 'package:bookmydoc2/screens/sign_up_screen.dart';

class RouteNames {
  static const String signUp = '/signup';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String search = '/search';
  static const String appointmentBooking = '/appointment-booking';
  static const String appointments = '/appointments';
  static const String message = '/message';
  static const String messagesList = '/messages-list';
  static const String profileManagement = '/profile-management';
  static const String healthRecords = '/health-records';
  static const String doctorProfileView = '/doctor-profile-view';

  static const String doctorHome = '/doctor-home';
  static const String doctorAppointments = '/doctor-appointments';
  static const String doctorAvailability = '/doctor-availability';
  static const String doctorMessagesList = '/doctor-messages-list';
  static const String doctorMessage = '/doctor-message';
  static const String doctorPatientRecords = '/doctor-patient-records';
  static const String doctorProfile = '/doctor-profile-screen';
  static const String doctorEarnings = '/doctor-earnings';
}

Route<dynamic> generateRoute(RouteSettings settings) {
  final args = settings.arguments as Map<String, dynamic>?;
  switch (settings.name) {
    case RouteNames.signUp:
      return MaterialPageRoute(builder: (_) => const SignUpScreen());
    case RouteNames.login:
      return MaterialPageRoute(builder: (_) => const LoginScreen());
    case RouteNames.forgotPassword:
      return MaterialPageRoute(builder: (_) => const ForgotPasswordScreen());
    case RouteNames.home:
      return MaterialPageRoute(builder: (_) => HomeScreen());
    case RouteNames.search:
      return MaterialPageRoute(builder: (_) => const SearchScreen());
    case RouteNames.doctorProfileView:
      return MaterialPageRoute(
        builder: (_) => DoctorProfileScreen(
          doctorId: args?["id"] ?? '',
          isOwnProfile: false,
        ),
      );
    case RouteNames.appointmentBooking:
      return MaterialPageRoute(
        builder: (_) => AppointmentBookingScreen(
          doctorId: args?["id"] ?? '',
        ),
      );
    case RouteNames.appointments:
      return MaterialPageRoute(builder: (_) => AppointmentsScreen());
    case RouteNames.message:
      return MaterialPageRoute(
        builder: (_) => MessageScreen(
          doctorId: args?["id"] ?? '',
        ),
      );
    case RouteNames.messagesList:
      return MaterialPageRoute(builder: (_) => MessagesListScreen());
    case RouteNames.profileManagement:
      return MaterialPageRoute(builder: (_) => const ProfileManagementScreen());
    case RouteNames.healthRecords:
      return MaterialPageRoute(builder: (_) => HealthRecordsScreen());
    case RouteNames.doctorHome:
      return MaterialPageRoute(builder: (_) => DoctorHomeScreen());
    case RouteNames.doctorAppointments:
      return MaterialPageRoute(builder: (_) => const DoctorAppointmentsScreen());
    case RouteNames.doctorAvailability:
      return MaterialPageRoute(builder: (_) => const DoctorAvailabilityScreen());
    case RouteNames.doctorMessagesList:
      return MaterialPageRoute(builder: (_) => DoctorMessagesListScreen());
    case RouteNames.doctorMessage:
      return MaterialPageRoute(
        builder: (_) => DoctorMessageScreen(
          patientId: args?["id"] ?? '',
        ),
      );
    case RouteNames.doctorPatientRecords:
      return MaterialPageRoute(builder: (_) => DoctorPatientRecordsScreen());
    case RouteNames.doctorProfile:
      return MaterialPageRoute(
        builder: (_) => DoctorProfileScreen(
          doctorId: args?["id"] ?? '',
          isOwnProfile: true,
        ),
      );
    case RouteNames.doctorEarnings:
      return MaterialPageRoute(builder: (_) => const DoctorEarningsScreen());
    default:
      return MaterialPageRoute(
        builder: (_) => Scaffold(
          body: Center(child: Text('Page not found: \${settings.name}')),
        ),
      );
  }
}

void navigateTo(BuildContext context, String routeName, [Map<String, dynamic>? args]) {
  Navigator.pushNamed(context, routeName, arguments: args);
}