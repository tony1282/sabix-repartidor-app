import 'package:flutter/material.dart';
import 'package:sabix_repartidor_app/presentation/screens/deliveries/available_orders_screen.dart';
import '../screens/splash_screen.dart';
import 'package:go_router/go_router.dart';
import '../screens/home/home_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../../core/providers/auth_provider.dart';
import '../screens/deliveries/deliveries_screen.dart';
import '../screens/deliveries/delivery_detail_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/settings/settings_screen.dart';
import 'package:provider/provider.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/chat/chat_room_screen.dart';
import '../../core/providers/chat_room_provider.dart';
import '../../core/services/chat_socket_service.dart';
import '../../data/repositories/chat_repository_impl.dart';

class AppRouter {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String deliveries = '/deliveries';
  static const String deliveryDetail = '/delivery/:id';
  static const String notifications = '/notifications';
  static const String availableOrders = '/available-orders';
  static const String profile = '/profile';
  static const String settings = '/settings';
  static const String chatList = '/chats';
  static const String chatRoom = '/chat/:conversationId/:orderId';

  static GoRouter router(
    AuthProvider authProvider, {
    GlobalKey<NavigatorState>? navigatorKey,
  }) {
    return GoRouter(
      navigatorKey: navigatorKey ?? GlobalKey<NavigatorState>(),
      initialLocation: splash,
      refreshListenable: authProvider,

      redirect: (BuildContext context, GoRouterState state) {
        final isAuthenticated = authProvider.isAuthenticated;
        final isGoingToAuth =
            state.matchedLocation == login ||
            state.matchedLocation == register ||
            state.matchedLocation == splash;

        debugPrint('🔄 Redirect - uri: ${state.uri.toString()}');
        debugPrint('🔄 Redirect - matchedLocation: ${state.matchedLocation}');
        debugPrint('🔄 Redirect - authenticated: $isAuthenticated');

        // 🔥 PERMITIR /deliveries SIEMPRE si está autenticado
        if (state.matchedLocation == deliveries && isAuthenticated) {
          debugPrint('🔄 Redirect - permitiendo /deliveries');
          return null;
        }

        if (!isAuthenticated && !isGoingToAuth) {
          debugPrint('🔄 Redirigiendo a login');
          return login;
        }

        if (isAuthenticated && isGoingToAuth) {
          debugPrint('🔄 Redirigiendo a home');
          return home;
        }

        debugPrint('🔄 No redirect, continuando a: ${state.uri.toString()}');
        return null;
      },

      routes: [
        GoRoute(
          path: splash,
          name: 'splash',
          builder: (context, state) => const SplashScreen(),
        ),
        GoRoute(
          path: login,
          name: 'login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: register,
          name: 'register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: home,
          name: 'home',
          builder: (context, state) => const HomeScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
        GoRoute(
          path: availableOrders,
          name: 'availableOrders',
          builder: (context, state) => const AvailableOrdersScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
        GoRoute(
          path: deliveries,
          name: 'deliveries',
          builder: (context, state) {
            debugPrint('📦 Construyendo DeliveriesScreen');
            return const DeliveriesScreen();
          },
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) {
              debugPrint('📦 Redirect: no autenticado, a login');
              return login;
            }
            debugPrint('📦 Redirect: autenticado, continuando a deliveries');
            return null;
          },
        ),
        GoRoute(
          path: deliveryDetail,
          name: 'deliveryDetail',
          builder: (context, state) {
            final idParam = state.pathParameters['id'] ?? '0';
            final orderId = int.tryParse(idParam) ?? 0;
            if (orderId == 0) {
              return Scaffold(
                appBar: AppBar(
                  title: const Text('Error'),
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                body: const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 80, color: Colors.red),
                      SizedBox(height: 16),
                      Text(
                        'ID de pedido inválido',
                        style: TextStyle(fontSize: 18),
                      ),
                      SizedBox(height: 24),
                      ElevatedButton(onPressed: null, child: Text('Volver')),
                    ],
                  ),
                ),
              );
            }
            return DeliveryDetailScreen(orderId: orderId);
          },
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
        GoRoute(
          path: notifications,
          name: 'notifications',
          builder: (context, state) => const NotificationsScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
        GoRoute(
          path: profile,
          name: 'profile',
          builder: (context, state) => const ProfileScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
        GoRoute(
          path: settings,
          name: 'settings',
          builder: (context, state) => const SettingsScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),

        GoRoute(
          path: chatList,
          name: 'chatList',
          builder: (context, state) => const ChatListScreen(),
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
        GoRoute(
          path: chatRoom,
          name: 'chatRoom',
          builder: (context, state) {
            final convId = int.tryParse(
              state.pathParameters['conversationId'] ?? '',
            );
            final orderId = int.tryParse(state.pathParameters['orderId'] ?? '');

            if (convId == null || orderId == null) {
              return const Scaffold(
                body: Center(child: Text('Conversación inválida')),
              );
            }

            // ChatRoomProvider se crea fresco por cada chat abierto.
            return ChangeNotifierProvider(
              create: (ctx) => ChatRoomProvider(
                repo: ctx.read<ChatRepositoryImpl>(),
                socket: ctx.read<ChatSocketService>(),
                currentUserId: ctx.read<AuthProvider>().currentUser?.id ?? 0,
              ),
              child: ChatRoomScreen(conversationId: convId, orderId: orderId),
            );
          },
          redirect: (context, state) {
            if (!authProvider.isAuthenticated) return login;
            return null;
          },
        ),
      ],
    );
  }
}

extension GoRouterExtension on GoRouter {
  void goToLogin() => go(AppRouter.login);
  void goToRegister() => go(AppRouter.register);
  void goToHome() => go(AppRouter.home);
  void goToDeliveries() => go(AppRouter.deliveries);
  void goToDeliveryDetail(int orderId) => go('/delivery/$orderId');
  void goToNotifications() => go(AppRouter.notifications);
  void goBack() => pop();
  void goToChatList() => go(AppRouter.chatList);
  void goToChatRoom(int conversationId, int orderId) =>
      go('/chat/$conversationId/$orderId');
}
