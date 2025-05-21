import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'user.dart';

class AddNewNotePage extends StatefulWidget {
  final User user;
  const AddNewNotePage({super.key, required this.user});

  @override
  State<AddNewNotePage> createState() => _AddNewNotePageState();
}

class _AddNewNotePageState extends State<AddNewNotePage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _noteController = TextEditingController();
  DateTime? selectedDate;
  bool sendEmail = false;

  final borderColor = const Color(0xFF655B40);
  late final OutlineInputBorder border;

  @override
  void initState() {
    super.initState();
    border = OutlineInputBorder(
      borderSide: BorderSide(color: borderColor, width: 2.0),
    );
  }

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      final formattedDate =
          '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}';

      final url = Uri.parse(
        'https://94b6-79-131-87-183.ngrok-free.app/api/addNote',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'user': {'email': widget.user.email},
          'note': {
            'text': _noteController.text,
            'date': formattedDate,
            'sendEmail': sendEmail,
          },
        }),
      );

      if (response.statusCode == 200 && mounted) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.newNote,
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: borderColor,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
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
                    localizations.addNewNote,
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
                      localizations.note,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _noteController,
                      maxLines: 3,
                      style: TextStyle(color: Color(0xFF655B40)),
                      decoration: InputDecoration(
                        hintText: localizations.enterNote,
                        hintStyle: TextStyle(color: Color(0xFF655B40)),
                        border: border,
                        enabledBorder: border,
                        focusedBorder: border,
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: Colors.red, width: 2.0),
                        ),
                      ),
                      validator:
                          (value) =>
                              value!.isEmpty
                                  ? localizations.pleaseEnterNote
                                  : null,
                    ),
                    const SizedBox(height: 20),
                    Text(
                      localizations.date,
                      style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _pickDate(context),
                      child: AbsorbPointer(
                        child: TextFormField(
                          controller: TextEditingController(
                            text:
                                selectedDate == null
                                    ? ''
                                    : '${selectedDate!.year.toString().padLeft(4, '0')}-${selectedDate!.month.toString().padLeft(2, '0')}-${selectedDate!.day.toString().padLeft(2, '0')}',
                          ),
                          validator:
                              (value) =>
                                  value!.isEmpty
                                      ? localizations.pleaseSelectDate
                                      : null,
                          style: TextStyle(color: Color(0xFF655B40)),
                          decoration: InputDecoration(
                            hintText: localizations.selectDate,
                            hintStyle: TextStyle(color: Color(0xFF655B40)),
                            border: border,
                            enabledBorder: border,
                            focusedBorder: border,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(
                          width: 24,
                          child: Checkbox(
                            value: sendEmail,
                            activeColor: borderColor,
                            onChanged: (bool? value) {
                              setState(() {
                                sendEmail = value ?? false;
                              });
                            },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            localizations.sendNoteInEmail,
                            style: TextStyle(
                              fontSize: 16,
                              color: Color(0xFF655B40),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 30),
                    Center(
                      child: SizedBox(
                        width: 250,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _submitForm,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: borderColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: Text(
                            localizations.addNewNoteButton,
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
