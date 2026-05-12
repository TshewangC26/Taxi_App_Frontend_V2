import 'package:flutter/material.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F4F6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Icon(Icons.arrow_back_ios_new,
                color: Colors.grey[700], size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('About Us',
            style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.w700,
                fontSize: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Hero card ─────────────────────────────────
            Container(
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.yellow[800],
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(children: [
                Image.asset(
                  'assets/images/taxi_logo.png',
                  width: 80, height: 80,
                  fit: BoxFit.contain,
                ),
                const SizedBox(height: 14),
                const Text('Easy Ride',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5)),
                const SizedBox(height: 6),
                Text(
                  'Bhutan\'s trusted online taxi service',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13),
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text('Version 1.0.0',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600)),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Our Mission ───────────────────────────────
            _SectionLabel(
                icon: Icons.rocket_launch_rounded,
                label: 'Our Mission'),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Text(
                'Easy Ride was built with one simple mission — to make transportation in Bhutan more accessible, affordable, and reliable for everyone. We connect passengers with professional, verified drivers to ensure every journey is safe and comfortable.',
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    height: 1.65),
              ),
            ),

            const SizedBox(height: 24),

            // ── Our Team ──────────────────────────────────
            _SectionLabel(
                icon: Icons.groups_rounded, label: 'Our Team'),
            const SizedBox(height: 14),

            // University project note
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.yellow[200]!),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.school_rounded,
                      color: Colors.yellow[800], size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Easy Ride was developed as a university final-year project at the Jigme Namgyel Engineering College (JNEC), Samdrupjongkhar, Bhutan.',
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.yellow[900],
                          height: 1.5),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Developers
            _TeamCard(
              role: 'Frontend Developer',
              name: 'Chogyal Wangdi',
              description:
                  'Responsible for designing and building the mobile app interface, user experience flows, and all Flutter screens.',
              icon: Icons.phone_android_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
            ),
            const SizedBox(height: 10),
            _TeamCard(
              role: 'Backend Developer',
              name: 'Tshewang Choden',
              description:
                  'Responsible for building the server-side APIs, database design, and integrating Railway.',
              icon: Icons.dns_rounded,
              iconBg: const Color(0xFFE8F5E9),
              iconColor: const Color(0xFF2E7D32),
            ),

            const SizedBox(height: 20),

            // Supervisors
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.yellow[800],
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.supervisor_account_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              const Text('Project Supervisors',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ]),

            const SizedBox(height: 14),

            _SupervisorCard(
              name: 'Madam Sonam Wangmo',
              role: 'Primary Supervisor',
              icon: Icons.person_rounded,
              iconBg: const Color(0xFFEDE7F6),
              iconColor: const Color(0xFF5E35B1),
            ),
            const SizedBox(height: 10),
            _SupervisorCard(
              name: 'Miss Deki Lhazom',
              role: 'Co-Supervisor',
              icon: Icons.person_rounded,
              iconBg: const Color(0xFFFFF3E0),
              iconColor: const Color(0xFFE65100),
            ),

            const SizedBox(height: 28),

            // ── Footer ────────────────────────────────────
            Center(
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.local_taxi,
                        size: 14, color: Colors.yellow[800]),
                    const SizedBox(width: 6),
                    Text('Easy Ride',
                        style: TextStyle(
                            color: Colors.yellow[800],
                            fontSize: 13,
                            fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 4),
                Text('© 2025 Easy Ride. All rights reserved.',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 11)),
                Text('Product of JNEC',
                    style: TextStyle(
                        color: Colors.grey[400], fontSize: 11)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Widgets ────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
            color: Colors.yellow[800],
            borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: Colors.white, size: 15),
      ),
      const SizedBox(width: 10),
      Text(label,
          style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black87)),
    ]);
  }
}

class _TeamCard extends StatelessWidget {
  final String role;
  final String name;
  final String description;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _TeamCard({
    required this.role,
    required this.name,
    required this.description,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(13)),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: iconBg,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(role,
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: iconColor)),
                ),
                const SizedBox(height: 6),
                Text(name,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87)),
                const SizedBox(height: 5),
                Text(description,
                    style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[500],
                        height: 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SupervisorCard extends StatelessWidget {
  final String name;
  final String role;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;

  const _SupervisorCard({
    required this.name,
    required this.role,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
              color: iconBg, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
              const SizedBox(height: 2),
              Text(role,
                  style: TextStyle(
                      fontSize: 12, color: Colors.grey[500])),
            ],
          ),
        ),
      ]),
    );
  }
}