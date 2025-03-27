import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'signup.dart';
import 'user.dart';
import 'userhomepage.dart';

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
    if (_formKey.currentState!.validate()) {
      setState(() {
        _emailError = null;
        _passwordError = null;
      });
      try {
        final response = await http.post(
          Uri.parse('http://localhost:5000/api/signin'),
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
              builder: (context) => UserHomePage(user: loggedInUser),
            ),
          );
        } else {
          setState(() {
            _emailError = "Email and password do not match an existing user";
            _passwordError = "Email and password do not match an existing user";
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
    return Scaffold(
      appBar: AppBar(
        title: Text("Log In", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF655B40),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/logo.png', height: 85, width: 85),
                  const Text(
                    'Welcome back',
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 23, color: Color(0xFF655B40)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Email',
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      onChanged: (value) {
                        user.email = value;
                      },
                      validator:
                          (value) => value!.isEmpty ? 'Enter an email' : null,
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        hintText: 'Enter your email',
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                        errorText: _emailError,
                      ),
                    ),
                    const SizedBox(height: 13),
                    const Text(
                      'Password',
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      obscureText: !_isPasswordVisible,
                      onChanged: (value) {
                        user.password = value;
                      },
                      validator:
                          (value) => value!.isEmpty ? 'Enter a password' : null,
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        hintText: 'Enter your password',
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
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
                          child: const Text(
                            'Log In',
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "You don't have an account?",
                          style: TextStyle(
                            fontSize: 16,
                            color: Color(0xFF655B40),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SignUpScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            "Sign Up",
                            style: TextStyle(
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
      ),
    );
  }
}
