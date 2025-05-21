import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'settings.dart';
import 'user.dart';
import 'newtask.dart';
import 'fields.dart';
import 'voicecommands.dart';
import 'addnewfieldprofit.dart';
import 'sellSeparate.dart';

class SeparateFieldScreen extends StatefulWidget {
  final Field field;
  final User user;

  const SeparateFieldScreen({Key? key, required this.field, required this.user})
    : super(key: key);

  @override
  State<SeparateFieldScreen> createState() => _SeparateFieldScreenState();
}

class _SeparateFieldScreenState extends State<SeparateFieldScreen> {
  late Field field;
  bool showExpenses = true;
  bool _isLoading = true;
  bool _isListening = false;
  int _availableSacks = 0;
  double _availableOilKg = 0.0;
  List<Map<String, dynamic>> _profitHistory = [];
  bool _showAllExpenses = false;
  bool _showAllProfits = false;

  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();

  @override
  void initState() {
    super.initState();
    _fetchField();
    _fetchAvailableSacks();
    _fetchAvailableOil();
    _fetchProfitHistory();

    _voiceHandler.listeningStream.listen((listening) {
      if (mounted) {
        setState(() {
          _isListening = listening;
        });
      }
    });
  }

  Future<void> _fetchField() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getSingleField',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final f = data['field'];

        if (mounted) {
          setState(() {
            field =
                Field(
                    f['location'],
                    (f['size'] ?? 0).toDouble(),
                    f['oliveNo'] ?? 0,
                    (f['cubics'] ?? 0).toDouble(),
                    (f['price'] ?? 0).toDouble(),
                    f['species'] ?? '',
                  )
                  ..expenses =
                      (f['expenses'] as List)
                          .map(
                            (e) => Expense(
                              task: e['task'] ?? '',
                              date: e['date'] ?? '',
                              cost: (e['cost'] ?? 0).toDouble(),
                              synthesis: e['synthesis'] ?? '',
                              type: e['type'] ?? '',
                              npk: e['npk'] ?? '',
                              notes: e['notes'] ?? '',
                            ),
                          )
                          .toList()
                  ..oilProfits =
                      (f['oilProfits'] as List)
                          .map(
                            (p) => OilProfit(
                              oilKgSold: (p['oilKgSold'] ?? 0).toDouble(),
                              pricePerKg: (p['pricePerKg'] ?? 0).toDouble(),
                              totalEarned: (p['totalEarned'] ?? 0).toDouble(),
                              dateSold: p['dateSold'] ?? '',
                            ),
                          )
                          .toList()
                  ..totalExpenses = (f['totalExpenses'] ?? 0).toDouble()
                  ..totalProfits = (f['totalProfits'] ?? 0).toDouble()
                  ..oilKg = (f['oilKg'] ?? 0).toDouble();

            _isLoading = false;
          });
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadField);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _fetchAvailableSacks() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getAvailableSacks',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _availableSacks = data['availableSacks'] ?? 0;
          });
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadSacks);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  String _getLocalizedTaskName(String task) {
    final localizations = AppLocalizations.of(context)!;
    switch (task.toLowerCase()) {
      case 'irrigation':
        return localizations.irrigation;
      case 'fertilization':
        return localizations.fertilization;
      case 'spraying':
        return localizations.spraying;
      default:
        return localizations.other;
    }
  }

  Future<void> _fetchAvailableOil() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getAvailableOil',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _availableOilKg = (data['availableOilKg'] ?? 0).toDouble();
          });
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadOil);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  Future<void> _fetchProfitHistory() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getProfitHistory',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (mounted) {
          setState(() {
            _profitHistory = List<Map<String, dynamic>>.from(data['history']);
          });
        }
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadHistory);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  void _confirmDeleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDeletion),
            content: Text(
              AppLocalizations.of(context)!.deleteExpenseConfirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      _deleteExpense(expense);
    }
  }

  Future<void> _deleteExpense(Expense expense) async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/deleteExpense',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': widget.field.location,
          'task': expense.task,
          'date': expense.date,
          'cost': expense.cost,
        }),
      );

      if (response.statusCode == 200 && mounted) {
        _fetchField();
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToDeleteExpense);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  void _confirmDeleteProfit(Map<String, dynamic> profit) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDeletion),
            content: Text(
              AppLocalizations.of(context)!.deleteProfitConfirmation,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(AppLocalizations.of(context)!.delete),
              ),
            ],
          ),
    );

    if (confirmed == true && mounted) {
      _deleteProfit(profit);
    }
  }

  Future<void> _deleteProfit(Map<String, dynamic> profit) async {
    try {
      final url =
          profit['type'] == 'sale'
              ? 'https://94b6-79-131-87-183.ngrok-free.app/api/deleteSale'
              : 'https://94b6-79-131-87-183.ngrok-free.app/api/deleteProfit';

      final body =
          profit['type'] == 'sale'
              ? {
                'email': widget.user.email,
                'location': widget.field.location,
                'date': profit['date'],
                'oilKg': profit['oilKg'],
              }
              : {
                'email': widget.user.email,
                'location': widget.field.location,
                'type': profit['type'],
                'date': profit['date'],
                'sacks': profit['sacks'],
                'oilKg': profit['oilKg'],
              };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200 && mounted) {
        await _fetchField();
        await _fetchAvailableSacks();
        await _fetchAvailableOil();
        await _fetchProfitHistory();
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToDeleteProfit);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.error}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

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

    List<Expense> displayedExpenses =
        _showAllExpenses
            ? field.expenses
            : field.expenses.length > 5
            ? field.expenses.sublist(0, 5)
            : field.expenses;

    List<Map<String, dynamic>> displayedProfits =
        _showAllProfits
            ? _profitHistory
            : _profitHistory.length > 5
            ? _profitHistory.sublist(0, 5)
            : _profitHistory;

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
                Text(
                  '${localizations.balance} ',
                  style: const TextStyle(
                    fontSize: 24,
                    color: Color(0xFF655B40),
                  ),
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
                _toggleButton(localizations.expenses, true),
                _toggleButton(localizations.profits, false),
              ],
            ),
            const SizedBox(height: 10),
            if (showExpenses)
              Row(
                children: [
                  Text(
                    '${localizations.totalExpenses} ',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
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
            if (!showExpenses) ...[
              Row(
                children: [
                  Text(
                    '${localizations.totalProfits} ',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  Text(
                    '€${field.totalProfits.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    '${localizations.availableSacks}: ',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  Text(
                    '$_availableSacks',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Row(
                children: [
                  Text(
                    '${localizations.availableOilKg}: ',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                  Text(
                    '$_availableOilKg',
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF655B40),
                    ),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 20),
            if (showExpenses) ...[
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _expenseButton(
                    localizations.irrigation,
                    'assets/irrigation.png',
                  ),
                  _expenseButton(
                    localizations.fertilization,
                    'assets/fertilize.png',
                  ),
                  _expenseButton(localizations.spraying, 'assets/spraying.png'),
                  _expenseButton(localizations.other, 'assets/moreicon.png'),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                localizations.expenseHistory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedExpenses.length,
                itemBuilder: (context, index) {
                  final expense = displayedExpenses[index];
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
                                _getLocalizedTaskName(expense.task),
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                '${expense.date} - €${expense.cost.toStringAsFixed(2)}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteExpense(expense),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (field.expenses.length > 5)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllExpenses = !_showAllExpenses;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF655B40),
                  ),
                  child: Text(
                    _showAllExpenses
                        ? localizations.showLess
                        : localizations.showMore,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ] else ...[
              const SizedBox(height: 10),
              GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _profitButton(localizations.sacks, 'assets/sack.png'),
                  _profitButton(localizations.grind, 'assets/grinder.png'),
                  _profitButton(localizations.sell, 'assets/sack.png'),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                localizations.profitHistory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: displayedProfits.length,
                itemBuilder: (context, index) {
                  final profit = displayedProfits[index];
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
                            profit['type'] == 'grind'
                                ? 'assets/grinderg.png'
                                : profit['type'] == 'sale'
                                ? 'assets/grinderg.png'
                                : 'assets/sackg.png',
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
                                profit['type'] == 'grind'
                                    ? localizations.grind
                                    : profit['type'] == 'sale'
                                    ? localizations.sell
                                    : localizations.sacks,
                                style: const TextStyle(fontSize: 16),
                              ),
                              Text(
                                profit['type'] == 'grind'
                                    ? '${profit['date']} - ${profit['oilKg']} kg'
                                    : profit['type'] == 'sale'
                                    ? '${profit['date']} - ${profit['oilKg']} kg ${localizations.soldFor} €${profit['totalEarned']?.toStringAsFixed(2)}'
                                    : '${profit['date']} - ${profit['sacks']} ${localizations.sacks}',
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDeleteProfit(profit),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (_profitHistory.length > 5)
                TextButton(
                  onPressed: () {
                    setState(() {
                      _showAllProfits = !_showAllProfits;
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF655B40),
                  ),
                  child: Text(
                    _showAllProfits
                        ? localizations.showLess
                        : localizations.showMore,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
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
        if (mounted) {
          _fetchField();
        }
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

  Widget _profitButton(String title, String assetPath) {
    final loc = AppLocalizations.of(context)!;
    return ElevatedButton(
      onPressed: () async {
        if (title == loc.sacks) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddNewFieldGrind(
                    user: widget.user,
                    field: field,
                    mode: 'add',
                  ),
            ),
          );
        } else if (title == loc.grind) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddNewFieldGrind(
                    user: widget.user,
                    field: field,
                    mode: 'grind',
                  ),
            ),
          );
        } else if (title == loc.sell) {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => SellSeparateScreen(
                    user: widget.user,
                    field: widget.field,
                  ),
            ),
          );
        }
        if (mounted) {
          await _fetchField();
          await _fetchAvailableSacks();
          await _fetchAvailableOil();
          await _fetchProfitHistory();
        }
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
