import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_theme.dart';
import 'core/network/api_client.dart';
import 'core/network/api_endpoints.dart';

import 'core/providers/auth_provider.dart';
import 'core/providers/delivery_provider.dart';
import 'core/providers/notification_provider.dart';
import 'core/providers/connectivity_provider.dart';
import 'core/providers/chat_provider.dart';

import 'core/services/local_storage_service.dart';
import 'core/services/chat_socket_service.dart';

import 'data/repositories/delivery_repository_impl.dart';
import 'data/repositories/notification_repository_impl.dart';
import 'data/repositories/chat_repository_impl.dart';

import 'data/datasources/local/delivery_local_datasource.dart';
import 'data/datasources/local/notification_local_datasource.dart';

import 'data/datasources/remote/delivery_remote_datasource.dart' as remote;
import 'data/datasources/remote/notification_remote_datasource.dart'
    as remoteNotif;
import 'data/datasources/remote/chat_remote_datasource.dart';

import 'domain/usecases/deliveries/accept_order_usecase.dart';
import 'domain/usecases/deliveries/reject_order_usecase.dart';
import 'domain/usecases/deliveries/update_location_usecase.dart';
import 'domain/usecases/deliveries/get_order_detail_usecase.dart';
import 'domain/usecases/deliveries/mark_as_delivered_usecase.dart';
import 'domain/usecases/deliveries/get_available_orders_usecase.dart';
import 'domain/usecases/deliveries/get_assigned_orders_usecase.dart';

import 'domain/usecases/notifications/register_device_usecase.dart';
import 'domain/usecases/notifications/get_notifications_usecase.dart';
import 'domain/usecases/notifications/get_unread_count_usecase.dart';
import 'domain/usecases/notifications/mark_as_read_usecase.dart';
import 'domain/usecases/notifications/mark_all_read_usecase.dart';
import 'domain/usecases/notifications/delete_notification_usecase.dart';

import 'domain/usecases/notifications/unregister_device_usecase.dart';
import 'domain/usecases/notifications/get_devices_usecase.dart';
import 'domain/usecases/notifications/delete_device_usecase.dart';

import 'presentation/routes/app_routes.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await LocalStorageService.init();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final ApiClient apiClient;

  late final AuthProvider _authProvider;

  late final DeliveryRepositoryImpl deliveryRepository;
  late final NotificationRepositoryImpl notificationRepository;

  late final RegisterDeviceUseCase registerDeviceUseCase;

  // ===== CHAT =====
  late final ChatSocketService chatSocketService;
  late final ChatRemoteDataSource chatRemoteDataSource;
  late final ChatRepositoryImpl chatRepository;
  late final ChatProvider chatProvider;

  @override
  void initState() {
    super.initState();

    apiClient = ApiClient()..init();

    final deliveryRemoteDataSource = remote.DeliveryRemoteDataSource(apiClient);
    final deliveryLocalDataSource = DeliveryLocalDataSource();

    deliveryRepository = DeliveryRepositoryImpl(
      remoteDataSource: deliveryRemoteDataSource,
      localDataSource: deliveryLocalDataSource,
    );

    final notificationRemoteDataSource =
        remoteNotif.NotificationRemoteDataSource(apiClient);
    final notificationLocalDataSource = NotificationLocalDataSource();

    notificationRepository = NotificationRepositoryImpl(
      remoteDataSource: notificationRemoteDataSource,
      localDataSource: notificationLocalDataSource,
    );

    registerDeviceUseCase = RegisterDeviceUseCase(notificationRepository);

    // Auth se crea aquí para poder inyectar el userId al repo de chat.
    _authProvider = AuthProvider(
      apiClient: apiClient,
      registerDeviceUseCase: registerDeviceUseCase,
    );

    // ===== CHAT =====
    chatRemoteDataSource = ChatRemoteDataSource(client: apiClient);

    chatSocketService = ChatSocketService(
      baseWsUrl: ApiEndpoints.wsBaseUrl,
      tokenProvider: () => LocalStorageService().getToken(),
    );

    chatRepository = ChatRepositoryImpl(
      remote: chatRemoteDataSource,
      socket: chatSocketService,
      currentUserIdProvider: () => _authProvider.currentUser?.id ?? 0,
    );

    chatProvider = ChatProvider(repo: chatRepository);
  }

  @override
  Widget build(BuildContext context) {
    final notificationLocalDataSource = NotificationLocalDataSource();

    return MultiProvider(
      providers: [
        Provider<RegisterDeviceUseCase>.value(value: registerDeviceUseCase),

        // ⚠️ Ahora AuthProvider usa .value porque lo creamos en initState
        ChangeNotifierProvider<AuthProvider>.value(value: _authProvider),

        ChangeNotifierProvider(create: (_) => ConnectivityProvider()),

        ChangeNotifierProvider(
          create: (_) => DeliveryProvider(
            getAvailableOrdersUseCase: GetAvailableOrdersUseCase(
              deliveryRepository,
            ),
            getAssignedOrdersUseCase: GetAssignedOrdersUseCase(
              deliveryRepository,
            ),
            getOrderDetailUseCase: GetOrderDetailUseCase(deliveryRepository),
            acceptOrderUseCase: AcceptOrderUseCase(deliveryRepository),
            rejectOrderUseCase: RejectOrderUseCase(deliveryRepository),
            updateLocationUseCase: UpdateLocationUseCase(deliveryRepository),
            markAsDeliveredUseCase: MarkAsDeliveredUseCase(deliveryRepository),
          ),
        ),

        ChangeNotifierProvider(
          create: (_) => NotificationProvider(
            getNotificationsUseCase: GetNotificationsUseCase(
              notificationRepository,
            ),
            getUnreadCountUseCase: GetUnreadCountUseCase(
              notificationRepository,
            ),
            markAsReadUseCase: MarkAsReadUseCase(notificationRepository),
            markAllReadUseCase: MarkAllReadUseCase(notificationRepository),
            deleteNotificationUseCase: DeleteNotificationUseCase(
              notificationRepository,
            ),
            registerDeviceUseCase: registerDeviceUseCase,
            unregisterDeviceUseCase: UnregisterDeviceUseCase(
              notificationRepository,
            ),
            getDevicesUseCase: GetDevicesUseCase(notificationRepository),
            deleteDeviceUseCase: DeleteDeviceUseCase(notificationRepository),
            localDataSource: notificationLocalDataSource,
          ),
        ),

        // ===== CHAT =====
        Provider<ChatSocketService>.value(value: chatSocketService),
        Provider<ChatRepositoryImpl>.value(value: chatRepository),
        ChangeNotifierProvider<ChatProvider>.value(value: chatProvider),
      ],

      child: const AppRouterWidget(),
    );
  }
}

class AppRouterWidget extends StatelessWidget {
  const AppRouterWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final router = AppRouter.router(authProvider);

        return MaterialApp.router(
          title: 'Sabix Repartidor',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          routerConfig: router,
          builder: (context, child) {
            return Consumer<ConnectivityProvider>(
              builder: (context, connectivity, _) {
                if (!connectivity.hasInternet) {
                  return Scaffold(
                    body: Column(
                      children: [
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          color: Colors.red,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.wifi_off, color: Colors.white),
                              SizedBox(width: 8),
                              Text(
                                'Sin conexión a internet',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                        Expanded(child: child ?? const SizedBox()),
                      ],
                    ),
                  );
                }
                return child ?? const SizedBox();
              },
            );
          },
        );
      },
    );
  }
}
