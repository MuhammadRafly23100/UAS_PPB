import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'logout.dart';
import 'edit_profile.dart';
import 'models/user.dart';
import 'db/db_helper.dart'; // Import DBHelper to get transaction counts
import 'order_history_page.dart'; // Import OrderHistoryPage


class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? userData;
  File? _avatarImage;
  int _pendingShippingCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUserDataAndCounts();
  }

  Future<void> _loadUserDataAndCounts() async {
    final prefs = await SharedPreferences.getInstance();
    String? emailPref = prefs.getString("email");
    if (emailPref == null) return;

    final User _user = User();
    final data = await _user.getUserByEmail(emailPref);
    final pendingCount = await _user.getPendingShippingCount(); // Call from _user instance

    setState(() {
      userData = data;
      _avatarImage = (userData?['avatar'] != null &&
                userData!['avatar'].toString().isNotEmpty)
          ? File(userData!['avatar'])
          : null;
      _pendingShippingCount = pendingCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: userData == null
          ? const Center(child: CircularProgressIndicator())
          : buildProfileUI(),
    );
  }

  Widget buildProfileUI() {
    return SafeArea(
      child: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _avatarImage != null
                          ? FileImage(_avatarImage!)
                          : null,
                      child: _avatarImage == null
                          ? const Icon(Icons.person, size: 50, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      userData?["nama"] ?? "-",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 30),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Status Pesanan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2EDE5),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildStatusBox('Riwayat Pesanan', _pendingShippingCount, onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const OrderHistoryPage()),
                        );
                      }),
                      _buildStatusBox('Pembatalan', 0), // Placeholder
                      _buildStatusBox('Pengembalian', 0), // Placeholder
                      _buildStatusBox('Rating', 4.7, isRating: true),
                    ],
                  ),
                ),
                const SizedBox(height: 30),
                fieldLabel("Name"),
                fieldBox(userData?["nama"] ?? ""),
                const SizedBox(height: 30),
                fieldLabel("Email"),
                fieldBox(userData?["email"] ?? ""),
                const SizedBox(height: 30),
                fieldLabel("Phone"),
                fieldBox(userData?["no_telp"] ?? ""),
                const SizedBox(height: 30),
                fieldLabel("Address"),
                fieldBox(userData?["alamat"] ?? ""),
                const SizedBox(height: 30),
                SizedBox(
                  width: 160,
                  height: 35,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8D6E63),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final updatedData = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              EditProfilePage(userData: userData!),
                        ),
                      );

                      if (updatedData != null) {
                        setState(() {
                          userData = updatedData;
                          _avatarImage = updatedData['avatar'] != null
                              ? File(updatedData['avatar'])
                              : null;
                        });
                      }
                    },
                    child: const Text(
                      "Edit Profile",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 50),
              ],
            ),
          ),
          Positioned(
            top: 10,
            right: 10,
            child: IconButton(
              icon: const Icon(Icons.logout, color: Colors.black, size: 28),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LogoutPage()),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBox(String title, dynamic value, {bool isRating = false, VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        height: 80,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF8D6E63)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            isRating
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 20),
                      Text(
                        value.toString(),
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                : Text(
                    value.toString(),
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
            const SizedBox(height: 5),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget fieldLabel(String text) => Align(
        alignment: Alignment.centerLeft,
        child: Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
      );

  Widget fieldBox(String value) => TextField(
        readOnly: true,
        decoration: InputDecoration(
          filled: true,
          fillColor: const Color(0xFFF2EDE5),
          hintText: value,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide.none,
          ),
        ),
      );
}
