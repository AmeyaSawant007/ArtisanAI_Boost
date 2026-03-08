import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  String _currentTier = 'free';

  @override
  void initState() {
    super.initState();
    _loadTier();
  }

  Future<void> _loadTier() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() { _currentTier = prefs.getString('tier') ?? 'free'; });
  }

  Future<void> _selectTier(String tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('tier', tier);
    setState(() { _currentTier = tier; });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Switched to ${tier.toUpperCase()} plan! ✅'),
          backgroundColor: const Color(0xFF8B4513),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text('Subscription Plans'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 10),
            const Text('Choose Your Plan',
                style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF8B4513))),
            const SizedBox(height: 6),
            const Text('Upgrade to unlock more features',
                style: TextStyle(color: Colors.grey)),
            const SizedBox(height: 24),

            _planCard(
              tier: 'free',
              title: 'Free',
              price: '₹0/month',
              color: Colors.grey.shade700,
              features: [
                '5 AI scans per day',
                'English captions only',
                'Basic hashtags (5 tags)',
                'Standard support',
              ],
            ),

            const SizedBox(height: 16),

            _planCard(
              tier: 'pro',
              title: 'Pro 🚀',
              price: '₹199/month',
              color: const Color(0xFF8B4513),
              features: [
                '50 AI scans per day',
                'English + Hindi captions',
                'Full hashtag set (12 tags)',
                'Product type detection',
                'Scan history',
                'Priority support',
              ],
              highlighted: true,
            ),

            const SizedBox(height: 16),

            _planCard(
              tier: 'premium',
              title: 'Premium 👑',
              price: '₹499/month',
              color: Colors.amber.shade700,
              features: [
                'Unlimited AI scans',
                'English + Hindi captions',
                'Trending hashtags',
                'Full scan history',
                'Analytics dashboard',
                'Priority AI processing',
                'Dedicated support',
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _planCard({
    required String tier,
    required String title,
    required String price,
    required Color color,
    required List<String> features,
    bool highlighted = false,
  }) {
    final isActive = _currentTier == tier;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isActive ? color : Colors.grey.shade200,
          width: isActive ? 2.5 : 1,
        ),
        boxShadow: highlighted
            ? [BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 12,
                offset: const Offset(0, 4))]
            : [],
      ),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: color)),
                    Text(price,
                        style: TextStyle(
                            fontSize: 14, color: color.withOpacity(0.8))),
                  ],
                ),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text('ACTIVE',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...features.map((f) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(f, style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                )),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: isActive ? null : () => _selectTier(tier),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isActive ? Colors.grey.shade300 : color,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    child: Text(isActive ? 'Current Plan' : 'Select Plan',
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
