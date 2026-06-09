import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'firebase_options.dart';
import 'modules/providers/auth_provider.dart';
import 'modules/providers/booking_provider.dart';
import 'modules/providers/route_provider.dart';
import 'modules/providers/driver_provider.dart';
import 'modules/screens/login_screens.dart';

// Global navigator key
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Handle background messages
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

// Show notification at TOP using navigatorKey overlay
void showTopNotification(String title, String body) {
  final overlayState = navigatorKey.currentState?.overlay;
  if (overlayState == null) return;

  late OverlayEntry overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      top: MediaQuery.of(context).padding.top + 10,
      left: 16,
      right: 16,
      child: Material(
        color: Colors.transparent,
        child: _NotificationBanner(
          title: title,
          body: body,
          onDismiss: () {
            try {
              overlayEntry.remove();
            } catch (_) {}
          },
        ),
      ),
    ),
  );

  overlayState.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 4), () {
    try {
      overlayEntry.remove();
    } catch (_) {}
  });
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  runApp(const MyApp());

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    print('Foreground notification received: ${message.notification?.title}');
    if (message.notification != null) {
      showTopNotification(
        message.notification!.title ?? 'Online Taxi Service',
        message.notification!.body ?? '',
      );
    }
  });
}

// ==========================================
// APP ROOT
// ==========================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => BookingProvider()),
        ChangeNotifierProvider(create: (_) => RouteProvider()),
        ChangeNotifierProvider(create: (_) => DriverProvider()),
      ],
      child: ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) => MaterialApp(
        title: 'Online Taxi Service',
        navigatorKey: navigatorKey,
        theme: ThemeData(
          primaryColor: Colors.yellow[800],
          scaffoldBackgroundColor: Colors.white,
          colorScheme: ColorScheme.light(
            primary: Colors.yellow[800]!,
            secondary: Colors.yellow[700]!,
            surface: Colors.white,
            background: Colors.white,
            onPrimary: Colors.white,
            onSecondary: Colors.white,
            onSurface: Colors.black,
            onBackground: Colors.black,
          ),
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
            centerTitle: true,
            iconTheme: IconThemeData(color: Colors.black),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.yellow[800],
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.grey),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.yellow[800]!, width: 2),
            ),
            prefixIconColor: Colors.yellow[800],
          ),
          useMaterial3: true,
        ),
        debugShowCheckedModeBanner: false,
        home: const SplashScreen(),
        ),
      ),
    );
  }
}

// ==========================================
// SPLASH SCREEN
// ==========================================
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // Main sequencing controller
  late AnimationController _mainController;

  // Ripple / glow ring controller — loops independently
  late AnimationController _rippleController;

  // Shimmer sweep controller — loops independently
  late AnimationController _shimmerController;

  // ── Main sequence animations ──────────────────────────────
  // Ring expands from centre before logo appears
  late Animation<double> _ringScale;
  late Animation<double> _ringOpacity;

  // Logo
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;

  // Brand name
  late Animation<double> _brandFade;
  late Animation<Offset> _brandSlide;

  // Divider line
  late Animation<double> _dividerWidth;

  // Tagline
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  // Bottom (dots + footer)
  late Animation<double> _bottomFade;

  // Ripple ring (looping)
  late Animation<double> _rippleScale;
  late Animation<double> _rippleOpacity;

  // Shimmer sweep across logo (looping)
  late Animation<double> _shimmerPosition;

  @override
  void initState() {
    super.initState();

    // ── 1. Main controller — 2 400 ms total ─────────────────
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    // Expanding ring (0 ms – 500 ms)
    _ringScale = Tween<double>(begin: 0.4, end: 1.6).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );
    _ringOpacity = Tween<double>(begin: 0.6, end: 0.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.0, 0.22, curve: Curves.easeOut),
      ),
    );

    // Logo — blooms out of the ring (150 ms – 750 ms)
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.06, 0.30, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.60, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.06, 0.36, curve: Curves.easeOutBack),
      ),
    );

    // Brand name (550 ms – 1 050 ms)
    _brandFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.24, 0.48, curve: Curves.easeOut),
      ),
    );
    _brandSlide = Tween<Offset>(
      begin: const Offset(0, 0.4),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.24, 0.48, curve: Curves.easeOut),
      ),
    );

    // Divider line grows outward (900 ms – 1 300 ms)
    _dividerWidth = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.40, 0.58, curve: Curves.easeOut),
      ),
    );

    // Tagline (1 100 ms – 1 550 ms)
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.70, curve: Curves.easeOut),
      ),
    );
    _taglineSlide = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.50, 0.70, curve: Curves.easeOut),
      ),
    );

    // Bottom elements (1 600 ms – 2 200 ms)
    _bottomFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.70, 0.92, curve: Curves.easeOut),
      ),
    );

    // ── 2. Ripple controller — loops after logo settles ─────
    _rippleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _rippleScale = Tween<double>(begin: 1.0, end: 1.55).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );
    _rippleOpacity = Tween<double>(begin: 0.45, end: 0.0).animate(
      CurvedAnimation(parent: _rippleController, curve: Curves.easeOut),
    );

    // ── 3. Shimmer controller — loops continuously ───────────
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _shimmerPosition = Tween<double>(begin: -1.0, end: 2.0).animate(
      CurvedAnimation(parent: _shimmerController, curve: Curves.easeInOut),
    );

    // Start main sequence
    _mainController.forward();

    // Start ripple + shimmer once logo has fully appeared (~900 ms)
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) {
        _rippleController.repeat();
        _shimmerController.repeat(period: const Duration(milliseconds: 2800));
      }
    });

    // Navigate to LoginScreen with a smooth fade
    Future.delayed(const Duration(milliseconds: 3400), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const LoginScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 700),
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _rippleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final accent = Colors.yellow[800]!;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: Listenable.merge(
              [_mainController, _rippleController, _shimmerController]),
          builder: (context, _) {
            return Column(
              children: [
                const Spacer(flex: 3),

                // ── Logo + ripple ring ───────────────────────
                SizedBox(
                  width: 220,
                  height: 220,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Intro expanding ring
                      if (_ringOpacity.value > 0)
                        Transform.scale(
                          scale: _ringScale.value,
                          child: Opacity(
                            opacity: _ringOpacity.value,
                            child: Container(
                              width: 180,
                              height: 180,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: accent,
                                  width: 2.5,
                                ),
                              ),
                            ),
                          ),
                        ),

                      // Looping ripple ring
                      Transform.scale(
                        scale: _rippleScale.value,
                        child: Opacity(
                          opacity: _rippleOpacity.value,
                          child: Container(
                            width: 168,
                            height: 168,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: accent,
                                width: 2,
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Logo with shimmer overlay
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: ClipOval(
                            child: SizedBox(
                              width: 168,
                              height: 168,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  // Logo image
                                  Image.asset(
                                    'assets/images/taxi_logo.png',
                                    width: 168,
                                    height: 168,
                                    fit: BoxFit.contain,
                                  ),

                                  // Shimmer sweep
                                  Positioned.fill(
                                    child: ShaderMask(
                                      blendMode: BlendMode.srcATop,
                                      shaderCallback: (bounds) {
                                        return LinearGradient(
                                          begin: Alignment(
                                              _shimmerPosition.value - 0.4, -0.5),
                                          end: Alignment(
                                              _shimmerPosition.value + 0.4, 0.5),
                                          colors: [
                                            Colors.white.withOpacity(0.0),
                                            Colors.white.withOpacity(0.30),
                                            Colors.white.withOpacity(0.0),
                                          ],
                                          stops: const [0.0, 0.5, 1.0],
                                        ).createShader(bounds);
                                      },
                                      child: Container(
                                        color: Colors.white.withOpacity(0.01),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 28),

                // ── Brand name ───────────────────────────────
                FadeTransition(
                  opacity: _brandFade,
                  child: SlideTransition(
                    position: _brandSlide,
                    child: const Text(
                      'Easy Ride',
                      style: TextStyle(
                        fontSize: 25,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 2.0,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Animated divider ─────────────────────────
                Align(
                  alignment: Alignment.center,
                  child: FractionallySizedBox(
                    widthFactor: _dividerWidth.value * 0.35,
                    child: Container(
                      height: 2,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ── Tagline ──────────────────────────────────
                FadeTransition(
                  opacity: _taglineFade,
                  child: SlideTransition(
                    position: _taglineSlide,
                    child: Text(
                      'Your ride, on demand',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                ),

                const Spacer(flex: 2),

                // ── Pulsing dots ─────────────────────────────
                Opacity(
                  opacity: _bottomFade.value,
                  child: _PulsingDots(color: accent),
                ),

                const SizedBox(height: 28),

                // ── Footer ───────────────────────────────────
                Opacity(
                  opacity: _bottomFade.value,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.local_taxi, size: 12, color: Colors.grey[400]),
                      const SizedBox(width: 5),
                      Text(
                        'Online Taxi Service',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ==========================================
// PULSING DOTS
// ==========================================
class _PulsingDots extends StatefulWidget {
  final Color color;
  const _PulsingDots({required this.color});

  @override
  State<_PulsingDots> createState() => _PulsingDotsState();
}

class _PulsingDotsState extends State<_PulsingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        return AnimatedBuilder(
          animation: _ctrl,
          builder: (_, __) {
            final delay = i * 0.25;
            final t = ((_ctrl.value - delay + 1.0) % 1.0);
            final opacity = 0.2 + 0.8 * (t < 0.5 ? t * 2 : (1.0 - t) * 2);
            final scale = 0.65 + 0.35 * (t < 0.5 ? t * 2 : (1.0 - t) * 2);
            return Transform.scale(
              scale: scale,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: widget.color.withOpacity(opacity),
                  shape: BoxShape.circle,
                ),
              ),
            );
          },
        );
      }),
    );
  }
}

// ==========================================
// NOTIFICATION BANNER
// ==========================================
class _NotificationBanner extends StatefulWidget {
  final String title;
  final String body;
  final VoidCallback onDismiss;

  const _NotificationBanner({
    required this.title,
    required this.body,
    required this.onDismiss,
  });

  @override
  State<_NotificationBanner> createState() => _NotificationBannerState();
}

class _NotificationBannerState extends State<_NotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -1.2),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: Colors.yellow[800]!.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.yellow[800],
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.local_taxi,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.body,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: widget.onDismiss,
                child: Icon(Icons.close, size: 17, color: Colors.grey[400]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}