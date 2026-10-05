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
// lib/presentation/screens/auth/register_screen.dart

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _phoneController = TextEditingController();

  // ✅ SOLO REPARTIDOR
  String _selectedVehicleType = 'Moto';
  final TextEditingController _vehiclePlateController = TextEditingController(
    text: 'ABC-123',
  );

  final List<String> _vehicleTypes = [
    'Moto',
    'Bicicleta',
    'Automóvil',
    'Camioneta',
    'A pie',
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          // ✅ Botón físico de retroceso → ir a login
          context.go('/login');
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text('Registro de Repartidor'),
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.textWhite,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => context.go('/login'),
            tooltip: 'Volver al inicio de sesión',
          ),
        ),
        body: Consumer2<AuthProvider, ConnectivityProvider>(
          builder: (context, auth, connectivity, _) {
            if (auth.isLoading) {
              return const LoadingWidget(message: 'Creando cuenta...');
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

            return SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.spacingXXL),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Logo
                    Center(
                      child: Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpg',
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Icon(
                                Icons.delivery_dining,
                                size: 60,
                                color: AppColors.primary,
                              );
                            },
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Título
                    const Text(
                      'Registro de Repartidor',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingXS),
                    const Text(
                      'Completa tus datos para comenzar a repartir',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: AppConstants.spacingXXL),

                    // Username
                    CustomTextField(
                      controller: _usernameController,
                      label: 'Usuario *',
                      hint: 'Ej: repartidor1',
                      prefixIcon: Icons.person,
                      validator: Validators.validateUsername,
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // Email
                    CustomTextField(
                      controller: _emailController,
                      label: 'Correo electrónico *',
                      hint: 'repartidor@email.com',
                      prefixIcon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      validator: Validators.validateEmail,
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // Nombre y Apellido
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            controller: _firstNameController,
                            label: 'Nombre *',
                            hint: 'Juan',
                            prefixIcon: Icons.person_outline,
                            validator: Validators.validateName,
                          ),
                        ),
                        const SizedBox(width: AppConstants.spacingLG),
                        Expanded(
                          child: CustomTextField(
                            controller: _lastNameController,
                            label: 'Apellido *',
                            hint: 'Pérez',
                            prefixIcon: Icons.person_outline,
                            validator: Validators.validateName,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // Teléfono
                    CustomTextField(
                      controller: _phoneController,
                      label: 'Teléfono *',
                      hint: '10 dígitos',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      validator: Validators.validatePhone,
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // ============================================
                    // TIPO DE VEHÍCULO
                    // ============================================
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.inputBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedVehicleType,
                          isExpanded: true,
                          icon: const Icon(
                            Icons.arrow_drop_down,
                            color: AppColors.primary,
                          ),
                          items: _vehicleTypes.map((String type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedVehicleType = value!;
                            });
                          },
                          style: const TextStyle(
                            fontSize: 16,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // ============================================
                    // PLACA DEL VEHÍCULO
                    // ============================================
                    CustomTextField(
                      controller: _vehiclePlateController,
                      label: 'Placa del vehículo',
                      hint: 'Ej: ABC-1234',
                      prefixIcon: Icons.car_repair,
                    ),
                    const SizedBox(height: AppConstants.spacingLG),

                    // Contraseña
                    CustomTextField(
                      controller: _passwordController,
                      label: 'Contraseña *',
                      hint: 'Mínimo 6 caracteres',
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
                    const SizedBox(height: AppConstants.spacingLG),

                    // Confirmar contraseña
                    CustomTextField(
                      controller: _confirmPasswordController,
                      label: 'Confirmar contraseña *',
                      hint: 'Repite tu contraseña',
                      prefixIcon: Icons.lock_outline,
                      suffixIcon: _obscureConfirmPassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      onSuffixPressed: () {
                        setState(
                          () => _obscureConfirmPassword =
                              !_obscureConfirmPassword,
                        );
                      },
                      obscureText: _obscureConfirmPassword,
                      validator: (value) => Validators.validateConfirmPassword(
                        value,
                        _passwordController.text,
                      ),
                    ),

                    const SizedBox(height: AppConstants.spacingXXXL),

                    // Botón Registrar
                    CustomButton(
                      text: 'Registrarme como Repartidor',
                      onPressed: () => _register(context),
                      isLoading: auth.isLoading,
                    ),

                    const SizedBox(height: AppConstants.spacingLG),

                    // Link a Login
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          '¿Ya tienes cuenta?',
                          style: TextStyle(color: AppColors.textSecondary),
                        ),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: const Text(
                            'Inicia sesión',
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
  // REGISTRO - SIEMPRE DELIVERY
  // ============================================
  Future<void> _register(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      final auth = context.read<AuthProvider>();

      // ✅ Se toma la referencia ANTES del await, mientras el widget
      // sigue montado (mismo fix que en login_screen.dart).
      final registerDeviceUseCase = context.read<RegisterDeviceUseCase>();

      final success = await auth.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: _firstNameController.text.trim(),
        lastName: _lastNameController.text.trim(),
        phone: _phoneController.text.trim(),
        vehicleType: _selectedVehicleType,
        vehiclePlate: _vehiclePlateController.text.trim(),
      );

      if (success) {
        // ✅ Igual que en login_screen.dart: se dispara ANTES del
        // chequeo de `mounted`, porque no depende del widget vivo y
        // go_router puede desmontar esta pantalla apenas
        // AuthProvider marca authenticated=true.
        // ignore: unawaited_futures
        FirebaseNotificationService(
          registerDeviceUseCase: registerDeviceUseCase,
        ).initialize();
      }

      if (!mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('¡Registro exitoso como Repartidor! 🏍️'),
            backgroundColor: AppColors.success,
          ),
        );
        await context.read<DeliveryProvider>().restoreActiveOrder();
        if (mounted) context.go('/home');
      }
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _vehiclePlateController.dispose();
    super.dispose();
  }
}
