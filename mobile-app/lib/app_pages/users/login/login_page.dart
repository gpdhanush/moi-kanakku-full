import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:moi/app_configs/index.dart';
import 'package:moi/app_utils/app_providers/language_provider.dart';
import 'package:moi/app_utils/index.dart';
import 'package:provider/provider.dart';
import 'login_controller.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final LoginController _controller = LoginController();

  @override
  void initState() {
    super.initState();
    pageTitleLogs("LOGIN PAGE");
    // _controller.emailCtrl.text = "agprakash406@gmail.com";
    // _controller.passCtrl.text = "Renzo@1995";
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: SafeArea(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildHeaderImage(),
                    const SizedBox(height: 25),
                    _buildTitleText(theme, languageProvider),
                    const SizedBox(height: 25),
                    _buildEmailField(theme, languageProvider),
                    const SizedBox(height: 16),
                    _buildPasswordField(theme, languageProvider),
                    const SizedBox(height: 25),
                    _buildLoginButton(theme, languageProvider),
                    const SizedBox(height: 16),
                    _buildSignupButton(context, theme, languageProvider),
                    _buildForgotPasswordButton(
                      context,
                      theme,
                      languageProvider,
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderImage() {
    return Image.asset(
      AppImages.loginBackgroundImage,
      fit: BoxFit.cover,
      height: 250,
      width: double.infinity,
    );
  }

  Widget _buildTitleText(ThemeData theme, LanguageProvider languageProvider) {
    return Column(
      children: [
        Text(
          languageProvider.tr('login.title'),
          style: theme.textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 24.0,
            fontFamily: 'tamilFont',
          ),
        ),
        SizedBox(height: 8),
        Text(
          languageProvider.tr('login.subtitle'),
          style: theme.textTheme.bodyMedium?.copyWith(
            color: Colors.black87,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildEmailField(ThemeData theme, LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormWidget(
        title: languageProvider.tr('login.email'),
        prefixIcon: Icons.email_outlined,
        required: true,
        controller: _controller.emailCtrl,
        keyboardType: TextInputType.emailAddress,
        textCapitalization: TextCapitalization.none,
        validator: _controller.validateEmail,
      ),
    );
  }

  Widget _buildPasswordField(
    ThemeData theme,
    LanguageProvider languageProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: TextFormWidget(
        title: languageProvider.tr('login.password'),
        prefixIcon: Icons.lock_outline,
        maxLines: 1,
        controller: _controller.passCtrl,
        maxLength: 64,
        obscureText: _controller.showPass,
        required: true,
        obscuringCharacter: "●",
        textInputAction: TextInputAction.done,
        suffixIconTrue: true,
        suffixIcon: _controller.showPass
            ? Icons.visibility_outlined
            : Icons.visibility_off_outlined,
        suffixIconOnPressed: () {
          setState(() {
            _controller.togglePasswordVisibility();
          });
        },
        validator: (value) =>
            _controller.validatePassword(value, languageProvider),
      ),
    );
  }

  Widget _buildLoginButton(ThemeData theme, LanguageProvider languageProvider) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: AppButton(
        title: languageProvider.tr('login.loginNow'),
        onPressed: () {
          FocusScope.of(context).unfocus();
          if (_formKey.currentState!.validate()) {
            _formKey.currentState!.save();
            _controller.submitLogin(context);
          }
        },
      ),
    );
  }

  Widget _buildSignupButton(
    BuildContext context,
    ThemeData theme,
    LanguageProvider languageProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          TextButton(
            onPressed: () {
              Navigator.pushNamed(context, "signup");
            },
            child: Text(
              languageProvider.tr('login.createAccount'),
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                decoration: TextDecoration.underline,
                decorationThickness: 1.5,
                decorationColor: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForgotPasswordButton(
    BuildContext context,
    ThemeData theme,
    LanguageProvider languageProvider,
  ) {
    return TextButton(
      onPressed: () {
        Navigator.pushNamed(context, "forgot_password");
      },
      child: Text(
        languageProvider.tr('login.forgotPassword'),
        overflow: TextOverflow.ellipsis,
        style: theme.textTheme.bodyMedium?.copyWith(
          decoration: TextDecoration.underline,
          decorationThickness: 1.5,
          decorationColor: theme.colorScheme.primary,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
    );
  }
}
