import 'package:flutter/material.dart';
import 'user.dart';
import 'main.dart';
import 'fields.dart';

class UserHomePage extends StatelessWidget {
  final User user;

  const UserHomePage({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Welcome, ${user.firstname}!"),
        backgroundColor: const Color(0xFF655B40),
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hello, ${user.firstname} ${user.lastname}!",
              style: TextStyle(fontSize: 24),
            ),
            Text("Email: ${user.email}", style: TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MyHomePage()),
                );
              },
              child: Text("Log Out"),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FieldsScreen(user: user),
                  ),
                );
              },
              child: Text("Fields"),
            ),
          ],
        ),
      ),
    );
  }
}
