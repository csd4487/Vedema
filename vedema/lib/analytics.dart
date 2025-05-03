import 'package:flutter/material.dart';
import 'user.dart';
import 'fields.dart';
import 'userhomepage.dart';
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
    _loadFields();
  }

  void _loadFields() {
    setState(() {
      fieldOptions = widget.user.fields.map((f) => f.location).toList();
      fieldOptions.add('Other Expenses');
      selectedFields = List.from(fieldOptions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF655B40),
        automaticallyImplyLeading: false,
        title: const Text('Analytics', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon:
                _isListening
                    ? const Icon(Icons.mic, color: Colors.red, size: 30)
                    : const Icon(Icons.mic_none, color: Colors.white, size: 30),
            onPressed: () {
              _voiceHandler.toggleListening(context, widget.user);
            },
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
            const Text(
              'Filter Analytics',
              style: TextStyle(fontSize: 22, color: Color(0xFF655B40)),
            ),
            const SizedBox(height: 16),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Fields',
                  style: TextStyle(color: Color(0xFF655B40)),
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
                        ? 'Deselect All'
                        : 'Select All',
                    style: const TextStyle(color: Color(0xFF655B40)),
                  ),
                ),
              ],
            ),
            Wrap(
              spacing: 10,
              children:
                  fieldOptions.map((field) {
                    return FilterChip(
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
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),

            const Text('View Type', style: TextStyle(color: Color(0xFF655B40))),
            Wrap(
              spacing: 10,
              children:
                  ['Expenses', 'Profits', 'Both'].map((type) {
                    return ChoiceChip(
                      label: Text(type),
                      selected: viewType == type,
                      selectedColor: const Color(0xFF655B40),
                      labelStyle: TextStyle(
                        color:
                            viewType == type
                                ? Colors.white
                                : const Color(0xFF655B40),
                      ),
                      onSelected: (_) {
                        setState(() {
                          viewType = type;
                        });
                      },
                      backgroundColor: Colors.white,
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),

            const Text(
              'Select Tasks',
              style: TextStyle(color: Color(0xFF655B40)),
            ),
            Wrap(
              spacing: 10,
              children:
                  taskOptions.map((task) {
                    return FilterChip(
                      label: Text(task),
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
                    );
                  }).toList(),
            ),

            const SizedBox(height: 20),

            const Text(
              'Chart Type',
              style: TextStyle(color: Color(0xFF655B40)),
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
                    chartOptions.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(
                          type,
                          style: const TextStyle(color: Color(0xFF655B40)),
                        ),
                      );
                    }).toList(),
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
                  child: const Text('Cancel', style: TextStyle(fontSize: 16)),
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
                            ),
                      ),
                    );
                  },
                  child: const Text(
                    'Apply',
                    style: TextStyle(color: Colors.white, fontSize: 16),
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
            _buildNavItem(context, 'assets/field.png', 'Fields', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FieldsScreen(user: widget.user),
                ),
              );
            }),
            _buildNavItem(context, 'assets/expensesfooter.png', 'Expenses', () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => UserHomePage(user: widget.user),
                ),
              );
            }),
            _buildNavItem(context, 'assets/stats.png', 'Analytics', () {}),
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
