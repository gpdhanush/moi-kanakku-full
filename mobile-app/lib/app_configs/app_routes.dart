import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:moi/app_models/index.dart';
import 'package:moi/app_pages/upcoming_functions/models/upcoming_function_model.dart';
import 'package:moi/app_pages/index.dart';
import 'package:moi/app_utils/app_providers/connectivity_provider.dart';
import 'package:moi/app_utils/app_widgets/auth_guard.dart';
import 'package:provider/provider.dart';

class AppRoute {
  static final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const SplashScreen(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/home',
        name: 'home',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: const MainShellPage(),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/function-transaction-list',
        name: 'function-transaction-list',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: FunctionTransactionList(
            functionData: state.extra ?? const <String, dynamic>{},
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/transaction-detail-view',
        name: 'transaction-detail-view',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: TransactionDetailViewPage(
            transaction: state.extra as Map<String, dynamic>,
          ),
          transitionsBuilder: _slideTransition,
        ),
      ),
      GoRoute(
        path: '/view-functions-list',
        name: 'view-functions-list',
        pageBuilder: (context, state) => CustomTransitionPage(
          key: state.pageKey,
          child: ViewFunctionDetails(data: state.extra as List),
          transitionsBuilder: _slideTransition,
        ),
      ),
    ],
  );

  static Widget _slideTransition(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(curved),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
        child: child,
      ),
    );
  }

  static Future<T?> open<T>(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    final goRouter = GoRouter.maybeOf(context);
    if (goRouter != null) {
      return goRouter.pushNamed<T>(routeName, extra: arguments);
    }
    return Navigator.pushNamed<T>(context, routeName, arguments: arguments);
  }

  static const Set<String> _protectedRoutes = {
    'home',
    'profile',
    'change-password',
    'contact_us',
    'feedbacks',
    'settings',
    'functions-list',
    'view-functions-list',
    'function-transaction-list',
    'add-edit-functions',
    'transaction-dashboard',
    'all-transactions',
    'add-edit-transaction',
    'add-transaction',
    'transaction-person-details',
    'transaction-detail-view',
    'notifications',
    'upcoming-function-list',
    'upcoming-function-details',
    'add-edit-upcoming-function',
  };

  static Widget _maybeGuard(String? name, Widget page) {
    if (name != null && _protectedRoutes.contains(name)) {
      return AuthGuard(child: page);
    }
    return page;
  }

  static Route<dynamic> allRoutes(RouteSettings settings) {
    Widget buildPage(BuildContext context) {
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

      late final Widget page;
      switch (settings.name) {
        case "splash":
          page = const SplashScreen();
        case "onboarding":
          page = const OnboardingPage();
        case "permissions":
          page = const PermissionPage();
        case "home":
          page = const MainShellPage();
        case "login":
          page = const LoginPage();
        case "set-password":
          page = const SetPasswordPage();
        case "google-profile-setup":
          page = const GoogleProfileSetupPage();
        case "signup":
          page = const Signup();
        case "forgot_password":
          page = const ForgotPassword();
        case "verify_forgot_otp":
          page = VerifyForgotOtp(email: settings.arguments as String);
        case "reset_password":
          final args = settings.arguments;
          if (args is Map) {
            page = ResetPassword(
              email: args['email']?.toString() ?? '',
              otp: args['otp']?.toString() ?? '',
            );
          } else {
            page = ResetPassword(email: args?.toString() ?? '', otp: '');
          }
        case "restore_account_send_otp":
          page = RestoreAccountSendOtp(email: settings.arguments as String);
        case "restore_account_verify_otp":
          page = RestoreAccountVerifyOtp(email: settings.arguments as String);
        case "profile":
          page = const ProfilePage();
        case "change-password":
          page = const ChangePassword();
        case "contact_us":
          page = const ContactUs();
        case "feedbacks":
          page = const Feedbacks();
        case "settings":
          page = const Settings();
        case "functions-list":
          page = const FunctionsList();
        case "view-functions-list":
          page = ViewFunctionDetails(data: settings.arguments as List);
        case "function-transaction-list":
          page = FunctionTransactionList(functionData: settings.arguments);
        case "add-edit-functions":
          page = AddEditFunctions(data: settings.arguments as List);
        case "transaction-dashboard":
          page = const TransactionDashboard();
        case "all-transactions":
          final args = settings.arguments as Map<String, dynamic>?;
          page = AllTransactionsPage(
            type: args?['type']?.toString().toUpperCase() ?? '',
          );
        case "add-edit-transaction":
          page = AddEditPage(data: settings.arguments);
        case "add-transaction":
          final args = settings.arguments;
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
          page = AddTransactionPage(
            type: type,
            person: person,
            transaction: transaction,
            isEdit: isEdit,
          );
        case "transaction-person-details":
          page = TransactionPersonDetails(
            person: settings.arguments as PersonResponseModel,
          );
        case "transaction-detail-view":
          page = TransactionDetailViewPage(
            transaction: settings.arguments as Map<String, dynamic>,
          );
        case "notifications":
          page = const NotificationListPage();
        case "upcoming-function-list":
          page = const UpcomingFunctionList();
        case "upcoming-function-details":
          page = UpcomingFunctionDetailsPage(
            function: settings.arguments as UpcomingFunction,
          );
        case "add-edit-upcoming-function":
          page = AddEditUpcomingFunction(data: settings.arguments);
        default:
          page = const SplashScreen();
      }
      return _maybeGuard(settings.name, page);
    }

    if (settings.name == 'home') {
      return PageRouteBuilder(
        settings: settings,
        transitionDuration: const Duration(milliseconds: 360),
        reverseTransitionDuration: const Duration(milliseconds: 240),
        pageBuilder: (context, _, _) => buildPage(context),
        transitionsBuilder: (_, animation, _, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
            child: child,
          );
        },
      );
    }

    return MaterialPageRoute(settings: settings, builder: buildPage);
  }
}
