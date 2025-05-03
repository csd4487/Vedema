import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'separatefield.dart';

class NewTaskForm extends StatefulWidget {
  final String taskName;
  final User user;
  final Field field;

  const NewTaskForm({
    super.key,
    required this.taskName,
    required this.user,
    required this.field,
  });

  @override
  State<NewTaskForm> createState() => _NewTaskFormState();
}

class _NewTaskFormState extends State<NewTaskForm> {
  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  final _dateController = TextEditingController();
  final _costController = TextEditingController();
  final _synthesisController = TextEditingController();
  final _typeController = TextEditingController();
  final _npkController = TextEditingController();
  final _notesController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.taskName != 'Other') {
      _taskController.text = widget.taskName;
    }
  }

  Future<void> _submitForm() async {
    if (_formKey.currentState!.validate()) {
      try {
        final expenseData = {
          'task': _taskController.text,
          'date': _dateController.text,
          'cost': double.parse(_costController.text),
          'synthesis': _synthesisController.text,
          'type': _typeController.text,
          'npk': _npkController.text,
          'notes': _notesController.text,
          'location': widget.field.location,
        };

        print('Sending expense data: ${json.encode(expenseData)}');

        final response = await http.post(
          Uri.parse('http://192.168.1.2:5000/api/addExpense'),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': widget.user.email,
            'expenseData': expenseData,
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SeparateFieldScreen(
                    user: widget.user,
                    field: widget.field,
                  ),
            ),
          );
        } else {
          final responseBody = json.decode(response.body);
          print('Error: ${responseBody['message']}');
        }
      } on FormatException catch (e) {
        print('Data format error: ${e.message}');
      } catch (error) {
        print('Error: ${error.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF655B40), width: 2.0),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text("NewTask", style: TextStyle(color: Colors.white)),
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
                const Text(
                  'Add new task',
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
                    'Task',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _taskController,
                    readOnly: widget.taskName != 'Other',
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter the task name',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter task name' : null,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Date',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateController,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter the date',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Please enter date' : null,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Cost',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _costController,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter the cost',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Please enter cost' : null,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Synthesis',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _synthesisController,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter the synthesis',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) =>
                            value!.isEmpty ? 'Please enter synthesis' : null,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Type',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _typeController,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter the type',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Please enter type' : null,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'NPK',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _npkController,
                    style: const TextStyle(color: Color(0xFF655B40)),
                    decoration: InputDecoration(
                      border: border,
                      enabledBorder: border,
                      focusedBorder: border,
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter the NPK value',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Please enter NPK' : null,
                  ),
                  const SizedBox(height: 13),
                  const Text(
                    'Notes',
                    style: TextStyle(fontSize: 18, color: Color(0xFF655B40)),
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
                      errorBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.red, width: 2.0),
                      ),
                      hintText: 'Enter any notes',
                      hintStyle: TextStyle(color: Color(0xFF655B40)),
                    ),
                    validator:
                        (value) => value!.isEmpty ? 'Please enter notes' : null,
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
                          'Add Task',
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
    );
  }
}
