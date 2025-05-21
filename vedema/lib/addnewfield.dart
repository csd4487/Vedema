import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'package:logger/logger.dart';
import 'fields.dart';

class AddNewFieldScreen extends StatefulWidget {
  final User user;

  const AddNewFieldScreen({super.key, required this.user});

  @override
  _AddNewFieldScreenState createState() => _AddNewFieldScreenState();
}

class _AddNewFieldScreenState extends State<AddNewFieldScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Logger logger = Logger();
  String _location = '';
  double _size = 0.0;
  int _oliveNo = 0;
  double _cubics = 0.0;
  double _price = 0.0;
  String _species = '';

  Future<void> _submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      try {
        final Map<String, dynamic> requestData = {
          'email': widget.user.email,
          'location': _location,
          'size': _size,
          'oliveNo': _oliveNo,
          'cubics': _cubics,
          'price': _price,
          'species': _species,
        };

        final response = await http.post(
          Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/addField'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          logger.i(AppLocalizations.of(context)!.fieldAddedSuccess);

          widget.user.fields.add(
            Field(_location, _size, _oliveNo, _cubics, _price, _species),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FieldsScreen(user: widget.user),
            ),
          );
        } else {
          logger.e("Error adding field: ${response.statusCode}");
        }
      } catch (error) {
        logger.e("Error adding field: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.newField),
        backgroundColor: const Color(0xFF655B40),
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: const TextStyle(color: Colors.white, fontSize: 20),
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
                    localizations.addYourField,
                    textAlign: TextAlign.left,
                    style: TextStyle(fontSize: 23, color: Color(0xFF655B40)),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      localizations.location,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
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
                        hintText: localizations.enterLocation,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _location = value;
                        });
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
                      localizations.fieldSize,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        hintText: localizations.enterFieldSize,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                        suffixText: localizations.squareMeters,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _size = double.tryParse(value) ?? 0.0;
                        });
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
                      localizations.oliveCount,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      keyboardType: TextInputType.number,
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
                        hintText: localizations.enterOliveCount,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _oliveNo = int.tryParse(value) ?? 0;
                        });
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
                      localizations.species,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
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
                        hintText: localizations.enterSpecies,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _species = value;
                        });
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
                      localizations.cubics,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        hintText: localizations.enterCubics,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _cubics = double.tryParse(value) ?? 0.0;
                        });
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
                      localizations.price,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      style: TextStyle(color: Color(0xFF655B40)),
                      keyboardType: TextInputType.numberWithOptions(
                        decimal: true,
                      ),
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
                        hintText: localizations.enterPrice,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                        suffixText: localizations.euroSymbol,
                      ),
                      onChanged: (value) {
                        setState(() {
                          _price = double.tryParse(value) ?? 0.0;
                        });
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return localizations.fieldRequired;
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
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                          child: Text(
                            localizations.addField,
                            style: TextStyle(color: Colors.white, fontSize: 18),
                          ),
                        ),
                      ),
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
