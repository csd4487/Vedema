import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'settings.dart';
import 'user.dart';
import 'newtaskfromexpenses.dart';
import 'fields.dart';
import 'voicecommands.dart';
import 'addnewprofit2.dart';
import 'analyticsdefault.dart';
import 'sales.dart';
import 'addnewprofitother.dart';

class AllFieldsExpensesScreen extends StatefulWidget {
  final User user;

  const AllFieldsExpensesScreen({super.key, required this.user});

  @override
  State<AllFieldsExpensesScreen> createState() =>
      _AllFieldsExpensesScreenState();
}

class _AllFieldsExpensesScreenState extends State<AllFieldsExpensesScreen> {
  bool showExpenses = true;
  bool _isLoading = true;
  bool _isListening = false;
  int _totalAvailableSacks = 0;
  double _totalAvailableOilKg = 0.0;
  List<Map<String, dynamic>> _profitHistory = [];
  bool _showAllExpenses = false;
  bool _showAllProfits = false;
  List<Field> _allFields = [];
  double _totalExpenses = 0.0;
  double _totalProfits = 0.0;
  List<OtherExpense> _otherExpenses = [];
  double _otherExpensesTotal = 0.0;
  double _otherProfitsTotal = 0.0;

  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();

  @override
  void initState() {
    super.initState();
    _fetchAllData();
    _voiceHandler.listeningStream.listen((listening) {
      setState(() {
        _isListening = listening;
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _fetchAllData();
  }

  Future<void> _fetchAllData() async {
    setState(() => _isLoading = true);
    await Future.wait([
      _fetchAllFields(),
      _fetchTotalAvailableSacks(),
      _fetchTotalAvailableOil(),
      _fetchProfitHistory(),
      _fetchOtherExpenses(),
    ]);
    setState(() => _isLoading = false);
  }

  Future<void> _fetchAllFields() async {
    try {
      final response = await http.post(
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/getFields'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _allFields =
              (data['fields'] as List)
                  .map(
                    (f) =>
                        Field(
                            f['location'],
                            f['size']?.toDouble() ?? 0.0,
                            f['oliveNo'] ?? 0,
                            f['cubics']?.toDouble() ?? 0.0,
                            f['price']?.toDouble() ?? 0.0,
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
                          ..sackProductions =
                              (f['sackProductions'] as List)
                                  .map(
                                    (s) => SackProduction(
                                      sacks: s['sacks'] ?? 0,
                                      dateProduced: s['dateProduced'] ?? '',
                                    ),
                                  )
                                  .toList()
                          ..oilProductions =
                              (f['oilProductions'] as List)
                                  .map(
                                    (o) => OilProduction(
                                      sacksUsed: o['sacksUsed'] ?? 0,
                                      oilKg: (o['oilKg'] ?? 0).toDouble(),
                                      dateGrinded: o['dateGrinded'] ?? '',
                                    ),
                                  )
                                  .toList()
                          ..oilProfits =
                              (f['oilProfits'] as List)
                                  .map(
                                    (p) => OilProfit(
                                      oilKgSold:
                                          (p['oilKgSold'] ?? 0).toDouble(),
                                      pricePerKg:
                                          (p['pricePerKg'] ?? 0).toDouble(),
                                      totalEarned:
                                          (p['totalEarned'] ?? 0).toDouble(),
                                      dateSold: p['dateSold'] ?? '',
                                    ),
                                  )
                                  .toList()
                          ..totalExpenses = (f['totalExpenses'] ?? 0).toDouble()
                          ..totalProfits = (f['totalProfits'] ?? 0).toDouble()
                          ..availableSacks = f['availableSacks'] ?? 0
                          ..oilKg = (f['oilKg'] ?? 0).toDouble(),
                  )
                  .toList();

          _totalExpenses = _allFields.fold(
            0.0,
            (sum, field) => sum + field.totalExpenses,
          );
          _totalProfits = _allFields.fold(
            0.0,
            (sum, field) => sum + field.totalProfits,
          );
        });
      } else {
        throw Exception('Failed to load fields');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingFields}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchOtherExpenses() async {
    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getOtherExpenses',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _otherExpenses =
              (data['otherExpenses'] as List)
                  .map(
                    (e) => OtherExpense(
                      task: e['task'] ?? '',
                      date: e['date'] ?? '',
                      cost: (e['cost'] ?? 0).toDouble(),
                      notes: e['notes'] ?? '',
                    ),
                  )
                  .toList();
          _otherExpensesTotal = _otherExpenses.fold(
            0.0,
            (sum, expense) => sum + expense.cost,
          );
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${AppLocalizations.of(context)!.errorLoadingFields}: $e',
            ),
          ),
        );
      }
    }
  }

  Future<void> _fetchTotalAvailableSacks() async {
    final loc = AppLocalizations.of(context)!;

    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getTotalAvailableSacks',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalAvailableSacks = data['totalAvailableSacks'] ?? 0;
        });
      } else {
        throw Exception(loc.failedToLoadSacks);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorFetchingSacks}: $e')),
        );
      }
    }
  }

  Future<void> _fetchTotalAvailableOil() async {
    final loc = AppLocalizations.of(context)!;

    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getTotalAvailableOil',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _totalAvailableOilKg = (data['totalAvailableOilKg'] ?? 0).toDouble();
        });
      } else {
        throw Exception(loc.failedToLoadOil);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${loc.errorFetchingOil}: $e')));
      }
    }
  }

  Future<void> _fetchProfitHistory() async {
    final loc = AppLocalizations.of(context)!;

    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/getAllProfitHistory',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _profitHistory = List<Map<String, dynamic>>.from(data['history']);
          _otherProfitsTotal = _profitHistory
              .where((p) => p['type'] == 'other')
              .fold(0.0, (sum, profit) => sum + (profit['profitNo'] ?? 0));
        });
      } else {
        throw Exception(loc.failedToLoadProfits);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorFetchingProfits}: $e')),
        );
      }
    }
  }

  void _confirmDeleteExpense(Map<String, dynamic> expense, bool isOther) async {
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(loc.confirmDeletion),
            content: Text(loc.confirmDeleteExpensePrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _deleteExpense(expense, isOther);
    }
  }

  void _deleteExpense(Map<String, dynamic> expense, bool isOther) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final response = await http.post(
        Uri.parse(
          'https://94b6-79-131-87-183.ngrok-free.app/api/deleteExpense',
        ),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'location': isOther ? null : expense['location'],
          'task': expense['task'],
          'date': expense['date'],
          'cost': expense['cost'],
          'isOther': isOther,
        }),
      );

      if (response.statusCode == 200) {
        _fetchAllData();
      } else {
        throw Exception(loc.failedToDeleteExpense);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorDeletingExpense}: $e')),
        );
      }
    }
  }

  void _confirmDeleteProfit(Map<String, dynamic> profit) async {
    final loc = AppLocalizations.of(context)!;

    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(loc.confirmDeletion),
            content: Text(loc.confirmDeleteProfitPrompt),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(loc.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(loc.delete),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      _deleteProfit(profit);
    }
  }

  void _deleteProfit(Map<String, dynamic> profit) async {
    final loc = AppLocalizations.of(context)!;

    try {
      final url =
          profit['type'] == 'other'
              ? 'https://94b6-79-131-87-183.ngrok-free.app/api/deleteOtherProfit'
              : profit['type'] == 'sale'
              ? 'https://94b6-79-131-87-183.ngrok-free.app/api/deleteSale'
              : 'https://94b6-79-131-87-183.ngrok-free.app/api/deleteProfit';

      final body =
          profit['type'] == 'other'
              ? {
                'email': widget.user.email,
                'type': profit['profitType'] ?? '',
                'date': profit['date'],
                'profitNo': (profit['profitNo'] as num).toDouble(),
              }
              : profit['type'] == 'sale'
              ? {
                'email': widget.user.email,
                'location': profit['location'],
                'date': profit['date'],
                'oilKg': profit['oilKg'],
              }
              : {
                'email': widget.user.email,
                'location': profit['location'],
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

      if (response.statusCode == 200) {
        _fetchAllData();
      } else {
        throw Exception('${loc.failedToDeleteProfit}: ${response.body}');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${loc.errorDeletingProfit}: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    double net =
        (_totalProfits + _otherProfitsTotal) -
        (_totalExpenses + _otherExpensesTotal);
    String displayNet =
        net == 0
            ? '0'
            : net > 0
            ? '+€${net.toStringAsFixed(2)}'
            : '-€${(-net).toStringAsFixed(2)}';
    Color netColor =
        net == 0 ? Colors.black : (net > 0 ? Colors.green : Colors.red);

    List<Map<String, dynamic>> allExpenses = [];
    for (var field in _allFields) {
      for (var expense in field.expenses) {
        allExpenses.add({
          'type': 'expense',
          'location': field.location,
          'task': expense.task,
          'date': expense.date,
          'cost': expense.cost,
          'synthesis': expense.synthesis,
          'notes': expense.notes,
          'isOther': false,
        });
      }
    }
    for (var expense in _otherExpenses) {
      allExpenses.add({
        'type': 'expense',
        'location': loc.general,
        'task': expense.task,
        'date': expense.date,
        'cost': expense.cost,
        'notes': expense.notes,
        'isOther': true,
      });
    }
    allExpenses.sort((a, b) => b['date'].compareTo(a['date']));

    List<Map<String, dynamic>> allProfits = List.from(_profitHistory);
    allProfits.sort((a, b) => b['date'].compareTo(a['date']));

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF655B40),
        title: Text(
          loc.allFieldsSummary,
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
                  AppLocalizations.of(context)!.balance,
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
                _toggleButton(AppLocalizations.of(context)!.expenses, true),
                _toggleButton(AppLocalizations.of(context)!.profits, false),
              ],
            ),
            const SizedBox(height: 10),
            if (showExpenses) ...[
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalExpenses,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      Text(
                        '€${(_totalExpenses + _otherExpensesTotal).toStringAsFixed(1)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ] else ...[
              Column(
                children: [
                  Row(
                    children: [
                      Text(
                        AppLocalizations.of(context)!.totalProfits,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      Text(
                        '€$_totalProfits',
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
                        AppLocalizations.of(context)!.totalAvailableSacks,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      Text(
                        '$_totalAvailableSacks',
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
                        AppLocalizations.of(context)!.totalAvailableOil,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      Text(
                        '$_totalAvailableOilKg',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                        ),
                      ),
                    ],
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
                    AppLocalizations.of(context)!.irrigation,
                    'assets/irrigation.png',
                  ),
                  _expenseButton(
                    AppLocalizations.of(context)!.fertilization,
                    'assets/fertilize.png',
                  ),
                  _expenseButton(
                    AppLocalizations.of(context)!.spraying,
                    'assets/spraying.png',
                  ),
                  _expenseButton(
                    AppLocalizations.of(context)!.other,
                    'assets/moreicon.png',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(
                AppLocalizations.of(context)!.allExpensesHistory,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount:
                    _showAllExpenses
                        ? allExpenses.length
                        : allExpenses.length > 5
                        ? 5
                        : allExpenses.length,
                itemBuilder: (context, index) {
                  final expense = allExpenses[index];
                  final isOther = expense['isOther'] ?? false;

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
                            _getIconPath(expense['task']),
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
                                isOther
                                    ? '${AppLocalizations.of(context)!.general} - ${_localizeTask(expense['task'], context)}'
                                    : '${expense['location']} - ${_localizeTask(expense['task'], context)}',
                              ),

                              Text(
                                '${expense['date']} - €${expense['cost'].toStringAsFixed(2)}',
                              ),
                              if (expense['notes'] != null &&
                                  expense['notes'].isNotEmpty)
                                Text(
                                  expense['notes'],
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed:
                              () => _confirmDeleteExpense(expense, isOther),
                        ),
                      ],
                    ),
                  );
                },
              ),
              if (allExpenses.length > 5)
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
                        ? AppLocalizations.of(context)!.showLess
                        : AppLocalizations.of(context)!.showMore,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ] else ...[
              Column(
                children: [
                  GridView.count(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      _profitButton('sacks', 'assets/sack.png'),
                      _profitButton('grind', 'assets/grinder.png'),
                      _profitButton('sell', 'assets/sack.png'),
                      _profitButton('other', 'assets/moreicon.png'),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    loc.profitHistory,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        _showAllProfits
                            ? allProfits.length
                            : allProfits.length > 5
                            ? 5
                            : allProfits.length,
                    itemBuilder: (context, index) {
                      final profit = allProfits[index];
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
                                    : profit['type'] == 'other'
                                    ? 'assets/moreicong.png'
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
                                    profit['type'] == 'other'
                                        ? '${loc.other} - ${profit['profitType']}'
                                        : '${profit['location']} - ${profit['type'] == 'grind'
                                            ? loc.grind
                                            : profit['type'] == 'sale'
                                            ? loc.sell
                                            : loc.sacks}',
                                    style: const TextStyle(fontSize: 16),
                                  ),
                                  Text(
                                    profit['type'] == 'grind'
                                        ? '${profit['date']} - ${profit['oilKg']} kg'
                                        : profit['type'] == 'sale'
                                        ? '${profit['date']} - ${profit['oilKg']} kg ${loc.soldFor} €${profit['totalEarned']?.toStringAsFixed(2)}'
                                        : profit['type'] == 'other'
                                        ? '${profit['date']} - €${profit['profitNo']?.toStringAsFixed(2)}'
                                        : '${profit['date']} - ${profit['sacks']} ${loc.sacks}',
                                  ),
                                  if (profit['notes'] != null &&
                                      profit['notes'].isNotEmpty)
                                    Text(
                                      profit['notes'],
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
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
                  if (allProfits.length > 5)
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
                        _showAllProfits ? loc.showLess : loc.showMore,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF655B40),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Image.asset('assets/field.png', height: 35, width: 35),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => FieldsScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.fields,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Image.asset(
                    'assets/expensesfooter.png',
                    height: 35,
                    width: 35,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) =>
                                AllFieldsExpensesScreen(user: widget.user),
                      ),
                    );
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.expenses,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Image.asset('assets/stats.png', height: 35, width: 35),
                  onPressed: () {
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
                  },
                ),
                Text(
                  AppLocalizations.of(context)!.analytics,
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _toggleButton(String labelKey, bool isExpense) {
    final selected = showExpenses == isExpense;
    final loc = AppLocalizations.of(context)!;

    final localizedLabel =
        labelKey == 'Expenses'
            ? loc.expenses
            : labelKey == 'Profits'
            ? loc.profits
            : labelKey;

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
        child: Text(localizedLabel),
      ),
    );
  }

  String _localizeTask(String task, BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    switch (task.toLowerCase()) {
      case 'irrigation':
        return loc.irrigation;
      case 'fertilization':
        return loc.fertilization;
      case 'spraying':
        return loc.spraying;
      case 'other':
        return loc.other;
      default:
        return task;
    }
  }

  Widget _expenseButton(String titleKey, String assetPath) {
    final loc = AppLocalizations.of(context)!;

    final localizedTitle =
        {
          'Irrigation': loc.irrigation,
          'Fertilization': loc.fertilization,
          'Spraying': loc.spraying,
          'Other': loc.other,
        }[titleKey] ??
        titleKey;

    return ElevatedButton(
      onPressed: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) =>
                    NewTaskFormExpenses(taskName: titleKey, user: widget.user),
          ),
        );
        _fetchAllData();
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
            localizedTitle,
            style: const TextStyle(fontSize: 16, color: Colors.white),
          ),
        ],
      ),
    );
  }

  Widget _profitButton(String key, String assetPath) {
    final loc = AppLocalizations.of(context)!;

    final localizedTitle =
        {
          'sacks': loc.sacks,
          'grind': loc.grind,
          'sell': loc.sell,
          'other': loc.other,
        }[key] ??
        key;

    return ElevatedButton(
      onPressed: () async {
        if (key == 'sacks') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddNewProfit2(user: widget.user, mode: 'add'),
            ),
          );
        } else if (key == 'grind') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (context) => AddNewProfit2(user: widget.user, mode: 'grind'),
            ),
          );
        } else if (key == 'sell') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SalesScreen(user: widget.user),
            ),
          );
        } else if (key == 'other') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewProfitOtherPage(user: widget.user),
            ),
          );
        }

        _fetchAllData();
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
            localizedTitle,
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
