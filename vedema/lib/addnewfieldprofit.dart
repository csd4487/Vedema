import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddNewFieldGrind extends StatefulWidget {
  final User user;
  final Field field;
  final String mode;

  const AddNewFieldGrind({
    super.key,
    required this.user,
    required this.field,
    required this.mode,
  });

  @override
  State<AddNewFieldGrind> createState() => _AddNewFieldGrindState();
}

class _AddNewFieldGrindState extends State<AddNewFieldGrind> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sacksController = TextEditingController();
  final TextEditingController _oilKgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int _availableSacks = 0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    if (widget.mode == 'grind') {
      _fetchAvailableSacks();
    }
  }

  Future<void> _fetchAvailableSacks() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://d1ee-94-65-160-226.ngrok-free.app/api/getAvailableSacks',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _availableSacks = data['availableSacks'];
        });
      } else {
        throw Exception('Failed to fetch available sacks');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  Future<void> _submitGrind() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://d1ee-94-65-160-226.ngrok-free.app/api/grindSacks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
          'sacksToGrind': int.parse(_sacksController.text),
          'oilKg': double.parse(_oilKgController.text),
          'date': _dateController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sacksGrindSuccess),
          ),
        );
      } else {
        final error = jsonDecode(response.body)['message'];
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _submitAddSacks() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final url = Uri.parse(
        'https://d1ee-94-65-160-226.ngrok-free.app/api/addFieldSacks',
      );
      final requestBody = {
        'email': widget.user.email,
        'sackData': {
          'location': widget.field.location,
          'sacks': int.parse(_sacksController.text),
          'date': _dateController.text,
        },
      };

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sacksAddSuccess),
          ),
        );
      } else {
        final error = jsonDecode(response.body)['message'];
        throw Exception(error);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            "${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}";
      });
    }
  }

  OutlineInputBorder _inputBorder() {
    return OutlineInputBorder(
      borderSide: BorderSide(color: const Color(0xFF655B40), width: 2.0),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final isGrindMode = widget.mode == 'grind';

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGrindMode ? loc.grind : loc.addSacks,
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF655B40),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                Text(
                  isGrindMode ? loc.grindSacks : loc.addSacks,
                  style: const TextStyle(
                    fontSize: 23,
                    color: Color(0xFF655B40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            if (isGrindMode)
              Text(
                '${loc.availableSacks}: $_availableSacks',
                style: const TextStyle(fontSize: 18, color: Color(0xFF655B40)),
              ),
            const SizedBox(height: 15),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGrindMode
                        ? loc.numberOfSacksToGrind
                        : loc.numberOfSacksToAdd,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _sacksController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(),
                      focusedBorder: _inputBorder(),
                      hintText: loc.enterValidNumber,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) return loc.enterValue;
                      final intVal = int.tryParse(value);
                      if (intVal == null || intVal <= 0)
                        return loc.enterValidPositiveNumber;
                      if (isGrindMode && intVal > _availableSacks)
                        return loc.sacksExceedAvailable;
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  Text(
                    loc.date,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateController,
                    readOnly: true,
                    decoration: InputDecoration(
                      border: _inputBorder(),
                      enabledBorder: _inputBorder(),
                      focusedBorder: _inputBorder(),
                      hintText: loc.selectDateHint,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
                      suffixIcon: const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF655B40),
                      ),
                    ),
                    onTap: _selectDate,
                    validator: (value) {
                      if (value == null || value.isEmpty)
                        return loc.selectDateValidation;
                      return null;
                    },
                  ),
                  if (isGrindMode) ...[
                    const SizedBox(height: 15),
                    Text(
                      loc.oilKg,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF655B40),
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _oilKgController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        border: _inputBorder(),
                        enabledBorder: _inputBorder(),
                        focusedBorder: _inputBorder(),
                        hintText: loc.enterKgOfOil,
                        hintStyle: const TextStyle(color: Color(0xFF655B40)),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty)
                          return loc.enterValue;
                        final doubleVal = double.tryParse(value);
                        if (doubleVal == null || doubleVal <= 0)
                          return loc.enterValidPositiveNumber;
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 20),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : Center(
                        child: SizedBox(
                          width: 250,
                          height: 50,
                          child: ElevatedButton(
                            onPressed:
                                isGrindMode ? _submitGrind : _submitAddSacks,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF655B40),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: Text(
                              isGrindMode ? loc.grind : loc.addSacks,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
