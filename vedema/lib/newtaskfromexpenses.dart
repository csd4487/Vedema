import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'user.dart';

class NewTaskFormExpenses extends StatefulWidget {
  final String taskName;
  final User user;

  const NewTaskFormExpenses({
    super.key,
    required this.taskName,
    required this.user,
  });

  @override
  State<NewTaskFormExpenses> createState() => _NewTaskFormExpensesState();
}

class _NewTaskFormExpensesState extends State<NewTaskFormExpenses> {
  final _formKey = GlobalKey<FormState>();
  final _taskController = TextEditingController();
  final _dateController = TextEditingController();
  final _costController = TextEditingController();
  final _synthesisController = TextEditingController();
  final _typeController = TextEditingController();
  final _npkController = TextEditingController();
  final _notesController = TextEditingController();

  DateTime? _selectedDate;
  List<dynamic> _fields = [];
  String? _selectedLocation;

  late String _taskKey;

  @override
  void initState() {
    super.initState();
    _fetchFields();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final loc = AppLocalizations.of(context)!;
    _taskKey = _normalizeTaskKey(widget.taskName, loc);

    if (_taskKey != 'other') {
      _taskController.text = widget.taskName;
    }
  }

  String _normalizeTaskKey(String taskName, AppLocalizations loc) {
    final normalized = taskName.trim().toLowerCase();

    if (normalized == 'fertilization' ||
        normalized == loc.fertilization.toLowerCase()) {
      return 'fertilization';
    }
    if (normalized == 'spraying' || normalized == loc.spraying.toLowerCase()) {
      return 'spraying';
    }
    if (normalized == 'irrigation' ||
        normalized == loc.irrigation.toLowerCase()) {
      return 'irrigation';
    }
    if (normalized == 'other' || normalized == loc.other.toLowerCase()) {
      return 'other';
    }

    return 'other';
  }

  bool get _hideSynthesisTypeNPK =>
      _taskKey == 'irrigation' || _taskKey == 'other';

  bool get _hideFieldSelection => _taskKey == 'other';

  Future<void> _fetchFields() async {
    try {
      final response = await http.post(
        Uri.parse('https://d1ee-94-65-160-226.ngrok-free.app/api/getFields'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _fields = data['fields'];
          if (_fields.isNotEmpty) {
            _selectedLocation = _fields.first['location'];
          }
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
    final loc = AppLocalizations.of(context)!;
    if (_formKey.currentState!.validate()) {
      try {
        final expenseData = {
          'task': _normalizeTaskKey(_taskController.text, loc),
          'date': _dateController.text,
          'cost': double.parse(_costController.text),
          'synthesis': _hideSynthesisTypeNPK ? '' : _synthesisController.text,
          'type': _hideSynthesisTypeNPK ? '' : _typeController.text,
          'npk': _hideSynthesisTypeNPK ? '' : _npkController.text,
          'notes': _notesController.text,
          'location': _hideFieldSelection ? null : _selectedLocation,
        };

        final response = await http.post(
          Uri.parse(
            'https://d1ee-94-65-160-226.ngrok-free.app/api/addExpenseSeparate',
          ),
          headers: {'Content-Type': 'application/json'},
          body: json.encode({
            'email': widget.user.email,
            'expenseData': expenseData,
          }),
        );

        if (response.statusCode == 200) {
          Navigator.pop(context);
        } else {
          final responseBody = json.decode(response.body);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${loc.error}: ${responseBody['message']}')),
          );
        }
      } catch (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.error}: ${error.toString()}')),
        );
      }
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    String hintText, {
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    String? validator,
  }) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF655B40), width: 2.0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 18, color: Color(0xFF655B40)),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            readOnly: readOnly,
            maxLines: maxLines,
            style: const TextStyle(color: Color(0xFF655B40)),
            decoration: InputDecoration(
              border: border,
              enabledBorder: border,
              focusedBorder: border,
              errorBorder: const OutlineInputBorder(
                borderSide: BorderSide(color: Colors.red, width: 2.0),
              ),
              hintText: hintText,
              hintStyle: const TextStyle(color: Color(0xFF655B40)),
            ),
            validator:
                (value) => value == null || value.isEmpty ? validator : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDateField(AppLocalizations loc) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF655B40), width: 2.0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.date,
            style: const TextStyle(fontSize: 18, color: Color(0xFF655B40)),
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => _pickDate(context),
            child: AbsorbPointer(
              child: TextFormField(
                controller: _dateController,
                style: const TextStyle(color: Color(0xFF655B40)),
                decoration: InputDecoration(
                  hintText: loc.selectDate,
                  hintStyle: const TextStyle(color: Color(0xFF655B40)),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
                validator:
                    (value) =>
                        value == null || value.isEmpty
                            ? loc.dateValidation
                            : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.newTask, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF655B40),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(15.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Image.asset('assets/logo.png', height: 85, width: 85),
                  Text(
                    loc.addNewTask,
                    style: const TextStyle(
                      fontSize: 23,
                      color: Color(0xFF655B40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),
              if (!_hideFieldSelection)
                Padding(
                  padding: const EdgeInsets.only(bottom: 13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loc.field,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
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
                          });
                        },
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF655B40),
                              width: 2.0,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF655B40),
                              width: 2.0,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFF655B40),
                              width: 2.0,
                            ),
                          ),
                          hintText: loc.selectField,
                          hintStyle: const TextStyle(color: Color(0xFF655B40)),
                        ),
                        validator:
                            (value) =>
                                value == null || value.isEmpty
                                    ? loc.selectField
                                    : null,
                      ),
                    ],
                  ),
                ),

              _buildTextField(
                loc.task,
                _taskController,
                loc.enterTaskName,
                readOnly: _taskKey != 'other',
                validator: loc.taskValidation,
              ),
              _buildDateField(loc),
              _buildTextField(
                loc.cost,
                _costController,
                loc.enterCost,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: loc.costValidation,
              ),
              if (!_hideSynthesisTypeNPK) ...[
                _buildTextField(
                  loc.synthesis,
                  _synthesisController,
                  loc.enterSynthesis,
                  validator: loc.synthesisValidation,
                ),
                _buildTextField(
                  loc.type,
                  _typeController,
                  loc.enterType,
                  validator: loc.typeValidation,
                ),
                _buildTextField(
                  loc.npk,
                  _npkController,
                  loc.enterNpk,
                  validator: loc.npkValidation,
                ),
              ],
              _buildTextField(
                loc.notes,
                _notesController,
                loc.enterNotes,
                maxLines: 3,
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
                      loc.addTask,
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 75),
            ],
          ),
        ),
      ),
    );
  }
}
