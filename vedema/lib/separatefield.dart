import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings.dart';
import 'user.dart';
import 'newtask.dart';
import 'fields.dart';
import 'voicecommands.dart';

class SeparateFieldScreen extends StatefulWidget {
  final Field field;
  final User user;

  const SeparateFieldScreen({
    super.key,
    required this.field,
    required this.user,
  });

  @override
  State<SeparateFieldScreen> createState() => _SeparateFieldScreenState();
}

class _SeparateFieldScreenState extends State<SeparateFieldScreen> {
  late Field field;
  bool showExpenses = true;
  bool _isLoading = true;
  bool _isListening = false;

  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();

  @override
  void initState() {
    super.initState();
    _fetchField();

    _voiceHandler.listeningStream.listen((listening) {
      setState(() {
        _isListening = listening;
      });
    });
  }

  Future<void> _fetchField() async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:5000/api/getSingleField'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final f = data['field'];

        setState(() {
          field =
              Field(
                  f['location'],
                  f['size']?.toDouble() ?? 0.0,
                  f['oliveNo'] ?? 0,
                  f['cubics']?.toDouble() ?? 0.0,
                  f['price']?.toDouble() ?? 0.0,
                  f['species'] ?? '',
                )
                ..expenses =
                    (f['expenses'] as List).map((e) {
                      return Expense(
                        task: e['task'] ?? '',
                        date: e['date'] ?? '',
                        cost: (e['cost'] ?? 0).toDouble(),
                        synthesis: e['synthesis'] ?? '',
                        type: e['type'] ?? '',
                        npk: e['npk'] ?? '',
                        notes: e['notes'] ?? '',
                      );
                    }).toList()
                ..profits =
                    (f['profits'] as List).map((p) {
                      return Profit(
                        sacks: p['sacks'] ?? 0,
                        price: (p['price'] ?? 0).toDouble(),
                      );
                    }).toList()
                ..totalExpenses = (f['totalExpenses'] ?? 0).toDouble()
                ..totalProfits = (f['totalProfits'] ?? 0).toDouble();

          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load field');
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double net = field.totalProfits - field.totalExpenses;
    String displayNet =
        net == 0
            ? '0'
            : net > 0
            ? '+€${net.toStringAsFixed(2)}'
            : '-€${(-net).toStringAsFixed(2)}';
    Color netColor =
        net == 0 ? Colors.black : (net > 0 ? Colors.green : Colors.red);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF655B40),
        title: Text(
          field.location,
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => FieldsScreen(user: widget.user),
              ),
            );
          },
        ),
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
                builder:
                    (BuildContext context) =>
                        SettingsSidebar(user: widget.user),
              );
            },
          ),
        ],
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Balance: ',
                  style: TextStyle(fontSize: 24, color: Color(0xFF655B40)),
                ),
                Text(
                  displayNet,
                  style: TextStyle(fontSize: 24, color: netColor),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _toggleButton('Expenses', true),
                _toggleButton('Profits', false),
              ],
            ),
            const SizedBox(height: 10),
            if (showExpenses)
              Row(
                children: [
                  const Text(
                    'Total Expenses: ',
                    style: TextStyle(fontSize: 16, color: Color(0xFF655B40)),
                  ),
                  Text(
                    '€${field.totalExpenses.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 20),
            if (showExpenses) ...[
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _expenseButton('Irrigation', 'assets/irrigation.png'),
                  _expenseButton('Fertilization', 'assets/fertilize.png'),
                  _expenseButton('Spraying', 'assets/spraying.png'),
                  _expenseButton('Other', 'assets/moreicon.png'),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Expense History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: field.expenses.length,
                itemBuilder: (context, index) {
                  final expense = field.expenses[index];
                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFF655B40).withOpacity(0.2),
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.all(5),
                          child: Image.asset(
                            _getIconPath(expense.task),
                            height: 30,
                            width: 30,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                expense.task,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${expense.date} - €${expense.cost.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ] else ...[
              const Text(
                'Profit History',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: field.profits.length,
                itemBuilder: (context, index) {
                  final profit = field.profits[index];
                  return ListTile(
                    title: Text('${profit.sacks} sacks'),
                    subtitle: Text('€${profit.price.toStringAsFixed(2)}'),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String label, bool isExpense) {
    final selected = showExpenses == isExpense;
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            showExpenses = isExpense;
          });
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: selected ? const Color(0xFF655B40) : Colors.white,
          foregroundColor: selected ? Colors.white : Colors.black,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.zero,
            side: const BorderSide(color: Colors.black),
          ),
        ),
        child: Text(label),
      ),
    );
  }

  Widget _expenseButton(String title, String assetPath) {
    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => NewTaskForm(
                  taskName: title,
                  user: widget.user,
                  field: field,
                ),
          ),
        );
        _fetchField();
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF655B40),
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: Colors.white, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(assetPath, height: 60, width: 60),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  String _getIconPath(String task) {
    switch (task.toLowerCase()) {
      case 'irrigation':
        return 'assets/irrigationg.png';
      case 'fertilization':
        return 'assets/fertilizeg.png';
      case 'spraying':
        return 'assets/sprayingg.png';
      default:
        return 'assets/moreicong.png';
    }
  }
}
