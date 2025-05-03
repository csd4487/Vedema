import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart';
import 'user.dart';
import 'fields.dart';
import 'userhomepage.dart';
import 'settings.dart';
import 'voicecommands.dart';
import 'analytics.dart';

class AnalyticsDefaultPage extends StatefulWidget {
  final User user;
  final String analyticsType;

  const AnalyticsDefaultPage({
    super.key,
    required this.user,
    this.analyticsType = 'default',
  });

  @override
  State<AnalyticsDefaultPage> createState() => _AnalyticsDefaultPageState();
}

class _AnalyticsDefaultPageState extends State<AnalyticsDefaultPage> {
  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();
  bool _isListening = false;
  bool _isLoading = true;

  Map<String, double> _expenseData = {};
  Map<String, double> _profitData = {};
  String _fieldWithMostExpenses = 'No fields';
  String _fieldWithMostProfits = 'No fields';
  double _sacksSold = 0.0;
  Map<String, double> _expenseBreakdown = {};

  @override
  void initState() {
    super.initState();
    _voiceHandler.listeningStream.listen((listening) {
      setState(() {
        _isListening = listening;
      });
    });
    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    final url = Uri.parse('http://192.168.1.2:5000/api/getDefaultAnalytics');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': widget.user.email}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      Map<String, double> expenseSummary = {};
      Map<String, double> profitSummary = {};
      Map<String, double> expenseBreakdown = {};

      data['expenseSummary']?.forEach((key, value) {
        expenseSummary[key] = value.toDouble();
      });

      data['profitSummary']?.forEach((key, value) {
        profitSummary[key] = value.toDouble();
      });

      if (data['expenseBreakdown'] != null) {
        data['expenseBreakdown']?.forEach((key, value) {
          if (value > 0) {
            expenseBreakdown[key] = value.toDouble();
          }
        });
      }

      setState(() {
        _expenseData = expenseSummary;
        _profitData = profitSummary;
        _fieldWithMostExpenses = data['fieldWithMostExpenses'] ?? 'No fields';
        _fieldWithMostProfits = data['fieldWithMostProfits'] ?? 'No fields';
        _sacksSold = (data['sacksSold'] ?? 0).toDouble();
        _expenseBreakdown = expenseBreakdown;
        _isLoading = false;
      });
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalExpenses = _expenseData.values.fold(
      0.0,
      (sum, val) => sum + val,
    );
    final totalProfits = _profitData.values.fold(0.0, (sum, val) => sum + val);

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
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Analytics',
                              style: const TextStyle(
                                fontSize: 26,
                                color: Color(0xFF655B40),
                              ),
                            ),
                          ),
                        ),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder:
                                    (_) => AnalyticsPage(user: widget.user),
                              ),
                            );
                          },
                          icon: Image.asset(
                            'assets/filters.png',
                            width: 20,
                            height: 20,
                          ),
                          label: const Text('Filters'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF655B40),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Total Expenses: ${totalExpenses.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF655B40),
                      ),
                    ),
                    const SizedBox(height: 30),
                    PieChart(
                      dataMap:
                          _expenseData.isEmpty ? {'No Data': 1} : _expenseData,
                      chartType: ChartType.ring,
                      chartRadius: MediaQuery.of(context).size.width / 2,
                      colorList: const [
                        Colors.blue,
                        Colors.green,
                        Colors.red,
                        Colors.orange,
                        Colors.purple,
                      ],
                      centerText: "Expenses",
                      legendOptions: const LegendOptions(
                        showLegends: true,
                        legendPosition: LegendPosition.right,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF655B40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field with most expenses: $_fieldWithMostExpenses',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          if (_expenseBreakdown.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            const Text(
                              'Expense Breakdown:',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            ..._expenseBreakdown.entries.map(
                              (e) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2,
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      '${e.key}:',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${e.value.toStringAsFixed(2)} €',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      'Total Profits: ${totalProfits.toStringAsFixed(2)} €',
                      style: const TextStyle(
                        fontSize: 18,
                        color: Color(0xFF655B40),
                      ),
                    ),
                    const SizedBox(height: 30),
                    PieChart(
                      dataMap:
                          _profitData.isEmpty ? {'No Data': 1} : _profitData,
                      chartType: ChartType.ring,
                      chartRadius: MediaQuery.of(context).size.width / 2,
                      colorList: const [
                        Colors.green,
                        Colors.blue,
                        Colors.yellow,
                        Colors.red,
                        Colors.orange,
                      ],
                      centerText: "Profits",
                      legendOptions: const LegendOptions(
                        showLegends: true,
                        legendPosition: LegendPosition.right,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF655B40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Field with most profits: $_fieldWithMostProfits',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Sacks Sold: ${_sacksSold.toInt()}',
                            style: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 75),
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
