import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AddNewProfitOtherPage extends StatefulWidget {
  final User user;

  const AddNewProfitOtherPage({super.key, required this.user});

  @override
  State<AddNewProfitOtherPage> createState() => _AddNewProfitOtherPageState();
}

class _AddNewProfitOtherPageState extends State<AddNewProfitOtherPage> {
  final _formKey = GlobalKey<FormState>();
  final _typeController = TextEditingController();
  final _dateController = TextEditingController();
  final _incomeController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime? _selectedDate;

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text =
            '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final otherProfitData = {
        'type': _typeController.text,
        'date': _dateController.text,
        'profitNo': double.parse(_incomeController.text),
        'notes': _notesController.text,
      };

      try {
        final response = await http.post(
          Uri.parse(
            'https://d1ee-94-65-160-226.ngrok-free.app/api/addOtherProfit',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': widget.user.email,
            'otherProfitData': otherProfitData,
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context);
        } else {
          final responseBody = json.decode(response.body);
          print('Error: ${responseBody['message']}');
        }
      } on FormatException catch (e) {
        print('Data format error: ${e.message}');
      } catch (e) {
        print('Error submitting other profit: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final border = OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF655B40), width: 2.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          loc.newOtherProfit,
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
                  loc.addNewProfit,
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
                    loc.typeLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _typeController,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      hintText: loc.enterTypeHint,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? loc.typeValidation : null,
                  ),
                  const SizedBox(height: 13),
                  Text(
                    loc.dateLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickDate(context),
                    child: AbsorbPointer(
                      child: TextFormField(
                        controller: _dateController,
                        style: const TextStyle(color: Color(0xFF655B40)),
                        decoration: InputDecoration(
                          border: border,
                          enabledBorder: border,
                          focusedBorder: border,
                          hintText: loc.selectDateHint,
                          hintStyle: const TextStyle(color: Color(0xFF655B40)),
                        ),
                        validator:
                            (value) =>
                                value!.isEmpty
                                    ? loc.selectDateValidation
                                    : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 13),
                  Text(
                    loc.incomeLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _incomeController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      hintText: loc.enterIncomeHint,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? loc.incomeValidation : null,
                  ),
                  const SizedBox(height: 13),
                  Text(
                    loc.notesLabel,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _notesController,
                    maxLines: 3,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      hintText: loc.enterNotesHint,
                      hintStyle: const TextStyle(color: Color(0xFF655B40)),
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
                          loc.addProfitButton,
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
    );
  }
}
