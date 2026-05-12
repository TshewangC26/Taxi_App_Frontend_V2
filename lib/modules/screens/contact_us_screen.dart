import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

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
        title: const Text('Contact Us',
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
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.headset_mic_rounded,
                      color: Colors.white, size: 32),
                ),
                const SizedBox(height: 14),
                const Text('We\'re here to help',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Text(
                  'Reach out to us anytime — our support team\nis available 7 days a week.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                      height: 1.5),
                ),
              ]),
            ),

            const SizedBox(height: 24),

            // ── Section label ─────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.yellow[800],
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.contact_phone_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              const Text('Get in Touch',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ]),

            const SizedBox(height: 14),

            // ── Email tile only ───────────────────────────
            _ContactTile(
              icon: Icons.mail_rounded,
              iconBg: const Color(0xFFE3F2FD),
              iconColor: const Color(0xFF1565C0),
              label: 'Email',
              value: 'easyride6202@gmail.com',
              subtitle: 'We reply within 24 hours',
              onTap: () => launchUrl(
                  Uri.parse('mailto:easyride6202@gmail.com')),
            ),

            const SizedBox(height: 28),

            // ── Support hours ─────────────────────────────
            Row(children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                    color: Colors.yellow[800],
                    borderRadius: BorderRadius.circular(9)),
                child: const Icon(Icons.access_time_rounded,
                    color: Colors.white, size: 15),
              ),
              const SizedBox(width: 10),
              const Text('Support Hours',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87)),
            ]),

            const SizedBox(height: 14),

            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade100),
              ),
              child: Column(children: [
                _HoursRow(day: 'Monday – Friday',
                    hours: '8:00 AM – 8:00 PM'),
                Divider(height: 16, color: Colors.grey.shade100),
                _HoursRow(day: 'Saturday',
                    hours: '9:00 AM – 6:00 PM'),
                Divider(height: 16, color: Colors.grey.shade100),
                _HoursRow(day: 'Sunday',
                    hours: '10:00 AM – 4:00 PM'),
              ]),
            ),

            const SizedBox(height: 28),

            // ── Footer ────────────────────────────────────
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.local_taxi,
                      size: 12, color: Colors.grey[400]),
                  const SizedBox(width: 5),
                  Text('Easy Ride — Online Taxi Service',
                      style: TextStyle(
                          color: Colors.grey[400], fontSize: 11)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _ContactTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
        ),
        child: Row(children: [
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: iconColor, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey[400],
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87)),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey[500])),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded,
              color: Colors.grey[300], size: 20),
        ]),
      ),
    );
  }
}

class _HoursRow extends StatelessWidget {
  final String day;
  final String hours;
  const _HoursRow({required this.day, required this.hours});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(day,
            style: TextStyle(color: Colors.grey[500], fontSize: 13)),
        Text(hours,
            style: const TextStyle(
                color: Colors.black87,
                fontSize: 13,
                fontWeight: FontWeight.w600)),
      ],
    );
  }
}