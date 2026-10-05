import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/loading_widget.dart';
import '../../../core/utils/validators.dart';
import '../../../core/config/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/no_internet_widget.dart';
import '../../../core/config/app_constants.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/connectivity_provider.dart';
import 'package:sabix_repartidor_app/core/providers/delivery_provider.dart';
import '../../../core/services/firebase_notification_service.dart';
import '../../../domain/usecases/notifications/register_device_usecase.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Consumer2<AuthProvider, ConnectivityProvider>(
        builder: (context, auth, connectivity, _) {
          if (auth.isLoading) {
            return const LoadingWidget(message: 'Iniciando sesión...');
          }

          if (!connectivity.hasInternet) {
            return NoInternetWidget(
              onRetry: () => connectivity.checkInternet(),
            );
          }

          if (auth.errorMessage != null) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(auth.errorMessage!),
                  backgroundColor: AppColors.error,
                ),
              );
              auth.clearError();
            });
          }

          return SafeArea(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  // Header con gradiente
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 48, 24, 40),
                    decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.15),
                                blurRadius: 20,
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/logo.jpg',
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                Icons.delivery_dining,
                                size: 40,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Bienvenido de vuelta',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Inicia sesión para continuar',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Formulario
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CustomTextField(
                            controller: _usernameController,
                            label: 'Usuario',
                            hint: 'juan123',
                            prefixIcon: Icons.person_outline_rounded,
                            validator: Validators.required,
                          ),
                          const SizedBox(height: AppConstants.spacingLG),
                          CustomTextField(
                            controller: _passwordController,
                            label: 'Contraseña',
                            hint: 'Ingresa tu contraseña',
                            prefixIcon: Icons.lock_outline_rounded,
                            suffixIcon: _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            onSuffixPressed: () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                            obscureText: _obscurePassword,
                            validator: Validators.validatePassword,
                          ),
                          const SizedBox(height: 32),
                          CustomButton(
                            text: 'Iniciar Sesión',
                            onPressed: () => _login(context),
                            isLoading: auth.isLoading,
                          ),
                          const SizedBox(height: AppConstants.spacingLG),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text(
                                'No tienes cuenta?',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              TextButton(
                                onPressed: () => context.go('/register'),
                                child: const Text(
                                  'Registrate',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();
      final registerDeviceUseCase = context.read<RegisterDeviceUseCase>();

      final success = await auth.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        // ignore: unawaited_futures
        FirebaseNotificationService(
          registerDeviceUseCase: registerDeviceUseCase,
        ).initialize();
      }

      if (!mounted) return;

      if (success) {
        final user = auth.currentUser;
        final deliveryName = user?.fullName ?? user?.username ?? '';
        final deliveryProvider = context.read<DeliveryProvider>();
        deliveryProvider.setCurrentDeliveryName(deliveryName);
        await deliveryProvider.loadAssignedOrders();
        await deliveryProvider.restoreActiveOrder();
        if (mounted) context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }
}
