import 'package:flutter/material.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_pages/index.dart';
import 'package:moi/app_utils/app_providers/connectivity_provider.dart';
import 'package:provider/provider.dart';

class AppRoute {
  static Route<dynamic> allRoutes(RouteSettings settings) {
    return MaterialPageRoute(
      builder: (context) {
        if (settings.name == 'maintenance') {
          return const MaintenanceModePage();
        }
        if (settings.name == 'configuration_error') {
          return const ConfigurationErrorPage();
        }

        final isOnline = Provider.of<ConnectivityProvider>(
          context,
          listen: true,
        ).isOnline;
        if (!isOnline) {
          return const NoInternetPage();
        }
        switch (settings.name) {
          case "splash":
            return const SplashScreen();
          case "onboarding":
            return const OnboardingPage();
          case "permissions":
            return const PermissionPage();
          case "home":
            return const HomePage();
          case "login":
            return const LoginPage();
          case "signup":
            return const Signup();
          case "forgot_password":
            return const ForgotPassword();
          case "verify_forgot_otp":
            String args = settings.arguments as String;
            return VerifyForgotOtp(email: args);
          case "reset_password":
            String args = settings.arguments as String;
            return ResetPassword(email: args);
          case "restore_account_send_otp":
            String args = settings.arguments as String;
            return RestoreAccountSendOtp(email: args);
          case "restore_account_verify_otp":
            String args = settings.arguments as String;
            return RestoreAccountVerifyOtp(email: args);
          case "profile":
            return const ProfilePage();
          case "change-password":
            return const ChangePassword();
          case "contact_us":
            return const ContactUs();
          // case "contact-us":
          //   return const ContactUsPage();
          case "feedbacks":
            return const Feedbacks();
          case "promotion":
            return const PromotionPage();
          // case "booking-success":
          //   final args = settings.arguments as Map<String, dynamic>?;
          //   return BookingSuccessScreen(
          //     bookingId: args?['bookingId']?.toString(),
          //     paymentId: args?['paymentId']?.toString(),
          //   );
          case "settings":
            return const Settings();
          // FUNCTIONS
          case "functions-list":
            return const FunctionsList();
          case "view-functions-list":
            List args = settings.arguments as List;
            return ViewFunctionDetails(data: args);
          case "function-transaction-list":
            dynamic args = settings.arguments;
            return FunctionTransactionList(functionData: args);
          case "add-edit-functions":
            List args = settings.arguments as List;
            return AddEditFunctions(data: args);
          case "transaction-dashboard":
            return const TransactionDashboard();
          case "all-transactions":
            final args = settings.arguments as Map<String, dynamic>?;
            String type = args?['type']?.toString().toUpperCase() ?? '';
            return AllTransactionsPage(type: type);
          case "add-edit-transaction":
            dynamic args = settings.arguments;
            //  String type = "RETURN";
            //  dynamic personData;
            return AddEditPage(data: args);
          case "add-transaction":
            dynamic args = settings.arguments;
            String type = "RETURN";
            dynamic person;
            Map<String, dynamic>? transaction;
            bool isEdit = false;
            if (args is Map<String, dynamic>) {
              type = args['type'] ?? "RETURN";
              person = args['person'];
              if (args['transaction'] is Map) {
                transaction = Map<String, dynamic>.from(args['transaction']);
              }
              isEdit = args['isEdit'] == true;
            }
            return AddTransactionPage(
              type: type,
              person: person,
              transaction: transaction,
              isEdit: isEdit,
            );
          case "transaction-person-details":
            PersonResponseModel data =
                settings.arguments as PersonResponseModel;
            return TransactionPersonDetails(person: data);
          case "transaction-detail-view":
            Map<String, dynamic> args =
                settings.arguments as Map<String, dynamic>;
            return TransactionDetailViewPage(transaction: args);
          // dynamic args = settings.arguments;
          //             String type = "RETURN";
          //             dynamic personData;

          //             if (args is Map<String, dynamic>) {
          //               type = args['type'] ?? "RETURN";
          //               personData = args['personData'];
          //             }

          //             return AddMoiReturnInvest(type: type, personData: personData);
          // MOI
          // case "moi":
          //   return const MoiList();
          // case "add-moi":
          //   List args = settings.arguments as List;
          //   return AddUpdateMoi(data: args);
          // case "moi-details":
          //   List args = settings.arguments as List;
          //   return MoiDetailsView(data: args);
          // // MOI OUT DETAILD
          // case "moi-out":
          //   return const MoiOutList();
          // case "add-moi-out":
          //   List args = settings.arguments as List;
          //   return AddUpdateMoiOut(data: args);
          // case "moi_out_details":
          //   List args = settings.arguments as List;
          //   return MoiOutDetailView(data: args);
          // NOTIFICATIONS
          case "notifications":
            return const NotificationListPage();
          // UPCOMING FUNCTIONS
          case "upcoming-function-list":
            return const UpcomingFunctionList();
          case "upcoming-function-details":
            final args = settings.arguments as UpcomingFunction;
            return UpcomingFunctionDetailsPage(function: args);
          case "add-edit-upcoming-function":
            dynamic args = settings.arguments;
            return AddEditUpcomingFunction(data: args);
          // MOI CREDIT DEBIT
          // case "moi-credit-debit-dashboard":
          //   return const MoiCreditDebitDashboard();
          // case "moi-credit-debit-person-details":
          //   List args = settings.arguments as List;
          //   return MoiCreditDebitPersonDetails(personData: args[0]);
          // case "add-edit-moi-person":
          //   List args = settings.arguments as List;
          //   return AddEditMoiPerson(data: args);
          // case "add-moi-return-invest":
          //   dynamic args = settings.arguments;
          //   String type = "RETURN";
          //   dynamic personData;

          //   if (args is Map<String, dynamic>) {
          //     type = args['type'] ?? "RETURN";
          //     personData = args['personData'];
          //   }

          //   return AddMoiReturnInvest(type: type, personData: personData);
          // case "moi-transaction-details":
          //   Map<String, dynamic> args =
          //       settings.arguments as Map<String, dynamic>;
          //   return MoiTransactionDetails(
          //     transaction: args['transaction'],
          //     personDetails: args['personDetails'],
          //   );
        }
        return const SplashScreen();
      },
    );
  }
}
