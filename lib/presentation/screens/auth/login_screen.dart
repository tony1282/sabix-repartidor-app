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
      body: SafeArea(
        child: Consumer2<AuthProvider, ConnectivityProvider>(
          builder: (context, auth, connectivity, _) {
            // Loading
            if (auth.isLoading) {
              return const LoadingWidget(message: 'Iniciando sesión...');
            }

            // Sin internet
            if (!connectivity.hasInternet) {
              return NoInternetWidget(
                onRetry: () => connectivity.checkInternet(),
              );
            }

            // Error
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

            return Padding(
              padding: const EdgeInsets.all(AppConstants.spacingXXL),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 30,
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo.jpg',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Icon(
                              Icons.delivery_dining,
                              size: 50,
                              color: AppColors.primary,
                            );
                          },
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingXXL),

                    const Text(
                      '¡Bienvenido de vuelta!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    const Text(
                      'Inicia sesión para continuar',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppConstants.spacingXXL),

                    // Username
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Usuario',
                      hint: 'juan123',
                      prefixIcon: Icons.person,
                      validator: Validators.required,
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // Contraseña
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Contraseña',
                      hint: 'Ingresa tu contraseña',
                      prefixIcon: Icons.lock,
                      suffixIcon: _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixPressed: () {
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                      obscureText: _obscurePassword,
                      validator: Validators.validatePassword,
                    ),

                    const SizedBox(height: AppConstants.spacingXXXL),

                    // Botón Login
                    CustomButton(
                      text: 'Iniciar Sesión',
                      onPressed: () => _login(context),
                      isLoading: auth.isLoading,
                    ),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Link a Registro
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿No tienes cuenta?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go('/register'),
                          child: const Text(
                            'Regístrate',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ============================================
  // 🔥 LOGIN CORREGIDO
  // ============================================
  Future<void> _login(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();

      // ✅ Se toma la referencia ANTES del await, mientras el widget
      // sigue montado. Leer el context después de un await (como se
      // hacía antes) puede tronar con "deactivated widget's ancestor
      // is unsafe" si para entonces ya se navegó/desmontó la pantalla.
      final registerDeviceUseCase = context.read<RegisterDeviceUseCase>();

      final success = await auth.login(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
      );

      if (success) {
        // ✅ El registro de FCM NO depende del widget/context sigan vivos
        // (ya capturamos registerDeviceUseCase antes del await), así que
        // se dispara aquí, ANTES del chequeo de `mounted`. Si se pusiera
        // después, go_router puede haber desmontado ya esta pantalla por
        // el redirect automático a /home que ocurre en cuanto
        // AuthProvider marca authenticated=true, y este código nunca se
        // llegaría a ejecutar.
        // ignore: unawaited_futures
        FirebaseNotificationService(
          registerDeviceUseCase: registerDeviceUseCase,
        ).initialize();
      }

      if (!mounted) return;

      if (success) {
        // ✅ Obtener el usuario actual desde AuthProvider
        final user = auth.currentUser;
        // ✅ Usar fullName (o username como fallback)
        final deliveryName = user?.fullName ?? user?.username ?? '';

        // ✅ Configurar el DeliveryProvider con el nombre del repartidor
        final deliveryProvider = context.read<DeliveryProvider>();
        deliveryProvider.setCurrentDeliveryName(deliveryName);

        // ✅ Cargar los pedidos asignados a este repartidor
        await deliveryProvider.loadAssignedOrders();

        // ✅ Restaurar un pedido activo (si existe)
        await deliveryProvider.restoreActiveOrder();

        // ✅ Redirigir al Home
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
