import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
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

  DateTime? _selectedDate;

  late String _taskKey;

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

    if (normalized == 'irrigation' ||
        normalized == loc.irrigation.toLowerCase()) {
      return 'irrigation';
    }
    if (normalized == 'fertilization' ||
        normalized == loc.fertilization.toLowerCase()) {
      return 'fertilization';
    }
    if (normalized == 'spraying' || normalized == loc.spraying.toLowerCase()) {
      return 'spraying';
    }
    if (normalized == 'other' || normalized == loc.other.toLowerCase()) {
      return 'other';
    }
    return 'other';
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
    if (_formKey.currentState!.validate()) {
      try {
        final expenseData = {
          'task': _taskKey,
          'date': _dateController.text,
          'cost': double.parse(_costController.text),
          'synthesis': _hideSynthesisTypeNPK ? '' : _synthesisController.text,
          'type': _hideSynthesisTypeNPK ? '' : _typeController.text,
          'npk': _hideSynthesisTypeNPK ? '' : _npkController.text,
          'notes': _notesController.text,
          'location': widget.field.location,
        };

        final response = await http.post(
          Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/addExpense'),
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
      } catch (e) {
        print('Error: $e');
      }
    }
  }

  bool get _hideSynthesisTypeNPK {
    final key = _taskKey.trim().toLowerCase();
    return key == 'other' || key == 'irrigation';
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
          loc.newTaskTitle,
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
              _buildLabeledField(
                label: loc.taskLabel,
                controller: _taskController,
                hintText: loc.enterTaskHint,
                readOnly: _taskKey.toLowerCase() != 'other',
                validator:
                    (value) => value!.isEmpty ? loc.taskValidation : null,
              ),
              _buildDatePicker(loc),
              _buildLabeledField(
                label: loc.costLabel,
                controller: _costController,
                hintText: loc.enterCostHint,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator:
                    (value) => value!.isEmpty ? loc.costValidation : null,
              ),
              if (!_hideSynthesisTypeNPK) ...[
                _buildLabeledField(
                  label: loc.synthesisLabel,
                  controller: _synthesisController,
                  hintText: loc.enterSynthesisHint,
                ),
                _buildLabeledField(
                  label: loc.typeLabel,
                  controller: _typeController,
                  hintText: loc.enterTypeHint,
                ),
                _buildLabeledField(
                  label: loc.npk,
                  controller: _npkController,
                  hintText: loc.enterNpkHint,
                ),
              ],
              _buildLabeledField(
                label: loc.notesLabel,
                controller: _notesController,
                hintText: loc.enterNotesHint,
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
                      loc.addTaskButton,
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

  Widget _buildLabeledField({
    required String label,
    required TextEditingController controller,
    required String hintText,
    TextInputType keyboardType = TextInputType.text,
    bool readOnly = false,
    int maxLines = 1,
    String? Function(String?)? validator,
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
            validator: validator,
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(AppLocalizations loc) {
    final border = OutlineInputBorder(
      borderSide: const BorderSide(color: Color(0xFF655B40), width: 2.0),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            loc.dateLabel,
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
                  hintText: loc.selectDateHint,
                  hintStyle: const TextStyle(color: Color(0xFF655B40)),
                  border: border,
                  enabledBorder: border,
                  focusedBorder: border,
                ),
                validator:
                    (value) => value!.isEmpty ? loc.dateValidation : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
