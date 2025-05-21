import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddNewProfit2 extends StatefulWidget {
  final User user;
  final String mode;

  const AddNewProfit2({super.key, required this.user, required this.mode});

  @override
  State<AddNewProfit2> createState() => _AddNewProfit2State();
}

class _AddNewProfit2State extends State<AddNewProfit2> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _sacksController = TextEditingController();
  final TextEditingController _oilKgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  int _availableSacks = 0;
  DateTime? _selectedDate;
  List<dynamic> _fields = [];
  String? _selectedLocation;

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  Future<void> _fetchFields() async {
    try {
      final response = await http.post(
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/getFields'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fields = data['fields'];
        });
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadFields);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  Future<void> _fetchAvailableSacks() async {
    if (_selectedLocation == null) return;

    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getAvailableSacks',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': _selectedLocation,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _availableSacks = data['availableSacks'];
        });
      } else {
        throw Exception(
          AppLocalizations.of(context)!.failedToFetchAvailableSacks,
        );
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
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/grindSacks'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': _selectedLocation,
          'sacksToGrind': int.parse(_sacksController.text),
          'oilKg': double.parse(_oilKgController.text),
          'date': _dateController.text,
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context)!.sacksGroundSuccessfully,
            ),
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
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/addFieldSacks',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'sackData': {
            'location': _selectedLocation,
            'sacks': int.parse(_sacksController.text),
            'date': _dateController.text,
          },
        }),
      );

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.sacksAddedSuccessfully),
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

  @override
  Widget build(BuildContext context) {
    final isGrindMode = widget.mode == 'grind';
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          isGrindMode ? localizations.grind : localizations.addSacks,
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
                  isGrindMode
                      ? localizations.grindSacks
                      : localizations.addSacks,
                  style: const TextStyle(
                    fontSize: 23,
                    color: Color(0xFF655B40),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  localizations.selectField,
                  style: const TextStyle(
                    fontSize: 18,
                    color: Color(0xFF655B40),
                  ),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    border: OutlineInputBorder(),
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
                  ),
                  value: _selectedLocation,
                  items:
                      _fields.map<DropdownMenuItem<String>>((field) {
                        return DropdownMenuItem<String>(
                          value: field['location'],
                          child: Text(field['location']),
                        );
                      }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedLocation = value;
                      _availableSacks = 0;
                    });
                    if (isGrindMode) _fetchAvailableSacks();
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return localizations.pleaseSelectAField;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                if (isGrindMode && _selectedLocation != null)
                  Text(
                    '${localizations.availableSacks}: $_availableSacks',
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 15),
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isGrindMode
                        ? localizations.numberOfSacksToGrind
                        : localizations.numberOfSacksToAdd,
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
                      border: OutlineInputBorder(),
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
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.enterNumberOfSacks;
                      }
                      final intValue = int.tryParse(value);
                      if (intValue == null || intValue <= 0) {
                        return localizations.enterValidPositiveNumber;
                      }
                      if (isGrindMode && intValue > _availableSacks) {
                        return localizations.sacksExceedAvailable;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 15),
                  if (isGrindMode)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.kgOfOilObtained,
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
                            border: OutlineInputBorder(),
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
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return localizations.enterKgOfOil;
                            }
                            final doubleValue = double.tryParse(value);
                            if (doubleValue == null || doubleValue <= 0) {
                              return localizations.enterValidPositiveNumber;
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  Text(
                    localizations.date,
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
                      hintText: localizations.selectDate,
                      suffixIcon: const Icon(Icons.calendar_today),
                      border: OutlineInputBorder(),
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
                    ),
                    onTap: _selectDate,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return localizations.pleaseSelectADate;
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 25),
                  Center(
                    child: ElevatedButton(
                      onPressed:
                          _isLoading
                              ? null
                              : isGrindMode
                              ? _submitGrind
                              : _submitAddSacks,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF655B40),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 90,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child:
                          _isLoading
                              ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                              : Text(
                                isGrindMode
                                    ? localizations.grind
                                    : localizations.addSacks,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
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
