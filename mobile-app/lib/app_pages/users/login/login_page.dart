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
    pageTitleLogs('LOGIN PAGE');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final languageProvider = context.watch<LanguageProvider>();
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarIconBrightness: Brightness.dark,
      ),
      child: PopScope(
        canPop: false,
        child: SafeArea(
          child: Scaffold(
            resizeToAvoidBottomInset: true,
            body: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _buildHeaderImage(),
                          const SizedBox(height: 25),
                          _buildTitleText(theme, languageProvider),
                          const SizedBox(height: 25),
                          _buildEmailField(theme, languageProvider),
                          const SizedBox(height: 16),
                          _buildPasswordField(theme, languageProvider),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Padding(
                              padding: const EdgeInsets.only(right: 15, top: 4),
                              child: _buildForgotPasswordButton(
                                context,
                                theme,
                                languageProvider,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildLoginButton(theme, languageProvider),
                          const SizedBox(height: 50),
                          _buildSignupSection(context, theme, languageProvider),
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),
                ),
                if (!isKeyboardOpen) _BottomPattern(color: primary),
              ],
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
            fontFamily: 'Inter',
          ),
        ),
        const SizedBox(height: 8),
        Text(
          languageProvider.tr('login.subtitle'),
          textAlign: TextAlign.center,
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
        obscuringCharacter: '●',
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

  Widget _buildSignupSection(
    BuildContext context,
    ThemeData theme,
    LanguageProvider languageProvider,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            '${languageProvider.tr('login.noAccount')} ',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.black54,
              fontWeight: FontWeight.w500,
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, 'signup'),
            child: Text(
              languageProvider.tr('login.createAccount'),
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
        Navigator.pushNamed(context, 'forgot_password');
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
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

class _BottomPattern extends StatelessWidget {
  final Color color;

  const _BottomPattern({required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 72,
      width: double.infinity,
      child: CustomPaint(painter: _LoginBottomPatternPainter(color: color)),
    );
  }
}

class _LoginBottomPatternPainter extends CustomPainter {
  final Color color;

  _LoginBottomPatternPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final soft = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..style = PaintingStyle.fill;
    final mid = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    final dot = Paint()
      ..color = color.withValues(alpha: 0.18)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(size.width * 0.12, size.height * 1.15), 48, soft);
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 1.05), 56, soft);
    canvas.drawCircle(Offset(size.width * 0.50, size.height * 1.35), 70, mid);

    const spacing = 18.0;
    for (double x = 10; x < size.width; x += spacing) {
      for (double y = 18; y < size.height - 8; y += spacing) {
        final offset = ((x / spacing).round() + (y / spacing).round()).isEven
            ? 0.0
            : 4.0;
        canvas.drawCircle(Offset(x + offset, y), 1.6, dot);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _LoginBottomPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
