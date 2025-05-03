import 'package:flutter/material.dart';
import 'notes.dart';
import 'main.dart';
import 'user.dart';

class SettingsSidebar extends StatelessWidget {
  final User user;

  const SettingsSidebar({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Align(
      alignment: Alignment.topRight,
      child: Container(
        width: screenSize.width * 0.4,
        height: screenSize.height * 0.68,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF5A5139), Color(0xFF655B40), Color(0xFFEFEDE7)],
            stops: [0.0, 0.8, 1.0],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(20),
            bottomLeft: Radius.circular(20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(-6, 0),
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topRight,
              child: IconButton(
                icon: Image.asset('assets/menuicon.png', width: 32, height: 32),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
            const SizedBox(height: 20),
            _settingsButton("Notes", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => NotesPage(user: user)),
              );
            }),
            _divider(),
            _settingsButton("Language", null),
            _divider(),
            _settingsButton("Logout", () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyHomePage()),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _settingsButton(String label, VoidCallback? onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
          padding: EdgeInsets.zero,
          alignment: Alignment.centerLeft,
        ),
        child: Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _divider() {
    return const Divider(color: Colors.white54, thickness: 0.8, height: 1);
  }
}
