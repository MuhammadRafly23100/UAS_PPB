import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'db/db_helper.dart';
import 'session_manager.dart';

class OrderHistoryPage extends StatefulWidget {
  const OrderHistoryPage({super.key});

  @override
  State<OrderHistoryPage> createState() => _OrderHistoryPageState();
}

class _OrderHistoryPageState extends State<OrderHistoryPage> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> _allTransactions = [];
  List<Map<String, dynamic>> _filteredTransactions = [];
  bool _isLoading = true;
  final NumberFormat currencyFormat = NumberFormat("#,###", "id_ID");
  int? _currentUserId;
  late TabController _tabController;

  final List<String> _tabs = ['Semua', 'Diproses', 'Selesai', 'Dibatalkan'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_filterTransactions);
    _loadOrderHistory();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAndLoadOrderHistory();
  }

  Future<void> _checkAndLoadOrderHistory() async {
    final newUserId = await SessionManager.getUserId();
    if (newUserId != _currentUserId) {
      _currentUserId = newUserId;
      _loadOrderHistory();
    }
  }

  // Parser tanggal yang aman untuk format SQLite "YYYY-MM-DD HH:MM:SS"
  String _formatTanggal(dynamic v) {
    final s = v?.toString() ?? '';
    if (s.isEmpty) return '-';
    final iso = s.contains(' ') ? s.replaceFirst(' ', 'T') : s; // jadi ISO-ish
    DateTime? dt;
    try {
      dt = DateTime.parse(iso);
    } catch (_) {
      dt = DateTime.tryParse(s);
    }
    dt ??= DateTime.now();
    return DateFormat('dd MMM yyyy', 'id_ID').format(dt);
  }

  Future<void> _loadOrderHistory() async {
    setState(() {
      _isLoading = true;
      _allTransactions = [];
    });

    DBHelper? dbHelper; // Declare dbHelper as nullable
    try {
      // ➜ HANYA pakai userId; jangan kunci pakai email
      final userId = await SessionManager.getUserId();
      if (userId == null) {
        if (mounted) {
          setState(() {
            _allTransactions = [];
            _filterTransactions();
          });
        }
        return;
      }

      dbHelper = DBHelper();
      debugPrint('DEBUG: Attempting to get transactions for userId: $userId');
      final transactions = await dbHelper.getTransactionsByUserId(userId);
      debugPrint('DEBUG: Retrieved ${transactions.length} transactions.');

      // Ambil detail setiap transaksi + pastikan status tidak null
      for (var t in transactions) {
        final details = await dbHelper.getTransactionDetails(t['transaksi_id']);
        t['details'] = details;
        t['status'] = t['status'] ?? 'Diproses';
        debugPrint('DEBUG: Transaction ${t['transaksi_id']} has ${details.length} details.');
      }

      if (mounted) {
        setState(() {
          _allTransactions = transactions;
          _filterTransactions();
        });
      }
    } catch (e) {
      debugPrint('ERROR: Error loading order history: $e');
      if (mounted) {
        setState(() {
          _allTransactions = [];
          _filterTransactions();
        });
      }
    } finally {
      if (dbHelper != null) {
        await dbHelper.close(); // Explicitly close the database
        debugPrint('DEBUG: DBHelper instance closed in _loadOrderHistory.');
      }
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _filterTransactions() {
    final selectedTab = _tabs[_tabController.index];
    debugPrint('DEBUG: _filterTransactions called for tab: "$selectedTab"');
    debugPrint('DEBUG: _allTransactions content before filtering: $_allTransactions'); // Added debug print
    setState(() {
      if (selectedTab == 'Semua') {
        _filteredTransactions = _allTransactions;
      } else {
        _filteredTransactions = _allTransactions
            .where((transaction) => transaction['status'] == selectedTab)
            .toList();
      }
      debugPrint('DEBUG: Filtered transactions for tab "$selectedTab": ${_filteredTransactions.length} items');
      if (_filteredTransactions.isEmpty && selectedTab != 'Semua') {
        debugPrint('DEBUG: No transactions found for status "$selectedTab".');
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_filterTransactions);
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat Pesanan'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrderHistory,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: _tabs.map((tab) {
                if (_filteredTransactions.isEmpty) {
                  return const Center(child: Text('Anda belum memiliki riwayat pesanan untuk status ini.'));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _filteredTransactions.length,
                  itemBuilder: (context, index) {
                    final transaction = _filteredTransactions[index];
                    final List<Map<String, dynamic>> details = transaction['details'] ?? [];
                    final String firstProductName =
                        details.isNotEmpty ? details[0]['nama_produk'] : 'Produk Tidak Diketahui';
                    final int otherItemsCount = details.length > 1 ? details.length - 1 : 0;
                    final String status = transaction['status'] ?? 'Unknown';

                    return Card(
                      margin: const EdgeInsets.only(bottom: 16.0),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _formatTanggal(transaction['tanggal']),
                                  style: const TextStyle(fontSize: 14, color: Colors.grey),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: status == 'Selesai'
                                        ? Colors.green.shade100
                                        : status == 'Diproses'
                                            ? Colors.orange.shade100
                                            : Colors.red.shade100,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status,
                                    style: TextStyle(
                                      color: status == 'Selesai'
                                          ? Colors.green.shade800
                                          : status == 'Diproses'
                                              ? Colors.orange.shade800
                                              : Colors.red.shade800,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Builder(builder: (context) {
                                  final imagePath = details.isNotEmpty ? details[0]['foto_produk'] : null;
                                  if (imagePath != null) {
                                    try {
                                      if (File(imagePath).existsSync()) {
                                        return Container(
                                          width: 80,
                                          height: 80,
                                          margin: const EdgeInsets.only(right: 10),
                                          decoration: BoxDecoration(
                                            borderRadius: BorderRadius.circular(8),
                                            image: DecorationImage(
                                              image: FileImage(File(imagePath)),
                                              fit: BoxFit.cover,
                                            ),
                                          ),
                                        );
                                      }
                                    } catch (_) {}
                                  }
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(right: 10),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.grey[300],
                                    ),
                                    child: const Icon(Icons.image_not_supported, color: Colors.grey),
                                  );
                                }),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        firstProductName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (otherItemsCount > 0)
                                        Text(
                                          '+ $otherItemsCount item lainnya',
                                          style: const TextStyle(color: Colors.grey, fontSize: 14),
                                        ),
                                      const SizedBox(height: 10),
                                      const Text('Total Harga', style: TextStyle(fontSize: 14, color: Colors.grey)),
                                      Text(
                                        'Rp ${currencyFormat.format(transaction['total'])}',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () {
                                  // TODO: Arahkan ke halaman detail pesanan jika ada
                                  debugPrint('Lihat Detail: ${transaction['transaksi_id']}');
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue.shade50,
                                  foregroundColor: Colors.blue.shade700,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                child: const Text('Lihat Detail >'),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              }).toList(),
            ),
    );
  }
}
