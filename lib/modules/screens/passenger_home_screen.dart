import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/route_provider.dart';
import '../models/taxi_route.dart';
import 'book_ride_screen.dart';
import 'my_bookings_screen.dart';
import 'profile_screen.dart';
import 'login_screens.dart';

class PassengerHomeScreen extends StatefulWidget {
  const PassengerHomeScreen({super.key});

  @override
  State<PassengerHomeScreen> createState() => _PassengerHomeScreenState();
}

class _PassengerHomeScreenState extends State<PassengerHomeScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  int _currentIndex = 0; // Bottom nav index

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.07),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    ));
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<RouteProvider>(context, listen: false).getRoutes();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // ── Logout confirmation dialog ────────────────────────────────
  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.5),
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.yellow[50],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      color: Colors.yellow[100],
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.yellow[800],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.logout_rounded,
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Logging Out?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Would you like to logout from\nEasy Ride?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      style: OutlinedButton.styleFrom(
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey.shade300),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        foregroundColor: Colors.black54,
                      ),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.yellow[800],
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Yes, Logout',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          PageRouteBuilder(
            pageBuilder: (_, animation, __) => FadeTransition(
              opacity: animation,
              child: const LoginScreen(),
            ),
            transitionDuration: const Duration(milliseconds: 500),
          ),
          (route) => false,
        );
      }
    }
  }

  List<TaxiRoute> _filterRoutes(List<TaxiRoute> routes) {
    if (_searchQuery.isEmpty) return routes;
    final query = _searchQuery.toLowerCase().trim();
    return routes.where((route) {
      final pickup  = route.pickupLocation.toLowerCase();
      final dropoff = route.dropoffLocation.toLowerCase();
      return pickup.startsWith(query) ||
          dropoff.startsWith(query) ||
          pickup.contains(query) ||
          dropoff.contains(query);
    }).toList();
  }

  // ── Bottom nav page switch ────────────────────────────────────
  void _onNavTap(int index) {
    if (index == 1) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BookRideScreen()),
      );
      return;
    }
    if (index == 2) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MyBookingsScreen()),
      );
      return;
    }
    if (index == 3) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const ProfileScreen()),
      );
      return;
    }
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final authProvider   = Provider.of<AuthProvider>(context);
    final user           = authProvider.user;
    final routeProvider  = Provider.of<RouteProvider>(context);
    final filteredRoutes = _filterRoutes(routeProvider.routes);
    final profilePhoto   = user?.profilePhoto;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),

      // ── APP BAR ────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Logo image instead of icon
            Image.asset(
              'assets/images/taxi_logo.png',
              width: 36,
              height: 36,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 10),
            const Text(
              'Easy Ride',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w800,
                fontSize: 19,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: InkWell(
              onTap: _confirmLogout,
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.logout_rounded,
                        color: Colors.grey[600], size: 16),
                    const SizedBox(width: 5),
                    Text(
                      'Logout',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),

      // ── BOTTOM NAVIGATION BAR ──────────────────────────────
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border(
            top: BorderSide(color: Colors.grey.shade100, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: _onNavTap,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.yellow[800],
          unselectedItemColor: Colors.grey[400],
          selectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
          elevation: 0,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home_rounded),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.local_taxi_outlined),
              activeIcon: Icon(Icons.local_taxi_rounded),
              label: 'Book Ride',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long_rounded),
              label: 'Bookings',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_outline_rounded),
              activeIcon: Icon(Icons.person_rounded),
              label: 'Profile',
            ),
          ],
        ),
      ),

      // ── BODY ───────────────────────────────────────────────
      body: FadeTransition(
        opacity: _fadeAnim,
        child: SlideTransition(
          position: _slideAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // ── PROFILE CARD (no edit button) ─────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: Row(
                    children: [
                      // Avatar with yellow ring
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.yellow[700]!, width: 2.5),
                        ),
                        child: CircleAvatar(
                          radius: 28,
                          backgroundColor: Colors.yellow[800],
                          backgroundImage: profilePhoto != null
                              ? NetworkImage(profilePhoto)
                              : null,
                          child: profilePhoto == null
                              ? const Icon(Icons.person,
                                  size: 28, color: Colors.white)
                              : null,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              user?.name ?? 'Passenger',
                              style: const TextStyle(
                                color: Colors.black87,
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 1),
                            Text(
                              user?.email ?? '',
                              style: TextStyle(
                                  color: Colors.grey[400], fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),

                      // Passenger badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.yellow[50],
                          borderRadius: BorderRadius.circular(20),
                          border:
                              Border.all(color: Colors.yellow[200]!),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.verified_user_outlined,
                                size: 12, color: Colors.yellow[800]),
                            const SizedBox(width: 4),
                            Text(
                              'Passenger',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Colors.yellow[800],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 26),

                // ── AVAILABLE ROUTES ─────────────────────────
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const _SectionLabel(title: 'Available Routes'),
                    InkWell(
                      onTap: () => Provider.of<RouteProvider>(context,
                              listen: false)
                          .getRoutes(),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Icon(Icons.refresh_rounded,
                            color: Colors.grey[500], size: 18),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ── SEARCH BAR ───────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.grey.shade100),
                  ),
                  child: TextField(
                    controller: _searchController,
                    style: const TextStyle(
                        fontSize: 14, color: Colors.black87),
                    decoration: InputDecoration(
                      hintText: 'Search by location...',
                      hintStyle: TextStyle(
                          color: Colors.grey[400], fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey[400], size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.close_rounded,
                                  color: Colors.grey[400], size: 18),
                              onPressed: () {
                                setState(() {
                                  _searchController.clear();
                                  _searchQuery = '';
                                });
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4, vertical: 14),
                    ),
                    onChanged: (v) => setState(() => _searchQuery = v),
                  ),
                ),
                const SizedBox(height: 12),

                // ── ROUTES TABLE ─────────────────────────────
                routeProvider.isLoading
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.yellow[800]!),
                          ),
                        ),
                      )
                    : filteredRoutes.isEmpty
                        ? Container(
                            padding:
                                const EdgeInsets.symmetric(vertical: 40),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade100),
                            ),
                            child: Column(
                              children: [
                                Icon(Icons.search_off_rounded,
                                    size: 44, color: Colors.grey[300]),
                                const SizedBox(height: 10),
                                Text(
                                  _searchQuery.isEmpty
                                      ? 'No routes available'
                                      : 'No routes for "$_searchQuery"',
                                  style: TextStyle(
                                      color: Colors.grey[400],
                                      fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.grey.shade100),
                            ),
                            clipBehavior: Clip.antiAlias,
                            child: Column(
                              children: [
                                // Header row
                                Container(
                                  color: const Color(0xFF1C1C1E),
                                  child: Row(
                                    children: [
                                      _headerCell('From', flex: 3),
                                      _headerCell('To', flex: 3),
                                      _headerCell('4-Seat', flex: 2,
                                          icon: Icons.directions_car),
                                      _headerCell('7-Seat', flex: 2,
                                          icon: Icons.airport_shuttle),
                                      _headerCell('8-Seat', flex: 2,
                                          icon: Icons.directions_bus),
                                    ],
                                  ),
                                ),
                                // Data rows
                                ListView.separated(
                                  shrinkWrap: true,
                                  physics:
                                      const NeverScrollableScrollPhysics(),
                                  itemCount: filteredRoutes.length,
                                  separatorBuilder: (_, __) => Divider(
                                      height: 1,
                                      color: Colors.grey.shade100),
                                  itemBuilder: (context, index) {
                                    final route = filteredRoutes[index];
                                    final isEven = index % 2 == 0;
                                    return Container(
                                      color: isEven
                                          ? Colors.white
                                          : const Color(0xFFF9F9F9),
                                      child: Row(
                                        children: [
                                          _dataCell(
                                              route.pickupLocation,
                                              flex: 3),
                                          _dataCell(
                                              route.dropoffLocation,
                                              flex: 3),
                                          _dataCell(
                                              'Nu.${route.price4Seater}',
                                              flex: 2,
                                              highlight: true),
                                          _dataCell(
                                              'Nu.${route.price7Seater}',
                                              flex: 2,
                                              highlight: true),
                                          _dataCell(
                                              'Nu.${route.price8Seater}',
                                              flex: 2,
                                              highlight: true),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text,
      {required int flex, IconData? icon}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 13, horizontal: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, color: Colors.white38, size: 12),
              const SizedBox(height: 3),
            ],
            Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _dataCell(String text,
      {required int flex, bool highlight = false}) {
    return Expanded(
      flex: flex,
      child: Padding(
        padding:
            const EdgeInsets.symmetric(vertical: 11, horizontal: 4),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 11,
            color: highlight ? Colors.yellow[800] : Colors.black87,
            fontWeight:
                highlight ? FontWeight.w600 : FontWeight.w400,
          ),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}

// ── Section label ───────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: Colors.black87,
        letterSpacing: 0.1,
      ),
    );
  }
}