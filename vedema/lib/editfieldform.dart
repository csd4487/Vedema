import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user.dart';
import 'fields.dart';
import 'package:logger/logger.dart';

class UpdateFieldScreen extends StatefulWidget {
  final User user;
  final Field field;

  const UpdateFieldScreen({super.key, required this.user, required this.field});

  @override
  _UpdateFieldScreenState createState() => _UpdateFieldScreenState();
}

class _UpdateFieldScreenState extends State<UpdateFieldScreen> {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final Logger logger = Logger();

  late String _location;
  late double _size;
  late int _oliveNo;
  late double _cubics;
  late double _price;
  late String _species;

  @override
  void initState() {
    super.initState();
    _location = widget.field.location;
    _size = widget.field.size;
    _oliveNo = widget.field.oliveNo;
    _cubics = widget.field.cubics;
    _price = widget.field.price;
    _species = widget.field.species;
  }

  Future<void> _submitForm() async {
    if (formKey.currentState?.validate() ?? false) {
      try {
        final updatedField = {
          'location': _location,
          'size': _size,
          'oliveNo': _oliveNo,
          'cubics': _cubics,
          'price': _price,
          'species': _species,
        };

        final requestData = {'email': widget.user.email, 'field': updatedField};

        final response = await http.post(
          Uri.parse(
            'https://d1ee-94-65-160-226.ngrok-free.app/api/updateField',
          ),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(requestData),
        );

        if (!mounted) return;

        if (response.statusCode == 200) {
          logger.i("Field updated successfully");
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => FieldsScreen(user: widget.user),
            ),
          );
        } else {
          logger.e("Error updating field: ${response.statusCode}");
        }
      } catch (error) {
        logger.e("Error updating field: $error");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.updateField),
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
                  const SizedBox(width: 8),
                  Text(
                    loc.updateYourField,
                    textAlign: TextAlign.left,
                    style: const TextStyle(
                      fontSize: 23,
                      color: Color(0xFF655B40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              Form(
                key: formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildLabel(loc.location),
                    _buildTextField(
                      initialValue: _location,
                      hint: loc.locationUneditable,
                      enabled: false,
                      onChanged: (_) {},
                    ),
                    _buildLabel(loc.fieldSize),
                    _buildTextField(
                      initialValue: _size.toString(),
                      hint: loc.enterFieldSize,
                      suffix: 'm²',
                      isNumber: true,
                      onChanged: (val) => _size = double.tryParse(val) ?? 0.0,
                    ),
                    _buildLabel(loc.oliveCount),
                    _buildTextField(
                      initialValue: _oliveNo.toString(),
                      hint: loc.enterOliveCount,
                      isNumber: true,
                      onChanged: (val) => _oliveNo = int.tryParse(val) ?? 0,
                    ),
                    _buildLabel(loc.species),
                    _buildTextField(
                      initialValue: _species,
                      hint: loc.enterSpecies,
                      onChanged: (val) => _species = val,
                    ),
                    _buildLabel(loc.cubics),
                    _buildTextField(
                      initialValue: _cubics.toString(),
                      hint: loc.enterCubics,
                      isNumber: true,
                      onChanged: (val) => _cubics = double.tryParse(val) ?? 0.0,
                    ),
                    _buildLabel(loc.price),
                    _buildTextField(
                      initialValue: _price.toString(),
                      hint: loc.enterPrice,
                      suffix: '€',
                      isNumber: true,
                      onChanged: (val) => _price = double.tryParse(val) ?? 0.0,
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
                          ),
                          child: Text(
                            loc.updateField,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
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

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 13, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(fontSize: 18, color: Color(0xFF655B40)),
      ),
    );
  }

  Widget _buildTextField({
    required String initialValue,
    required String hint,
    required Function(String) onChanged,
    bool isNumber = false,
    String? suffix,
    bool enabled = true,
  }) {
    final loc = AppLocalizations.of(context)!;

    return TextFormField(
      initialValue: initialValue,
      enabled: enabled,
      keyboardType:
          isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : null,
      style: const TextStyle(color: Color(0xFF655B40)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: enabled ? const Color(0xFF655B40) : Colors.grey,
        ),
        suffixText: suffix,
        fillColor: enabled ? null : const Color(0xFFF0F0F0),
        filled: !enabled,
        border: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF655B40), width: 2.0),
        ),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF655B40), width: 2.0),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Color(0xFF655B40), width: 2.0),
        ),
        errorBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.red, width: 2.0),
        ),
      ),
      onChanged: onChanged,
      validator: (value) {
        if (enabled && (value == null || value.isEmpty)) {
          return loc.fieldRequired;
        }
        return null;
      },
    );
  }
}
