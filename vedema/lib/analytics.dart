import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'user.dart';
import 'fields.dart';
import 'expenses.dart';
import 'settings.dart';
import 'voicecommands.dart';
import 'analyticsdefault.dart';

class AnalyticsPage extends StatefulWidget {
  final User user;

  const AnalyticsPage({super.key, required this.user});

  @override
  State<AnalyticsPage> createState() => _AnalyticsPageState();
}

class _AnalyticsPageState extends State<AnalyticsPage> {
  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();
  bool _isListening = false;

  List<String> selectedFields = [];
  String viewType = 'Both';
  List<String> selectedTasks = [
    'Irrigation',
    'Fertilization',
    'Spraying',
    'Other',
  ];
  String chartType = 'Pie Chart';
  String? selectedPeriod;
  List<String> availablePeriods = [];

  final List<String> taskOptions = [
    'Irrigation',
    'Fertilization',
    'Spraying',
    'Other',
  ];
  final List<String> chartOptions = [
    'Pie Chart',
    'Bar Chart',
    'Line Chart',
    'Doughnut Chart',
  ];
  List<String> fieldOptions = [];

  @override
  void initState() {
    super.initState();
    _voiceHandler.listeningStream.listen((listening) {
      setState(() {
        _isListening = listening;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final loc = AppLocalizations.of(context)!;

    setState(() {
      fieldOptions = widget.user.fields.map((f) => f.location).toList();
      fieldOptions.add(loc.otherExpenses);
      selectedFields = List.from(fieldOptions);
    });

    _fetchAvailablePeriods();
  }

  void _loadFields() {
    setState(() {
      fieldOptions = widget.user.fields.map((f) => f.location).toList();
      fieldOptions.add(AppLocalizations.of(context)!.otherExpenses);
      selectedFields = List.from(fieldOptions);
    });
  }

  void _fetchAvailablePeriods() async {
    final url = Uri.parse(
      'https://94b6-79-131-87-183.ngrok-free.app/api/getAvailablePeriods',
    );
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.user.email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        availablePeriods = List<String>.from(data['periods']);
        if (availablePeriods.isNotEmpty) {
          selectedPeriod ??= availablePeriods.first;
        }
      });
    } else {
      print('Failed to fetch periods: ${response.body}');
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    final typeLabels = {
      'Expenses': loc.expenses,
      'Profits': loc.profits,
      'Both': loc.both,
    };

    final taskLabels = {
      'Irrigation': loc.irrigation,
      'Fertilization': loc.fertilization,
      'Spraying': loc.spraying,
      'Other': loc.other,
    };

    final chartLabels = {
      'Pie Chart': loc.pieChart,
      'Bar Chart': loc.barChart,
      'Line Chart': loc.lineChart,
      'Doughnut Chart': loc.doughnutChart,
    };

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF655B40),
        automaticallyImplyLeading: false,
        title: Text(loc.analytics, style: const TextStyle(color: Colors.white)),
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.filterAnalytics,
              style: const TextStyle(fontSize: 22, color: Color(0xFF655B40)),
            ),
            const SizedBox(height: 16),
            Text(
              loc.selectPeriod,
              style: const TextStyle(color: Color(0xFF655B40)),
            ),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              value: selectedPeriod,
              decoration: const InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items:
                  availablePeriods
                      .map(
                        (period) => DropdownMenuItem(
                          value: period,
                          child: Text(
                            period,
                            style: const TextStyle(color: Color(0xFF655B40)),
                          ),
                        ),
                      )
                      .toList(),
              onChanged: (value) => setState(() => selectedPeriod = value!),
            ),
            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  loc.selectFields,
                  style: const TextStyle(color: Color(0xFF655B40)),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      if (selectedFields.length == fieldOptions.length) {
                        selectedFields.clear();
                      } else {
                        selectedFields = List.from(fieldOptions);
                      }
                    });
                  },
                  child: Text(
                    selectedFields.length == fieldOptions.length
                        ? loc.deselectAll
                        : loc.selectAll,
                    style: const TextStyle(color: Color(0xFF655B40)),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children:
                  fieldOptions
                      .map(
                        (field) => FilterChip(
                          label: Text(field),
                          selected: selectedFields.contains(field),
                          selectedColor: const Color(0xFF655B40),
                          labelStyle: TextStyle(
                            color:
                                selectedFields.contains(field)
                                    ? Colors.white
                                    : const Color(0xFF655B40),
                          ),
                          backgroundColor: Colors.white,
                          onSelected: (bool selected) {
                            setState(() {
                              selected
                                  ? selectedFields.add(field)
                                  : selectedFields.remove(field);
                            });
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),

            Text(
              loc.viewType,
              style: const TextStyle(color: Color(0xFF655B40)),
            ),
            Wrap(
              spacing: 10,
              children:
                  typeLabels.entries.map((entry) {
                    return ChoiceChip(
                      label: Text(entry.value),
                      selected: viewType == entry.key,
                      selectedColor: const Color(0xFF655B40),
                      labelStyle: TextStyle(
                        color:
                            viewType == entry.key
                                ? Colors.white
                                : const Color(0xFF655B40),
                      ),
                      onSelected: (_) {
                        setState(() {
                          viewType = entry.key;
                        });
                      },
                      backgroundColor: Colors.white,
                    );
                  }).toList(),
            ),
            const SizedBox(height: 20),

            Text(
              loc.selectTasks,
              style: const TextStyle(color: Color(0xFF655B40)),
            ),
            Wrap(
              spacing: 10,
              children:
                  taskOptions
                      .map(
                        (task) => FilterChip(
                          label: Text(taskLabels[task] ?? task),
                          selected: selectedTasks.contains(task),
                          selectedColor: const Color(0xFF655B40),
                          labelStyle: TextStyle(
                            color:
                                selectedTasks.contains(task)
                                    ? Colors.white
                                    : const Color(0xFF655B40),
                          ),
                          backgroundColor: Colors.white,
                          onSelected: (bool selected) {
                            setState(() {
                              selected
                                  ? selectedTasks.add(task)
                                  : selectedTasks.remove(task);
                            });
                          },
                        ),
                      )
                      .toList(),
            ),
            const SizedBox(height: 20),

            Text(
              loc.chartType,
              style: const TextStyle(color: Color(0xFF655B40)),
            ),
            SizedBox(
              width: 260,
              child: DropdownButtonFormField<String>(
                value: chartType,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                dropdownColor: Colors.white,
                iconEnabledColor: const Color(0xFF655B40),
                items:
                    chartOptions
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              chartLabels[type] ?? type,
                              style: const TextStyle(color: Color(0xFF655B40)),
                            ),
                          ),
                        )
                        .toList(),
                onChanged: (value) {
                  setState(() {
                    chartType = value!;
                  });
                },
              ),
            ),
            const SizedBox(height: 30),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF655B40),
                    side: const BorderSide(color: Color(0xFF655B40)),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AnalyticsDefaultPage(
                              user: widget.user,
                              analyticsType: 'default',
                            ),
                      ),
                    );
                  },
                  child: Text(loc.cancel, style: const TextStyle(fontSize: 16)),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF655B40),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 12,
                    ),
                  ),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => AnalyticsDefaultPage(
                              user: widget.user,
                              analyticsType: 'filtered',
                              selectedPeriod: selectedPeriod,
                              selectedFields: selectedFields,
                              viewType: viewType,
                              selectedTasks: selectedTasks,
                              chartType: chartType,
                            ),
                      ),
                    );
                  },
                  child: Text(
                    loc.apply,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF655B40),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(context, 'assets/field.png', loc.fields, () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FieldsScreen(user: widget.user),
                ),
              );
            }),
            _buildNavItem(
              context,
              'assets/expensesfooter.png',
              loc.expenses,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllFieldsExpensesScreen(user: widget.user),
                  ),
                );
              },
            ),
            _buildNavItem(context, 'assets/stats.png', loc.analytics, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String iconPath,
    String label,
    VoidCallback onTap,
  ) {
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
