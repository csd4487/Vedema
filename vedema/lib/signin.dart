import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'signup.dart';
import 'user.dart';
import 'fields.dart';

class SignInScreen extends StatefulWidget {
  const SignInScreen({super.key});
  @override
  SignInScreenState createState() => SignInScreenState();
}

class SignInScreenState extends State<SignInScreen> {
  bool _isPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  User user = User('', '', '', '', '');
  String? _emailError;
  String? _passwordError;

  Future<void> _submitForm() async {
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      setState(() {
        _emailError = null;
        _passwordError = null;
      });
      try {
        final response = await http.post(
          Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/signin'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'email': user.email, 'password': user.password}),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          final loggedInUser = User(
            responseData['user']['firstname'],
            responseData['user']['lastname'],
            responseData['user']['email'],
            '',
            '',
          );

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FieldsScreen(user: loggedInUser),
            ),
          );
        } else {
          setState(() {
            _emailError = loc.invalidEmail;
            _passwordError = loc.invalidEmail;
          });
        }
      } catch (error) {
        if (!mounted) return;
        setState(() {
          _emailError = "Network error. Please try again.";
          _passwordError = "Network error. Please try again.";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final borderColor = const Color(0xFF655B40);
    final border = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 2.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.login, style: const TextStyle(color: Colors.white)),
        backgroundColor: borderColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/logo.png', height: 85, width: 85),
                const SizedBox(width: 10),
                Text(
                  loc.login,
                  style: const TextStyle(
                    fontSize: 23,
                    color: Color(0xFF655B40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    loc.email,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    onChanged: (value) => user.email = value,
                    validator:
                        (value) => value!.isEmpty ? loc.fieldRequired : null,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: border,
                      disabledBorder: border,
                      focusedErrorBorder: border,
                      hintText: loc.enterEmail,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
                      errorText: _emailError,
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    loc.password,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    obscureText: !_isPasswordVisible,
                    onChanged: (value) => user.password = value,
                    validator:
                        (value) => value!.isEmpty ? loc.fieldRequired : null,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: border,
                      disabledBorder: border,
                      focusedErrorBorder: border,
                      hintText: loc.enterPassword,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
                      errorText: _passwordError,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: const Color(0xFF655B40),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),
                  Center(
                    child: SizedBox(
                      width: 250,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF655B40),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        child: Text(
                          loc.login,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        loc.alreadyHaveAccountnot,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SignUpScreen(),
                            ),
                          );
                        },
                        child: Text(
                          loc.signup,
                          style: const TextStyle(
                            fontSize: 16,
                            color: Color(0xFF655B40),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 75),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
