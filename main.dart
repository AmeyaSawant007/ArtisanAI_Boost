import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path_provider/path_provider.dart';
import 'auth_service.dart';
import 'login_screen.dart';
import 'subscription_screen.dart';
import 'history_screen.dart';
import 'analytics_screen.dart';


void main() => runApp(const ArtisanApp());


class ArtisanApp extends StatelessWidget {
  const ArtisanApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArtisanAI Boost',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF8B4513)),
        useMaterial3: true,
      ),
      home: const SplashScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}


class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}


class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    await Future.delayed(const Duration(seconds: 1));
    final auth = AuthService();
    final loggedIn = await auth.isLoggedIn();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => loggedIn ? const HomeScreen() : const LoginScreen(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF8B4513),
      body: Center(
        // ✅ FIXED: removed const from Center so Image.asset works
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 130, height: 130),
            const SizedBox(height: 16),
            const Text(
              'ArtisanAI Boost',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Empowering Indian Artisans',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
            const SizedBox(height: 40),
            const CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}


class _HomeScreenState extends State<HomeScreen> {
  static const String apiUrl =
      'https://YOUR_API_GATEWAY_URL/dev/generate';

  static const List<Map<String, String>> languages = [
    {'name': 'Hindi', 'flag': '🇮🇳'},
    {'name': 'Marathi', 'flag': '🟠'},
    {'name': 'Tamil', 'flag': '🟡'},
    {'name': 'Telugu', 'flag': '🔵'},
    {'name': 'Bengali', 'flag': '🟢'},
    {'name': 'Gujarati', 'flag': '🟣'},
    {'name': 'Kannada', 'flag': '🔴'},
    {'name': 'Malayalam', 'flag': '⚪'},
    {'name': 'Punjabi', 'flag': '🟤'},
    {'name': 'Urdu', 'flag': '🌙'},
  ];

  String _selectedLanguage = 'Hindi';
  File? _image;
  bool _loading = false;
  Map<String, dynamic>? _result;
  String? _error;
  String _userEmail = '';
  String _userTier = 'free';
  int _scansToday = 0;
  final _auth = AuthService();
  final ImagePicker _picker = ImagePicker();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final Map<String, int> _scanLimits = {
    'free': 5,
    'pro': 50,
    'premium': 999,
  };

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final user = await _auth.getCurrentUser();
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final lastDate = prefs.getString('lastScanDate') ?? '';
    if (lastDate != today) {
      await prefs.setInt('scansToday', 0);
      await prefs.setString('lastScanDate', today);
    }
    setState(() {
      _userEmail = user['email'] ?? '';
      _userTier = user['tier'] ?? 'free';
      _scansToday = prefs.getInt('scansToday') ?? 0;
    });
  }

  Future<void> _pickAndAnalyze(ImageSource source) async {
    final limit = _scanLimits[_userTier] ?? 5;
    if (_scansToday >= limit) {
      setState(() {
        _error =
            'Daily scan limit reached for ${_userTier.toUpperCase()} plan. Upgrade to scan more!';
      });
      return;
    }

    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 800,
      );
      if (picked == null) return;

      setState(() {
        _image = File(picked.path);
        _loading = true;
        _result = null;
        _error = null;
      });

      final bytes = await _image!.readAsBytes();
      final base64Image = base64Encode(bytes);

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'image': base64Image,
          'language': _selectedLanguage,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        final prefs = await SharedPreferences.getInstance();
        final newCount = _scansToday + 1;
        final totalScans = (prefs.getInt('totalScans') ?? 0) + 1;
        await prefs.setInt('scansToday', newCount);
        await prefs.setInt('totalScans', totalScans);

        if (_userTier == 'free' &&
            result['is_artisan'] == true &&
            result['rejection_type'] == null) {
          result['local_caption'] =
              '🔒 $_selectedLanguage captions available on Pro plan';
          final allHashtags = result['hashtags'] as List;
          result['hashtags'] = allHashtags.take(5).toList();
        }

        setState(() {
          _result = result;
          _scansToday = newCount;
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Error: ${response.body}';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
        _loading = false;
      });
    }
  }

  void _shareContent() {
    if (_result == null ||
        _result!['is_artisan'] != true ||
        _result!['rejection_type'] != null) return;
    final productType = _result!['product_type'] ?? 'Handmade Product';
    final english = _result!['english'] ?? '';
    final localCaption = _result!['local_caption'] ?? '';
    final localLanguage = _result!['local_language'] ?? _selectedLanguage;
    final hashtags = (_result!['hashtags'] as List).join(' ');

    final shareText = '''
🎨 $productType

🇬🇧 $english

$localLanguage: $localCaption

$hashtags

✨ Generated by ArtisanAI Boost — Empowering Indian Artisans
''';
    Share.share(shareText);
  }

  Future<void> _downloadCaption() async {
    if (_result == null ||
        _result!['is_artisan'] != true ||
        _result!['rejection_type'] != null) return;

    final productType = _result!['product_type'] ?? 'Product';
    final english = _result!['english'] ?? '';
    final localCaption = _result!['local_caption'] ?? '';
    final localLanguage = _result!['local_language'] ?? _selectedLanguage;
    final hashtags = (_result!['hashtags'] as List).join(' ');
    final whatsappLink = _result!['whatsapp_link'] ?? '';

    final content = '''
ArtisanAI Boost — Generated Content
=====================================
Product: $productType
Date: ${DateTime.now().toLocal().toString().substring(0, 16)}

ENGLISH CAPTION:
$english

$localLanguage CAPTION:
$localCaption

HASHTAGS:
$hashtags

WHATSAPP SHARE LINK:
$whatsappLink
=====================================
Generated by ArtisanAI Boost 🎨
''';
    try {
      final dir = await getExternalStorageDirectory();
      final file = File(
          '${dir!.path}/ArtisanAI_${productType.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.txt');
      await file.writeAsString(content);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Saved to ${file.path}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error saving: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _signOut() async {
    await _auth.signOut(_userEmail);
    if (mounted) {
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  Widget _buildProfileDrawer() {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              color: const Color(0xFF8B4513),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.account_circle,
                      color: Colors.white, size: 64),
                  const SizedBox(height: 12),
                  Text(
                    _userEmail,
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      _userTier.toUpperCase(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.star, color: Color(0xFF8B4513)),
              title: const Text('Subscription Plans'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const SubscriptionScreen()),
                ).then((_) => _loadUser());
              },
            ),
            ListTile(
              leading: const Icon(Icons.history, color: Color(0xFF8B4513)),
              title: const Text('Scan History'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()));
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.analytics, color: Color(0xFF8B4513)),
              title: const Text('Analytics'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const AnalyticsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title:
                  const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () {
                Navigator.pop(context);
                _signOut();
              },
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '🎨 ArtisanAI Boost\nEmpowering Indian Artisans',
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: Colors.grey.shade500, fontSize: 11),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) return const SizedBox.shrink();

    final bool isArtisan = _result!['is_artisan'] ?? false;
    final String? rejectionType = _result!['rejection_type'];

    if (!isArtisan && rejectionType == 'not_artisan') {
      return _rejectionCard(
        emoji: '❌',
        title: 'Not a Handmade Product',
        englishMsg: _result!['message_en'] ??
            'This does not appear to be a handmade product image.',
        localMsg: _result!['message_local'] ??
            'यह एक हस्तनिर्मित उत्पाद की तस्वीर नहीं लगती।',
        cardColor: Colors.red.shade50,
        borderColor: Colors.red.shade300,
        titleColor: Colors.red.shade700,
        textColor: Colors.red.shade600,
        iconData: Icons.cancel_outlined,
      );
    }

    if (isArtisan && rejectionType == 'coming_soon') {
      return _rejectionCard(
        emoji: '✨',
        title: 'Coming in Future Update!',
        englishMsg: _result!['message_en'] ??
            'This looks like a beautiful handmade product! This craft will be supported in a future update.',
        localMsg: _result!['message_local'] ??
            'यह एक सुंदर हस्तनिर्मित उत्पाद लगता है!',
        cardColor: Colors.amber.shade50,
        borderColor: Colors.amber.shade400,
        titleColor: Colors.amber.shade800,
        textColor: Colors.amber.shade700,
        iconData: Icons.rocket_launch_outlined,
      );
    }

    if (isArtisan && rejectionType == null) {
      return Column(
        children: [
          _resultCard('🛍️ Product Detected', _result!['product_type'] ?? ''),
          if (_result!['gi_tag'] == true)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.verified,
                      color: Colors.green.shade600, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'GI Tag Certified — Geographical Indication Protected',
                    style: TextStyle(
                        color: Colors.green.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ],
              ),
            ),
          _resultCard('🏷️ Rekognition Labels',
              (_result!['labels'] as List).join(' • ')),
          _resultCard('🇬🇧 English Caption', _result!['english']),
          _resultCard(
            '🌐 ${_result!['local_language'] ?? _selectedLanguage} Caption',
            _result!['local_caption'] ?? '',
          ),
          _resultCard(
              '📢 Hashtags', (_result!['hashtags'] as List).join('  ')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _shareContent,
                  icon: const Icon(Icons.share),
                  label: const Text('Share Post'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () {
                  final hashtags =
                      (_result!['hashtags'] as List).join(' ');
                  Share.share(hashtags);
                },
                icon: const Icon(Icons.tag),
                label: const Text('Tags'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade600,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final link = _result?['whatsapp_link'] ?? '';
                    if (link.isNotEmpty) {
                      final uri = Uri.parse(link);
                      if (await canLaunchUrl(uri)) {
                        await launchUrl(uri,
                            mode: LaunchMode.externalApplication);
                      }
                    } else {
                      _shareContent();
                    }
                  },
                  icon: const Icon(Icons.chat),
                  label: const Text('WhatsApp'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _downloadCaption,
                  icon: const Icon(Icons.download),
                  label: const Text('Download'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.purple.shade600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          if (_userTier == 'free') ...[
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const SubscriptionScreen()),
              ).then((_) => _loadUser()),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF8B4513),
                    Colors.amber.shade700
                  ]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '⭐ Upgrade for full captions + all hashtags',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      );
    }

    return const SizedBox.shrink();
  }

  Widget _rejectionCard({
    required String emoji,
    required String title,
    required String englishMsg,
    required String localMsg,
    required Color cardColor,
    required Color borderColor,
    required Color titleColor,
    required Color textColor,
    required IconData iconData,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 2),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(iconData, color: titleColor, size: 20),
              const SizedBox(width: 6),
              Text(title,
                  style: TextStyle(
                      color: titleColor,
                      fontSize: 16,
                      fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          Text(englishMsg,
              textAlign: TextAlign.center,
              style:
                  TextStyle(color: textColor, fontSize: 14, height: 1.6)),
          const Divider(height: 24),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(localMsg,
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: textColor, fontSize: 14, height: 1.6)),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => setState(() {
              _result = null;
              _image = null;
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Try Another Image'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B4513),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final limit = _scanLimits[_userTier] ?? 5;

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/logo.png', height: 30, width: 30),
            const SizedBox(width: 8),
            const Text('ArtisanAI Boost',
                style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold)),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.white),
            onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildProfileDrawer(),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Scan counter banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFF8B4513).withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF8B4513).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Plan: ${_userTier.toUpperCase()}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF8B4513))),
                  Text('Scans: $_scansToday / $limit',
                      style: const TextStyle(
                          color: Color(0xFF8B4513), fontSize: 13)),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Language Selector
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                  horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: const Color(0xFF8B4513).withOpacity(0.4)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.language,
                      color: Color(0xFF8B4513), size: 20),
                  const SizedBox(width: 8),
                  const Text('Caption Language:',
                      style: TextStyle(
                          color: Color(0xFF8B4513),
                          fontWeight: FontWeight.w600)),
                  const Spacer(),
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedLanguage,
                      icon: const Icon(Icons.arrow_drop_down,
                          color: Color(0xFF8B4513)),
                      items: languages.map((lang) {
                        return DropdownMenuItem<String>(
                          value: lang['name'],
                          child: Text('${lang['flag']} ${lang['name']}',
                              style: const TextStyle(fontSize: 14)),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() => _selectedLanguage = value!);
                      },
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            // Image Display
            Container(
              height: 230,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(
                    color: const Color(0xFF8B4513), width: 2),
                borderRadius: BorderRadius.circular(12),
                color: Colors.white,
              ),
              child: _image != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.file(_image!, fit: BoxFit.cover),
                    )
                  : const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined,
                              size: 60, color: Colors.brown),
                          SizedBox(height: 8),
                          Text('Tap below to scan your product 📸',
                              style: TextStyle(
                                  color: Colors.grey, fontSize: 15)),
                        ],
                      ),
                    ),
            ),

            const SizedBox(height: 14),

            // Camera / Gallery Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pickAndAnalyze(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('Camera'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _pickAndAnalyze(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('Gallery'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B4513),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Loading
            if (_loading)
              Column(
                children: [
                  const CircularProgressIndicator(
                      color: Color(0xFF8B4513)),
                  const SizedBox(height: 12),
                  Text(
                    'Generating captions in $_selectedLanguage... ✨',
                    style: const TextStyle(
                        color: Color(0xFF8B4513),
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),

            // Error
            if (_error != null)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline,
                        color: Colors.red.shade400),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_error!,
                          style:
                              TextStyle(color: Colors.red.shade700)),
                    ),
                    if (_error!.contains('Upgrade'))
                      TextButton(
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  const SubscriptionScreen()),
                        ).then((_) => _loadUser()),
                        child: const Text('Upgrade',
                            style: TextStyle(
                                color: Color(0xFF8B4513))),
                      ),
                  ],
                ),
              ),

            // Results
            _buildResult(),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _resultCard(String title, String content) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: const Color(0xFF8B4513).withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.brown.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                  fontSize: 14)),
          const SizedBox(height: 8),
          Text(content,
              style: const TextStyle(fontSize: 14, height: 1.5)),
        ],
      ),
    );
  }
}
