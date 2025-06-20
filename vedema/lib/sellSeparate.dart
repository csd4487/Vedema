import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class SellSeparateScreen extends StatefulWidget {
  final User user;
  final Field field;

  const SellSeparateScreen({
    super.key,
    required this.user,
    required this.field,
  });

  @override
  State<SellSeparateScreen> createState() => _SellSeparateScreenState();
}

class _SellSeparateScreenState extends State<SellSeparateScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _oilKgController = TextEditingController();
  final TextEditingController _pricePerKgController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
  bool _isLoading = false;
  double _availableOil = 0.0;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _fetchAvailableOil();
  }

  Future<void> _fetchAvailableOil() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://d1ee-94-65-160-226.ngrok-free.app/api/getAvailableOil',
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
          _availableOil = (data['availableOilKg'] ?? 0).toDouble();
        });
      } else {
        throw Exception('Failed to fetch available oil');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
      );
    }
  }

  Future<void> _submitSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final saleResponse = await http.post(
        Uri.parse('https://d1ee-94-65-160-226.ngrok-free.app/api/addSale'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
          'oilKgSold': double.parse(_oilKgController.text),
          'pricePerKg': double.parse(_pricePerKgController.text),
          'dateSold': _dateController.text,
        }),
      );

      if (saleResponse.statusCode == 200) {
        final removeResponse = await http.post(
          Uri.parse('https://d1ee-94-65-160-226.ngrok-free.app/api/removeOil'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'email': widget.user.email,
            'location': widget.field.location,
            'oilKgToRemove': double.parse(_oilKgController.text),
          }),
        );

        if (removeResponse.statusCode == 200) {
          await _fetchAvailableOil();
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppLocalizations.of(context)!.saleSuccess)),
          );
        } else {
          throw Exception('Failed to update oil inventory');
        }
      } else {
        final error = jsonDecode(saleResponse.body)['message'];
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
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.sale, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF655B40),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Image.asset('assets/logo.png', height: 85, width: 85),
                Text(
                  loc.makeSale,
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
                    '${loc.availableOil}: $_availableOil kg',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.oilToSell,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF655B40), width: 2.0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      controller: _oilKgController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.enterValue;
                        }
                        final doubleVal = double.tryParse(value);
                        if (doubleVal == null || doubleVal <= 0) {
                          return loc.enterValidNumber;
                        }
                        if (doubleVal > _availableOil) {
                          return loc.notEnoughOil;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    loc.pricePerKg,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF655B40), width: 2.0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      controller: _pricePerKgController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 10),
                        border: InputBorder.none,
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.enterValue;
                        }
                        final doubleVal = double.tryParse(value);
                        if (doubleVal == null || doubleVal <= 0) {
                          return loc.enterValidPrice;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    loc.date,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Color(0xFF655B40), width: 2.0),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: TextFormField(
                      controller: _dateController,
                      readOnly: true,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                        ),
                        border: InputBorder.none,
                        suffixIcon: const Icon(
                          Icons.calendar_today,
                          color: Color(0xFF655B40),
                        ),
                        hintText: loc.selectDate,
                      ),
                      onTap: _selectDate,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return loc.selectDate;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 30),
                  Center(
                    child:
                        _isLoading
                            ? const CircularProgressIndicator()
                            : ElevatedButton(
                              onPressed: _submitSale,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF655B40),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 40,
                                  vertical: 15,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(30),
                                ),
                              ),
                              child: Text(
                                loc.sell,
                                style: const TextStyle(fontSize: 18),
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
