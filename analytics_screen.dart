import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _totalScans = 0;
  int _scansToday = 0;
  String _tier = 'free';
  String _email = '';

  final Map<String, int> _scanLimits = {
    'free': 5,
    'pro': 50,
    'premium': 999,
  };

  @override
  void initState() {
    super.initState();
    _loadStats();
  }

  Future<void> _loadStats() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _scansToday = prefs.getInt('scansToday') ?? 0;
      _totalScans = prefs.getInt('totalScans') ?? 0;
      _tier = prefs.getString('tier') ?? 'free';
      _email = prefs.getString('email') ?? '';
    });
  }

  @override
  Widget build(BuildContext context) {
    final limit = _scanLimits[_tier] ?? 5;
    final progress = _scansToday / limit;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text('Analytics 📊'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User info card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF8B4513), Color(0xFFB5651D)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('👤 Account',
                      style: TextStyle(
                          color: Colors.white70, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(_email,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${_tier.toUpperCase()} PLAN',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Text('Usage Statistics',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513))),
            const SizedBox(height: 12),

            // Stats grid
            Row(
              children: [
                Expanded(
                  child: _statCard(
                      '📸', 'Scans Today',
                      '$_scansToday / $limit',
                      Colors.blue.shade600),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                      '🎯', 'Total Scans',
                      '$_totalScans',
                      Colors.green.shade600),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _statCard(
                      '⭐', 'Current Plan',
                      _tier.toUpperCase(),
                      const Color(0xFF8B4513)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _statCard(
                      '🔄', 'Scans Left Today',
                      '${limit - _scansToday}',
                      Colors.purple.shade600),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Daily usage progress bar
            const Text('Daily Usage',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513))),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF8B4513).withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('$_scansToday scans used',
                          style: const TextStyle(
                              fontWeight: FontWeight.w500)),
                      Text('$limit total',
                          style: const TextStyle(color: Colors.grey)),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: progress.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        progress > 0.8
                            ? Colors.red
                            : const Color(0xFF8B4513),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    progress >= 1.0
                        ? '⚠️ Daily limit reached — upgrade for more!'
                        : '✅ ${limit - _scansToday} scans remaining today',
                    style: TextStyle(
                        fontSize: 12,
                        color: progress >= 1.0
                            ? Colors.red
                            : Colors.green.shade700),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Plan features
            const Text('Your Plan Features',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513))),
            const SizedBox(height: 10),
            _planFeatures(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _statCard(
      String emoji, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color)),
          const SizedBox(height: 4),
          Text(label,
              style: const TextStyle(
                  color: Colors.grey, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _planFeatures() {
    final features = {
      'free': [
        '5 scans per day',
        'English captions only',
        '5 hashtags per scan',
        'Basic support',
      ],
      'pro': [
        '50 scans per day',
        'English + any Indian language',
        '12 hashtags per scan',
        'Scan history',
        'Priority support',
      ],
      'premium': [
        'Unlimited scans',
        'All Indian languages',
        '12 hashtags per scan',
        'Full analytics',
        'Dedicated support',
      ],
    };

    final currentFeatures = features[_tier] ?? features['free']!;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: const Color(0xFF8B4513).withOpacity(0.2)),
      ),
      child: Column(
        children: currentFeatures
            .map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle,
                          color: Color(0xFF8B4513), size: 18),
                      const SizedBox(width: 10),
                      Text(f,
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
