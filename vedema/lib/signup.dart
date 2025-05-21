import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'signin.dart';
import 'user.dart';
import 'main.dart';
import 'package:logger/logger.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({super.key});
  @override
  SignUpScreenState createState() => SignUpScreenState();
}

final logger = Logger();
User user = User('', '', '', '', '');

class SignUpScreenState extends State<SignUpScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  final _formKey = GlobalKey<FormState>();
  String? _emailError;

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final response = await http.post(
          Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/signup'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'firstname': user.firstname,
            'lastname': user.lastname,
            'email': user.email,
            'password': user.password,
          }),
        );

        if (!mounted) return;

        if (response.statusCode == 201) {
          logger.i('User created successfully!');
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => SignInScreen()),
          );
        } else if (response.statusCode == 409) {
          setState(() {
            _emailError = AppLocalizations.of(context)!.emailInUse;
          });
        } else {
          logger.e('Error: ${response.body}');
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: ${response.body}')));
        }
      } catch (error) {
        if (!mounted) return;

        logger.e('Network error: $error');
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Network error: $error')));
      }
    } else {
      logger.w("Form is invalid!");
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.signUpTitle,
          style: TextStyle(color: Colors.white),
        ),
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
                  Text(
                    localizations.createAccount,
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
                    Text(
                      localizations.firstName,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                        hintText: localizations.enterFirstName,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                      ),
                      onChanged: (value) {
                        user.firstname = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    Text(
                      localizations.lastName,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                        hintText: localizations.enterLastName,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                      ),
                      onChanged: (value) {
                        user.lastname = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    Text(
                      localizations.email,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: const Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                        hintText: localizations.enterEmail,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                        errorText: _emailError,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _emailError = null;
                        });
                        user.email = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
                        } else if (!RegExp(
                          r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
                        ).hasMatch(value)) {
                          return localizations.invalidEmail;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    Text(
                      localizations.password,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      obscureText: !_isPasswordVisible,
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                        hintText: localizations.enterPassword,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
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
                      onChanged: (value) {
                        user.password = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 13),
                    Text(
                      localizations.confirmPassword,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      obscureText: !_isConfirmPasswordVisible,
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: Color(0xFF655B40),
                            width: 2.0,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                        hintText: localizations.reEnterPassword,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isConfirmPasswordVisible
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: const Color(0xFF655B40),
                          ),
                          onPressed: () {
                            setState(() {
                              _isConfirmPasswordVisible =
                                  !_isConfirmPasswordVisible;
                            });
                          },
                        ),
                      ),
                      onChanged: (value) {
                        user.confirmpassword = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
                        } else if (value != user.password) {
                          return localizations.passwordsDontMatch;
                        }
                        return null;
                      },
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
                            localizations.signup,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          localizations.alreadyHaveAccount,
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
                                builder: (context) => SignInScreen(),
                              ),
                            );
                          },
                          child: Text(
                            localizations.logIn,
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
