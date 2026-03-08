import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  static const String historyApiUrl =
      'https://ifre636395.execute-api.us-east-1.amazonaws.com/dev/history';

  List<Map<String, dynamic>> _history = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final email = prefs.getString('email') ?? '';

      final response = await http.get(
        Uri.parse('$historyApiUrl?email=${Uri.encodeComponent(email)}'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _history = List<Map<String, dynamic>>.from(data['items'] ?? []);
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load history';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F0),
      appBar: AppBar(
        backgroundColor: const Color(0xFF8B4513),
        foregroundColor: Colors.white,
        title: const Text('Scan History 📋'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              setState(() { _loading = true; _error = null; });
              _loadHistory();
            },
          )
        ],
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF8B4513)))
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.red, size: 48),
                      const SizedBox(height: 12),
                      Text(_error!,
                          style: const TextStyle(color: Colors.red)),
                    ],
                  ),
                )
              : _history.isEmpty
                  ? const Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text('📭', style: TextStyle(fontSize: 60)),
                          SizedBox(height: 12),
                          Text('No scans yet!',
                              style: TextStyle(
                                  fontSize: 18, color: Colors.grey)),
                          SizedBox(height: 6),
                          Text('Go scan your first product 🎨',
                              style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _history.length,
                      itemBuilder: (context, index) {
                        final item = _history[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: const Color(0xFF8B4513)
                                    .withOpacity(0.2)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.brown.withOpacity(0.06),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: ExpansionTile(
                            tilePadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B4513)
                                    .withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text('🛍️',
                                  style: TextStyle(fontSize: 20)),
                            ),
                            title: Text(
                              item['product_type'] ?? 'Unknown Product',
                              style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8B4513)),
                            ),
                            subtitle: Text(
                              item['timestamp']?.substring(0, 10) ?? '',
                              style: const TextStyle(
                                  color: Colors.grey, fontSize: 12),
                            ),
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    _historyField('Labels',
                                        item['labels'] ?? ''),
                                    _historyField('English',
                                        item['english'] ?? ''),
                                    _historyField('Local Caption',
                                        item['local_caption'] ?? item['hindi'] ?? ''),
                                    _historyField('Hashtags',
                                        item['hashtags'] ?? ''),
                                  ],
                                ),
                              )
                            ],
                          ),
                        );
                      },
                    ),
    );
  }

  Widget _historyField(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF8B4513),
                  fontSize: 12)),
          const SizedBox(height: 4),
          Text(value,
              style: const TextStyle(fontSize: 13, height: 1.4)),
          const Divider(),
        ],
      ),
    );
  }
}
