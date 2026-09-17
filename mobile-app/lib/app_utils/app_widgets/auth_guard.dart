import 'package:flutter/material.dart';
import 'package:moi/app_configs/app_variables.dart';
import 'package:moi/app_storages/secure_storages.dart';
import 'package:moi/app_utils/app_providers/user_provider.dart';
import 'package:provider/provider.dart';

/// Redirects to login when there is no JWT session.
class AuthGuard extends StatefulWidget {
  final Widget child;

  const AuthGuard({super.key, required this.child});

  @override
  State<AuthGuard> createState() => _AuthGuardState();
}

class _AuthGuardState extends State<AuthGuard> {
  bool _checking = true;
  bool _allowed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verify());
  }

  Future<void> _verify() async {
    final storage = SecureStorageService();
    final userProvider = context.read<UserProvider>();
    var token = userProvider.jwtToken;
    if (token == null || token.isEmpty) {
      token = await storage.getToken();
      if (token.isNotEmpty) {
        await userProvider.updateJwtToken(token);
      }
    }

    final isLogin = await storage.get(AppVariables.isLogin) ?? false;
    final ok = token.isNotEmpty && isLogin == true;

    if (!mounted) return;
    if (!ok) {
      Navigator.pushNamedAndRemoveUntil(context, 'login', (r) => false);
      return;
    }
    setState(() {
      _allowed = true;
      _checking = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_allowed) {
      return const SizedBox.shrink();
    }
    return widget.child;
  }
}
