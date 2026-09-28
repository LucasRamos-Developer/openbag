import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:responsive_framework/responsive_framework.dart';
import 'package:flutter_web_plugins/url_strategy.dart';

import 'screens/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/auth/register_screen.dart';
import 'screens/onboarding/restaurant_onboarding_screen.dart';
import 'screens/onboarding/association_onboarding_screen.dart';
import 'screens/association/association_panel_screen.dart';
import 'screens/admin/admin_panel_screen.dart';
import 'screens/admin/admin_section.dart';
import 'screens/restaurant_panel/restaurant_panel_screen.dart';
import 'screens/kitchen/kitchen_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/restaurant/restaurant_page_screen.dart';
import 'screens/checkout/checkout_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/cart/cart_screen.dart';
import 'screens/orders/orders_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'models/user.dart';
import 'services/auth_service.dart';
import 'services/association_service.dart';
import 'services/restaurant_panel_service.dart';
import 'services/restaurant_service.dart';
import 'services/cart_service.dart';
import 'services/cooperative_service.dart';
import 'services/member_area_service.dart';
import 'services/order_service.dart';
import 'services/review_service.dart';
import 'services/realtime_service.dart';
import 'services/restaurant_orders_service.dart';
import 'core/ui/ui.dart';
import 'core/ui/showcase/ui_components_showcase.dart';
import 'constants/app_constants.dart';

import 'screens/courier/courier_panel_screen.dart';
import 'screens/courier/public_courier_screen.dart';
import 'screens/onboarding/courier_onboarding_screen.dart';
import 'services/courier_service.dart';
import 'services/courier_work_service.dart';
import 'services/restaurant_delivery_service.dart';
import 'services/restaurant_cash_service.dart';
import 'services/restaurant_routes_service.dart';
import 'screens/association/association_section.dart';
import 'screens/courier/courier_section.dart';
import 'screens/restaurant_panel/menu_form_route.dart';
import 'screens/restaurant_panel/restaurant_section.dart';
import 'screens/restaurant_panel/store_order_screen.dart';
import 'widgets/navigation/panel_routes.dart';

void main() {
  usePathUrlStrategy(); // Remove o # das URLs (somente para Web)
  // push/pop também atualizam a URL (página do restaurante e pedido ficam compartilháveis)
  GoRouter.optionURLReflectsImperativeAPIs = true;
  runApp(const OpenBagApp());
}

class OpenBagApp extends StatefulWidget {
  const OpenBagApp({super.key});

  @override
  State<OpenBagApp> createState() => _OpenBagAppState();
}

class _OpenBagAppState extends State<OpenBagApp> {
  // Criados uma única vez: o router depende do AuthService para os redirects
  final AuthService _authService = AuthService();
  late final GoRouter _router = buildRouter(_authService);
  late final RealtimeService _realtime = RealtimeService(_authService);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authService),
        ChangeNotifierProvider(create: (_) => AssociationService(_authService.apiClient)),
        ChangeNotifierProvider(create: (_) => CourierService(_authService.apiClient)),
        ChangeNotifierProvider(create: (_) => RestaurantPanelService(_authService.apiClient)),
        ChangeNotifierProvider(create: (_) => RestaurantDeliveryService(_authService.apiClient)),
        Provider(create: (_) => RestaurantCashService(_authService.apiClient)),
        Provider(create: (_) => RestaurantRoutesService(_authService.apiClient)),
        ChangeNotifierProvider(create: (_) => RestaurantService(_authService.apiClient)),
        Provider(create: (_) => OrderService(_authService.apiClient)),
        Provider(create: (_) => CooperativeService(_authService.apiClient)),
        Provider(create: (_) => MemberAreaService(_authService.apiClient)),
        Provider(create: (_) => ReviewService(_authService.apiClient)),
        ChangeNotifierProvider.value(value: _realtime),
        ChangeNotifierProvider(create: (_) => RestaurantOrdersService(_authService.apiClient, _realtime)),
        ChangeNotifierProvider(create: (_) => CourierWorkService(_authService.apiClient, _realtime)),
        ChangeNotifierProvider(create: (_) => CartService()),
      ],
      child: MaterialApp.router(
        title: AppConstants.appName,
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.light,
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
        builder: (context, child) => ResponsiveBreakpoints.builder(
          child: child!,
          breakpoints: [
            const Breakpoint(start: 0, end: 450, name: MOBILE),
            const Breakpoint(start: 451, end: 800, name: TABLET),
            const Breakpoint(start: 801, end: 1920, name: DESKTOP),
            const Breakpoint(start: 1921, end: double.infinity, name: '4K'),
          ],
        ),
      ),
    );
  }
}

/// Rotas que exigem login e um perfil específico
/// Rotas que exigem login; o valor é o perfil exigido (null = qualquer usuário logado)
const Map<String, String?> _protectedRoutes = {
  '/associacao': UserRoles.associationManager,
  '/admin': UserRoles.admin,
  '/restaurante': UserRoles.restaurantOwner,
  '/entregador': UserRoles.deliveryPerson,
  '/checkout': null,
  '/pedidos': null,
};

GoRouter buildRouter(AuthService authService) => GoRouter(
  initialLocation: '/',
  refreshListenable: authService,
  redirect: (context, state) {
    final path = state.matchedLocation;
    final protected = _protectedRoutes.entries
        .where((e) => path == e.key || path.startsWith('${e.key}/'))
        .firstOrNull;
    if (protected == null) return null;

    // Sessão ainda sendo restaurada: a splash decide o destino
    if (!authService.isInitialized) return '/';
    if (!authService.isAuthenticated) return Uri(path: '/login', queryParameters: {'next': state.uri.toString()}).toString();
    final requiredRole = protected.value;
    if (requiredRole != null && !authService.currentUser!.hasRole(requiredRole)) return authService.homeRoute;
    return null;
  },
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/registrar/usuario',
      builder: (context, state) => const RegisterScreen(),
    ),
    GoRoute(
      path: '/registrar/restaurante',
      builder: (context, state) => const RestaurantOnboardingScreen(),
    ),
    GoRoute(
      path: '/registrar/associacao',
      builder: (context, state) => const AssociationOnboardingScreen(),
    ),
    GoRoute(
      path: '/registrar/entregador',
      builder: (context, state) => CourierOnboardingScreen(inviteCode: state.uri.queryParameters['convite']),
    ),
    ...panelRoutes(
      base: '/associacao',
      sections: AssociationSection.values,
      builder: (section, tab) => AssociationPanelScreen(section: section, tab: tab),
    ),
    ...panelRoutes(
      base: '/entregador',
      sections: CourierSection.values,
      builder: (section, tab) => CourierPanelScreen(section: section, tab: tab),
    ),
    GoRoute(
      path: '/e/:slug',
      builder: (context, state) => PublicCourierScreen(slug: state.pathParameters['slug']!),
    ),
    // Rotas específicas do restaurante antes das seções do painel
    GoRoute(
      path: '/restaurante/cozinha',
      builder: (context, state) => const KitchenScreen(),
    ),
    GoRoute(
      path: storeOrderPath,
      builder: (context, state) => const StoreOrderScreen(),
    ),
    GoRoute(
      path: '/restaurante/cardapio/:tipo/:id',
      redirect: (context, state) =>
          MenuFormKind.fromSlug(state.pathParameters['tipo']) == null ? RestaurantSection.menu.path : null,
      builder: (context, state) => MenuFormRoute(
        kind: MenuFormKind.fromSlug(state.pathParameters['tipo'])!,
        id: int.tryParse(state.pathParameters['id']!),
        sectionId: int.tryParse(state.uri.queryParameters['secao'] ?? ''),
      ),
    ),
    ...panelRoutes(
      base: '/restaurante',
      sections: RestaurantSection.values,
      builder: (section, tab) => RestaurantPanelScreen(section: section, storeSection: StoreSection.fromSlug(tab)),
    ),
    ...panelRoutes(
      base: '/admin',
      sections: AdminSection.values,
      builder: (section, _) => AdminPanelScreen(section: section),
    ),
    GoRoute(
      path: '/ui-showcase',
      builder: (context, state) => const UIComponentsShowcase(),
    ),
    GoRoute(
      path: '/home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/r/:slug',
      builder: (context, state) => RestaurantPageScreen(
        slug: state.pathParameters['slug']!,
        previewTheme: state.uri.queryParameters['tema'],
        previewColor: state.uri.queryParameters['cor'],
      ),
    ),
    // Endereço antigo por id: a página aceita slug ou id
    GoRoute(
      path: '/restaurant/:id',
      redirect: (context, state) => '/r/${state.pathParameters['id']}',
    ),
    GoRoute(
      path: '/checkout',
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: '/pedidos',
      builder: (context, state) => const OrdersScreen(),
    ),
    GoRoute(
      path: '/pedidos/:id',
      builder: (context, state) => OrderDetailScreen(orderId: int.parse(state.pathParameters['id']!)),
    ),
    GoRoute(
      path: '/cart',
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: '/orders',
      redirect: (context, state) => '/pedidos',
    ),
    GoRoute(
      path: '/profile',
      builder: (context, state) => const ProfileScreen(),
    ),
  ],
);
