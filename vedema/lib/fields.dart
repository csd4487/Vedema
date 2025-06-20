import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'addnewfield.dart';
import 'expenses.dart';
import 'separatefield.dart';
import 'user.dart';
import 'settings.dart';
import 'voicecommands.dart';
import 'analyticsdefault.dart';
import 'editfieldform.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class FieldsScreen extends StatefulWidget {
  final User user;

  const FieldsScreen({super.key, required this.user});

  @override
  FieldsScreenState createState() => FieldsScreenState();
}

class FieldsScreenState extends State<FieldsScreen> {
  List<Field> _fields = [];
  bool _isLoading = true;

  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();
  bool _isListening = false;

  @override
  void initState() {
    super.initState();
    _loadFields();

    _voiceHandler.listeningStream.listen((listening) {
      setState(() => _isListening = listening);
    });
  }

  Future<void> _loadFields() async {
    try {
      final response = await http.post(
        Uri.parse('https://d1ee-94-65-160-226.ngrok-free.app/api/getFields'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> fieldsData = data['fields'];

        setState(() {
          _fields =
              fieldsData
                  .map(
                    (field) => Field(
                      field['location'],
                      field['size']?.toDouble() ?? 0.0,
                      field['oliveNo'] ?? 0,
                      field['cubics']?.toDouble() ?? 0.0,
                      field['price']?.toDouble() ?? 0.0,
                      field['species'] ?? '',
                    ),
                  )
                  .toList();
          _isLoading = false;
        });

        widget.user.fields = _fields;
      } else {
        throw Exception('Failed to load fields');
      }
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${AppLocalizations.of(context)!.errorLoadingFields}: $error',
          ),
        ),
      );
    }
  }

  Future<void> _confirmDeleteField(BuildContext context, Field field) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDeletion),
            content: Text(AppLocalizations.of(context)!.confirmDeleteField),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: Text(AppLocalizations.of(context)!.yes),
              ),
            ],
          ),
    );

    if (confirm == true) {
      _deleteField(field);
    }
  }

  Future<void> _deleteField(Field field) async {
    try {
      final response = await http.post(
        Uri.parse('https://d1ee-94-65-160-226.ngrok-free.app/api/deleteField'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': field.location,
          'size': field.size,
          'oliveNo': field.oliveNo,
          'cubics': field.cubics,
          'price': field.price,
          'species': field.species,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _fields.remove(field);
        });
      }
    } catch (e) {
      print("Delete error: $e");
    }
  }

  Future<void> _editField(Field field) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => UpdateFieldScreen(user: widget.user, field: field),
      ),
    );
    _loadFields();
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF655B40),
        title: Text(loc.fields, style: const TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon:
                _isListening
                    ? const Icon(Icons.mic, color: Colors.red, size: 30)
                    : const Icon(Icons.mic_none, color: Colors.white, size: 30),
            onPressed:
                () => _voiceHandler.toggleListening(context, widget.user),
          ),
          IconButton(
            icon: Image.asset('assets/menuicon.png', width: 35, height: 35),
            onPressed: () {
              showDialog(
                context: context,
                barrierColor: Colors.black38,
                builder: (_) => SettingsSidebar(user: widget.user),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 25),
                    _fields.isEmpty
                        ? Center(
                          child: Text(
                            loc.noFieldsHint,
                            style: const TextStyle(
                              fontSize: 18,
                              color: Color(0xFF655B40),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        )
                        : ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _fields.length,
                          itemBuilder: (context, index) {
                            final field = _fields[index];
                            return Column(
                              children: [
                                GestureDetector(
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder:
                                            (_) => SeparateFieldScreen(
                                              field: field,
                                              user: widget.user,
                                            ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(bottom: 25),
                                    padding: const EdgeInsets.all(15),
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          const Color(0xFF4A5C4A),
                                          const Color(
                                            0xFF655B40,
                                          ).withOpacity(0.7),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.25),
                                          blurRadius: 10,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Stack(
                                      children: [
                                        Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Row(
                                              children: [
                                                Image.asset(
                                                  'assets/location.png',
                                                  height: 30,
                                                  width: 30,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  field.location,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 22,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Image.asset(
                                                  'assets/size.png',
                                                  height: 30,
                                                  width: 30,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  '${field.size} m²',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              children: [
                                                Image.asset(
                                                  'assets/leaf.png',
                                                  height: 30,
                                                  width: 30,
                                                ),
                                                const SizedBox(width: 5),
                                                Text(
                                                  field.species,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 18,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                        Positioned(
                                          top: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: Image.asset(
                                              'assets/edit.png',
                                              width: 25,
                                              height: 25,
                                            ),
                                            onPressed: () => _editField(field),
                                          ),
                                        ),
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: IconButton(
                                            icon: Image.asset(
                                              'assets/delete.png',
                                              width: 25,
                                              height: 25,
                                            ),
                                            onPressed:
                                                () => _confirmDeleteField(
                                                  context,
                                                  field,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                if (index == _fields.length - 1)
                                  const SizedBox(height: 50),
                              ],
                            );
                          },
                        ),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewFieldScreen(user: widget.user),
            ),
          );
          _loadFields();
        },
        backgroundColor: const Color(0xFF655B40),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF655B40),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem('assets/field.png', loc.fields, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FieldsScreen(user: widget.user),
                ),
              );
            }),
            _buildNavItem('assets/expensesfooter.png', loc.expenses, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AllFieldsExpensesScreen(user: widget.user),
                ),
              );
            }),
            _buildNavItem('assets/stats.png', loc.analytics, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (_) => AnalyticsDefaultPage(
                        user: widget.user,
                        analyticsType: 'default',
                      ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(String iconPath, String label, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: Image.asset(iconPath, height: 35, width: 35),
          onPressed: onTap,
        ),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
