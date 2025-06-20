import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:pie_chart/pie_chart.dart' as pie;
import 'package:syncfusion_flutter_charts/charts.dart' as sf;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'user.dart';
import 'fields.dart';
import 'expenses.dart';
import 'settings.dart';
import 'package:permission_handler/permission_handler.dart';
import 'voicecommands.dart';
import 'package:open_filex/open_filex.dart';
import 'package:excel/excel.dart' as ex;
import 'package:file_saver/file_saver.dart';
import 'analytics.dart';
import 'dart:io';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AnalyticsDefaultPage extends StatefulWidget {
  final User user;
  final String analyticsType;
  final String? selectedPeriod;
  final List<String>? selectedFields;
  final String? viewType;
  final List<String>? selectedTasks;
  final String? chartType;

  const AnalyticsDefaultPage({
    Key? key,
    required this.user,
    required this.analyticsType,
    this.selectedPeriod,
    this.selectedFields,
    this.viewType,
    this.selectedTasks,
    this.chartType,
  }) : super(key: key);

  @override
  State<AnalyticsDefaultPage> createState() => _AnalyticsDefaultPageState();
}

class _AnalyticsDefaultPageState extends State<AnalyticsDefaultPage> {
  final VoiceCommandHandler _voiceHandler = VoiceCommandHandler();
  bool _isListening = false;
  bool _isLoading = true;
  bool _showExportOptions = false;

  Map<String, double> _expenseData = {};
  Map<String, double> _profitData = {};
  String _fieldWithMostExpenses = '';
  String _fieldWithMostProfits = '';
  double _sacksSold = 0.0;
  double _oilKgSold = 0.0;
  Map<String, double> _expenseBreakdown = {};
  String _currentSeason = '';
  String _chartType = 'Pie Chart';
  bool _showExpenses = true;
  bool _showProfits = true;
  double _totalExpenses = 0.0;
  double _totalProfits = 0.0;
  double _netProfit = 0.0;
  Map<String, Map<String, double>> _fieldExpenseDetails = {};
  Map<String, Map<String, double>> _fieldProfitDetails = {};

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

    if (widget.analyticsType == 'filtered') {
      _chartType = widget.chartType ?? loc.pieChart;
      final viewType = widget.viewType ?? 'Both';
      _showExpenses = viewType == 'Both' || viewType == loc.expenses;
      _showProfits = viewType == 'Both' || viewType == loc.profits;
      _currentSeason = loc.season(widget.selectedPeriod ?? '');
    } else {
      _currentSeason = loc.season('2024-2025');
    }

    fetchAnalyticsData();
  }

  Future<void> fetchAnalyticsData() async {
    final loc = AppLocalizations.of(context)!;

    final url = Uri.parse(
      widget.analyticsType == 'default'
          ? 'https://d1ee-94-65-160-226.ngrok-free.app/api/getDefaultAnalytics'
          : 'https://d1ee-94-65-160-226.ngrok-free.app/api/getFilteredAnalytics',
    );

    final body =
        widget.analyticsType == 'default'
            ? {'email': widget.user.email}
            : {
              'email': widget.user.email,
              'period': widget.selectedPeriod,
              'selectedFields': widget.selectedFields,
              'viewType': widget.viewType,
              'selectedTasks': widget.selectedTasks,
              'chartType': widget.chartType,
            };

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _processResponseData(data);
      } else {
        throw Exception(loc.failedToLoadAnalytics);
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${loc.errorLoadingAnalytics}: ${e.toString()}'),
        ),
      );
    }
  }

  String _translateTask(String task, AppLocalizations loc) {
    switch (task) {
      case 'Fertilization':
        return loc.fertilization;
      case 'Spraying':
        return loc.spraying;
      case 'Irrigation':
        return loc.irrigation;
      case 'Other':
        return loc.other;
      default:
        return task;
    }
  }

  Future<void> _exportToExcel() async {
    final loc = AppLocalizations.of(context)!;

    final status = await Permission.storage.request();
    if (!status.isGranted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.storagePermissionRequired)));
      return;
    }

    setState(() {
      _showExportOptions = false;
    });

    final excel = ex.Excel.createExcel();
    final sheet = excel['Analytics'];

    void addRow(String title, dynamic value, {bool isBold = false}) {
      final rowIndex = sheet.rows.length;
      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
          )
          .value = title;
      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
          )
          .value = value is double || value is int ? value : value.toString();

      if (isBold) {
        final style = ex.CellStyle(bold: true);
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
            )
            .cellStyle = style;
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
            )
            .cellStyle = style;
      }
    }

    sheet
        .cell(ex.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .value = '${loc.season}: $_currentSeason';
    sheet.appendRow([]);

    if (_showExpenses && _expenseData.isNotEmpty) {
      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: sheet.rows.length,
            ),
          )
          .value = loc.expensesAnalysis;
      addRow(loc.totalExpenses, _totalExpenses, isBold: true);
      sheet.appendRow([]);

      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: sheet.rows.length,
            ),
          )
          .value = loc.expenseCategories;
      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: sheet.rows.length,
            ),
          )
          .value = loc.amount;
      sheet.appendRow([]);

      for (final entry in _expenseData.entries) {
        addRow(_translateTask(entry.key, loc), entry.value);
      }
      sheet.appendRow([]);

      if (_fieldWithMostExpenses.isNotEmpty) {
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: sheet.rows.length,
              ),
            )
            .value = loc.fieldWithMostExpenses(_fieldWithMostExpenses);
        sheet.appendRow([]);

        if (_expenseBreakdown.isNotEmpty) {
          sheet
              .cell(
                ex.CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.rows.length,
                ),
              )
              .value = '${loc.expenseBreakdown}:';
          sheet.appendRow([]);
          for (final entry in _expenseBreakdown.entries) {
            addRow(_translateTask(entry.key, loc), entry.value);
          }
        }
        sheet.appendRow([]);
      }

      if (_fieldExpenseDetails.isNotEmpty) {
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: sheet.rows.length,
              ),
            )
            .value = loc.detailedExpensesByField;
        sheet.appendRow([]);
        for (final fieldEntry in _fieldExpenseDetails.entries) {
          sheet
              .cell(
                ex.CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.rows.length,
                ),
              )
              .value = fieldEntry.key;
          sheet.appendRow([]);
          for (final taskEntry in fieldEntry.value.entries) {
            if (taskEntry.value > 0) {
              addRow(_translateTask(taskEntry.key, loc), taskEntry.value);
            }
          }
          sheet.appendRow([]);
        }
      }
    }

    if (_showProfits && _profitData.isNotEmpty) {
      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: sheet.rows.length,
            ),
          )
          .value = loc.profitsAnalysis;
      addRow(loc.totalProfits, _totalProfits, isBold: true);
      sheet.appendRow([]);

      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 0,
              rowIndex: sheet.rows.length,
            ),
          )
          .value = loc.profitCategories;
      sheet
          .cell(
            ex.CellIndex.indexByColumnRow(
              columnIndex: 1,
              rowIndex: sheet.rows.length,
            ),
          )
          .value = loc.amount;
      sheet.appendRow([]);

      for (final entry in _profitData.entries) {
        addRow(_translateTask(entry.key, loc), entry.value);
      }
      sheet.appendRow([]);

      if (_fieldWithMostProfits.isNotEmpty) {
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: sheet.rows.length,
              ),
            )
            .value = loc.fieldWithMostProfits(_fieldWithMostProfits);
        sheet.appendRow([]);

        if (_oilKgSold > 0) {
          addRow('${loc.oilSold}:', '${_oilKgSold.toStringAsFixed(2)} kg');
        }

        if (_sacksSold > 0) {
          addRow('${loc.sacksSold}:', _sacksSold.toStringAsFixed(2));
        }

        if (_profitData.containsKey('Other')) {
          sheet
              .cell(
                ex.CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.rows.length,
                ),
              )
              .value = '${loc.otherProfits}:';
          sheet.appendRow([]);
          addRow(loc.total, _profitData['Other']);
        }
      }

      if (_fieldProfitDetails.isNotEmpty) {
        sheet
            .cell(
              ex.CellIndex.indexByColumnRow(
                columnIndex: 0,
                rowIndex: sheet.rows.length,
              ),
            )
            .value = loc.detailedProfitsByField;
        sheet.appendRow([]);
        for (final fieldEntry in _fieldProfitDetails.entries) {
          sheet
              .cell(
                ex.CellIndex.indexByColumnRow(
                  columnIndex: 0,
                  rowIndex: sheet.rows.length,
                ),
              )
              .value = fieldEntry.key;
          sheet.appendRow([]);
          for (final profitEntry in fieldEntry.value.entries) {
            if (profitEntry.value > 0) {
              final translatedKey = _translateTask(profitEntry.key, loc);
              final displayValue =
                  (profitEntry.key == 'oilSold')
                      ? '${profitEntry.value.toStringAsFixed(2)} kg'
                      : (profitEntry.key == 'sacksSold')
                      ? '${profitEntry.value.toStringAsFixed(2)} ${loc.sacks}'
                      : profitEntry.value;
              addRow(translatedKey, displayValue);
            }
          }
          sheet.appendRow([]);
        }
      }
    }

    Directory? downloadsDirectory;
    if (Platform.isAndroid) {
      downloadsDirectory = Directory('/storage/emulated/0/Download');
    } else {
      downloadsDirectory = await getApplicationDocumentsDirectory();
    }

    if (downloadsDirectory == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.downloadsDirectoryNotFound)));
      return;
    }

    final filePath = '${downloadsDirectory.path}/analytics_report.xlsx';
    final file = File(filePath);
    await file.writeAsBytes(excel.encode()!);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${loc.excelExportedTo} $filePath')));

    final result = await OpenFilex.open(filePath);
    if (result.type != ResultType.done) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(loc.failedToOpenExcel)));
    }
  }

  Future<void> _exportToPDF() async {
    final loc = AppLocalizations.of(context)!;

    setState(() {
      _showExportOptions = false;
    });

    final pdf = pw.Document();
    final font = await PdfGoogleFonts.robotoRegular();
    final fontBold = await PdfGoogleFonts.robotoBold();

    String formatCurrency(double value) {
      return '${value.toStringAsFixed(2)} €';
    }

    if (_showExpenses && _expenseData.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  loc.expensesAnalysis,
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${loc.totalExpenses}: ${formatCurrency(_totalExpenses)}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            loc.category,
                            style: pw.TextStyle(font: fontBold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            loc.amount,
                            style: pw.TextStyle(font: fontBold),
                          ),
                        ),
                      ],
                    ),
                    ..._expenseData.entries.map(
                      (entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              _translateTask(entry.key, loc),
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              formatCurrency(entry.value),
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                if (_fieldWithMostExpenses.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          loc.fieldWithMostExpenses(_fieldWithMostExpenses),
                          style: pw.TextStyle(font: fontBold),
                        ),
                        if (_expenseBreakdown.isNotEmpty) ...[
                          pw.SizedBox(height: 8),
                          pw.Text(
                            '${loc.expenseBreakdown}:',
                            style: pw.TextStyle(font: fontBold),
                          ),
                          pw.SizedBox(height: 4),
                          ..._expenseBreakdown.entries.map(
                            (e) => pw.Row(
                              children: [
                                pw.Text(
                                  '${_translateTask(e.key, loc)}:',
                                  style: pw.TextStyle(font: font),
                                ),
                                pw.Spacer(),
                                pw.Text(
                                  formatCurrency(e.value),
                                  style: pw.TextStyle(font: font),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (_fieldExpenseDetails.isNotEmpty) ...[
                  pw.Text(
                    loc.detailedExpensesByField,
                    style: pw.TextStyle(font: fontBold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  for (final fieldEntry in _fieldExpenseDetails.entries) ...[
                    pw.Text(
                      fieldEntry.key,
                      style: pw.TextStyle(font: fontBold),
                    ),
                    pw.SizedBox(height: 4),
                    for (final taskEntry in fieldEntry.value.entries)
                      if (taskEntry.value > 0)
                        pw.Row(
                          children: [
                            pw.Text(
                              '${_translateTask(taskEntry.key, loc)}:',
                              style: pw.TextStyle(font: font),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              formatCurrency(taskEntry.value),
                              style: pw.TextStyle(font: font),
                            ),
                          ],
                        ),
                    pw.SizedBox(height: 8),
                  ],
                ],
              ],
            );
          },
        ),
      );
    }

    if (_showProfits && _profitData.isNotEmpty) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  loc.profitsAnalysis,
                  style: pw.TextStyle(font: fontBold, fontSize: 18),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '${loc.totalProfits}: ${formatCurrency(_totalProfits)}',
                  style: pw.TextStyle(font: font, fontSize: 14),
                ),
                pw.SizedBox(height: 10),
                pw.Table(
                  border: pw.TableBorder.all(),
                  children: [
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            loc.category,
                            style: pw.TextStyle(font: fontBold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            loc.amount,
                            style: pw.TextStyle(font: fontBold),
                          ),
                        ),
                      ],
                    ),
                    ..._profitData.entries.map(
                      (entry) => pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              _translateTask(entry.key, loc),
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              formatCurrency(entry.value),
                              style: pw.TextStyle(font: font),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(height: 20),
                if (_fieldWithMostProfits.isNotEmpty) ...[
                  pw.Container(
                    width: double.infinity,
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey300,
                      borderRadius: pw.BorderRadius.circular(5),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          loc.fieldWithMostProfits(_fieldWithMostProfits),
                          style: pw.TextStyle(font: fontBold),
                        ),
                        pw.SizedBox(height: 8),
                        if (_oilKgSold > 0)
                          pw.Row(
                            children: [
                              pw.Text(
                                '${loc.oilSold}:',
                                style: pw.TextStyle(font: font),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                '${_oilKgSold.toStringAsFixed(2)} kg',
                                style: pw.TextStyle(font: font),
                              ),
                            ],
                          ),
                        if (_sacksSold > 0)
                          pw.Row(
                            children: [
                              pw.Text(
                                '${loc.sacksSold}:',
                                style: pw.TextStyle(font: font),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                '${_sacksSold.toStringAsFixed(2)}',
                                style: pw.TextStyle(font: font),
                              ),
                            ],
                          ),
                        if (_profitData.containsKey('Other')) ...[
                          pw.SizedBox(height: 8),
                          pw.Text(
                            '${loc.otherProfits}:',
                            style: pw.TextStyle(font: fontBold),
                          ),
                          pw.Row(
                            children: [
                              pw.Text(
                                '${loc.total}:',
                                style: pw.TextStyle(font: font),
                              ),
                              pw.Spacer(),
                              pw.Text(
                                formatCurrency(_profitData['Other'] ?? 0),
                                style: pw.TextStyle(font: font),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 20),
                ],
                if (_fieldProfitDetails.isNotEmpty) ...[
                  pw.Text(
                    loc.detailedProfitsByField,
                    style: pw.TextStyle(font: fontBold, fontSize: 16),
                  ),
                  pw.SizedBox(height: 10),
                  for (final fieldEntry in _fieldProfitDetails.entries) ...[
                    pw.Text(
                      fieldEntry.key,
                      style: pw.TextStyle(font: fontBold),
                    ),
                    pw.SizedBox(height: 4),
                    for (final profitEntry in fieldEntry.value.entries)
                      if (profitEntry.value > 0)
                        pw.Row(
                          children: [
                            pw.Text(
                              '${_translateTask(profitEntry.key, loc)}:',
                              style: pw.TextStyle(font: font),
                            ),
                            pw.Spacer(),
                            pw.Text(
                              profitEntry.key == 'oilSold'
                                  ? '${profitEntry.value.toStringAsFixed(2)} kg'
                                  : profitEntry.key == 'sacksSold'
                                  ? '${profitEntry.value.toStringAsFixed(2)} ${loc.sacks}'
                                  : formatCurrency(profitEntry.value),
                              style: pw.TextStyle(font: font),
                            ),
                          ],
                        ),
                    pw.SizedBox(height: 8),
                  ],
                ],
              ],
            );
          },
        ),
      );
    }

    final output = await getTemporaryDirectory();
    final file = File('${output.path}/analytics_report.pdf');
    await file.writeAsBytes(await pdf.save());

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
    );
  }

  void _processResponseData(Map<String, dynamic> data) {
    // Process expense data
    Map<String, double> expenseSummary = {
      'Fertilization':
          (data['expenseSummary']?['fertilization'] ?? 0).toDouble(),
      'Spraying': (data['expenseSummary']?['spraying'] ?? 0).toDouble(),
      'Irrigation': (data['expenseSummary']?['irrigation'] ?? 0).toDouble(),
      'Other': (data['expenseSummary']?['other'] ?? 0).toDouble(),
    };

    // Process profit data
    Map<String, double> profitSummary = {
      'Oil Sales': (data['profitSummary']?['oilsales'] ?? 0).toDouble(),
      'Sack Sales': (data['profitSummary']?['sacksales'] ?? 0).toDouble(),
      'Other': (data['profitSummary']?['other'] ?? 0).toDouble(),
    };

    // Process expense breakdown
    Map<String, double> expenseBreakdown = {
      'Fertilization':
          (data['expenseBreakdown']?['fertilization'] ?? 0).toDouble(),
      'Spraying': (data['expenseBreakdown']?['spraying'] ?? 0).toDouble(),
      'Irrigation': (data['expenseBreakdown']?['irrigation'] ?? 0).toDouble(),
      'Other': (data['expenseBreakdown']?['other'] ?? 0).toDouble(),
    };

    // Process field expense details
    Map<String, Map<String, double>> fieldExpenseDetails = {};
    if (data['fieldExpenseDetails'] != null) {
      (data['fieldExpenseDetails'] as Map).forEach((field, tasks) {
        fieldExpenseDetails[field] = {
          'Fertilization': (tasks['fertilization'] ?? 0).toDouble(),
          'Spraying': (tasks['spraying'] ?? 0).toDouble(),
          'Irrigation': (tasks['irrigation'] ?? 0).toDouble(),
          'Other': (tasks['other'] ?? 0).toDouble(),
        };
      });
    }

    // Process field profit details
    Map<String, Map<String, double>> fieldProfitDetails = {};
    if (data['fieldProfitDetails'] != null) {
      (data['fieldProfitDetails'] as Map).forEach((field, profits) {
        fieldProfitDetails[field] = {
          'Oil Sold': (profits['oilsold'] ?? 0).toDouble(),
          'Sacks Sold': (profits['sackssold'] ?? 0).toDouble(),
          'Other': (profits['other'] ?? 0).toDouble(),
        };
      });
    }

    setState(() {
      _expenseData = expenseSummary;
      _profitData = profitSummary;
      _expenseBreakdown = expenseBreakdown;
      _fieldExpenseDetails = fieldExpenseDetails;
      _fieldProfitDetails = fieldProfitDetails;
      _fieldWithMostExpenses = data['fieldWithMostExpenses'] ?? '';
      _fieldWithMostProfits = data['fieldWithMostProfits'] ?? '';
      _sacksSold = (data['sacksSold'] ?? 0).toDouble();
      _oilKgSold = (data['oilKgSold'] ?? 0).toDouble();
      _totalExpenses = (data['totalExpenses'] ?? 0).toDouble();
      _totalProfits = (data['totalProfits'] ?? 0).toDouble();
      _netProfit = (data['netProfit'] ?? 0).toDouble();
      _isLoading = false;
    });
  }

  Widget _buildChart(Map<String, double> data, String titleKey) {
    if (data.isEmpty) {
      return Center(
        child: Text(
          '${AppLocalizations.of(context)!.noDataAvailable} $titleKey',
          style: const TextStyle(color: Color(0xFF655B40)),
        ),
      );
    }

    switch (_chartType) {
      case 'Bar Chart':
        return _buildBarChart(data, titleKey);
      case 'Line Chart':
        return _buildLineChart(data, titleKey);
      case 'Doughnut Chart':
        return _buildPieChart(data, titleKey, pie.ChartType.disc);
      default:
        return _buildPieChart(data, titleKey);
    }
  }

  Widget _buildPieChart(
    Map<String, double> data,
    String title, [
    pie.ChartType chartType = pie.ChartType.ring,
  ]) {
    final loc = AppLocalizations.of(context)!;
    final localizedTitle =
        title.toLowerCase() == 'expenses'
            ? loc.expenses
            : title.toLowerCase() == 'profits'
            ? loc.profits
            : title;

    final translatedData = {
      for (var entry in data.entries)
        _translateTask(entry.key, loc): entry.value,
    };

    return Padding(
      padding: const EdgeInsets.only(left: 18.0),
      child: pie.PieChart(
        dataMap: translatedData,
        chartType: chartType,
        chartRadius: MediaQuery.of(context).size.width / 2.2,
        colorList: const [
          Colors.blue,
          Colors.green,
          Colors.red,
          Colors.orange,
          Colors.purple,
        ],
        centerText: localizedTitle,
        legendOptions: const pie.LegendOptions(
          showLegends: true,
          legendPosition: pie.LegendPosition.right,
        ),
        chartValuesOptions: const pie.ChartValuesOptions(
          showChartValues: true,
          showChartValuesOutside: true,
        ),
      ),
    );
  }

  Widget _buildBarChart(Map<String, double> data, String title) {
    final loc = AppLocalizations.of(context)!;
    final localizedTitle =
        title.toLowerCase() == 'expenses'
            ? loc.expenses
            : title.toLowerCase() == 'profits'
            ? loc.profits
            : title;

    final chartData =
        data.entries
            .map((e) => ChartData(_translateTask(e.key, loc), e.value))
            .toList();

    return SizedBox(
      height: 300,
      child: sf.SfCartesianChart(
        title: sf.ChartTitle(text: localizedTitle),
        primaryXAxis: sf.CategoryAxis(),
        primaryYAxis: sf.NumericAxis(
          numberFormat: NumberFormat.compactCurrency(symbol: '€'),
        ),
        series: <sf.ColumnSeries<ChartData, String>>[
          sf.ColumnSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: const Color(0xFF655B40),
            dataLabelSettings: const sf.DataLabelSettings(isVisible: true),
          ),
        ],
        tooltipBehavior: sf.TooltipBehavior(enable: true),
      ),
    );
  }

  Widget _buildLineChart(Map<String, double> data, String title) {
    final loc = AppLocalizations.of(context)!;
    final localizedTitle =
        title.toLowerCase() == 'expenses'
            ? loc.expenses
            : title.toLowerCase() == 'profits'
            ? loc.profits
            : title;

    final chartData =
        data.entries
            .map((e) => ChartData(_translateTask(e.key, loc), e.value))
            .toList();

    return SizedBox(
      height: 300,
      child: sf.SfCartesianChart(
        title: sf.ChartTitle(text: localizedTitle),
        primaryXAxis: sf.CategoryAxis(),
        primaryYAxis: sf.NumericAxis(
          numberFormat: NumberFormat.compactCurrency(symbol: '€'),
        ),
        series: <sf.LineSeries<ChartData, String>>[
          sf.LineSeries<ChartData, String>(
            dataSource: chartData,
            xValueMapper: (ChartData data, _) => data.category,
            yValueMapper: (ChartData data, _) => data.value,
            color: const Color(0xFF655B40),
            markerSettings: const sf.MarkerSettings(isVisible: true),
            dataLabelSettings: const sf.DataLabelSettings(isVisible: true),
          ),
        ],
        tooltipBehavior: sf.TooltipBehavior(enable: true),
      ),
    );
  }

  Widget _buildInfoContainer(String titleKey, List<Widget> children) {
    final loc = AppLocalizations.of(context)!;
    final localizedTitle = _getLocalizedTitle(loc, titleKey);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF655B40),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            localizedTitle,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  String _getLocalizedTitle(AppLocalizations loc, String key) {
    switch (key) {
      case 'summary':
        return loc.summary;
      case 'detailedExpenses':
        return loc.detailedExpenses;
      case 'detailedProfits':
        return loc.detailedProfits;
      case 'fieldWithMostExpenses':
        return loc.fieldWithMostExpenses(_fieldWithMostExpenses);
      case 'fieldWithMostProfits':
        return loc.fieldWithMostProfits(_fieldWithMostProfits);
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;

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
            onPressed:
                () => showDialog(
                  context: context,
                  barrierColor: Colors.black38,
                  builder: (_) => SettingsSidebar(user: widget.user),
                ),
          ),
        ],
      ),
      body: Stack(
        children: [
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
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _showExportOptions = !_showExportOptions;
                            });
                          },
                          icon: const Icon(Icons.download, size: 20),
                          label: Text(loc.export),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF655B40),
                            foregroundColor: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 10),
                        ElevatedButton.icon(
                          onPressed:
                              () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder:
                                      (_) => AnalyticsPage(user: widget.user),
                                ),
                              ),
                          icon: Image.asset(
                            'assets/filters.png',
                            width: 20,
                            height: 20,
                          ),
                          label: Text(loc.filters),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF655B40),
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (_showExportOptions)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          width: 200,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.withOpacity(0.5),
                                spreadRadius: 2,
                                blurRadius: 5,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: const Icon(Icons.picture_as_pdf),
                                title: Text(loc.exportPdf),
                                onTap: () {
                                  _exportToPDF();
                                  setState(() {
                                    _showExportOptions = false;
                                  });
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.grid_on),
                                title: Text(loc.exportExcel),
                                onTap: () {
                                  _exportToExcel();
                                  setState(() {
                                    _showExportOptions = false;
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: const Color(0xFF655B40),
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _currentSeason,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Color(0xFF655B40),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    if (_showExpenses && _expenseData.isNotEmpty) ...[
                      Text(
                        '${loc.totalExpenses}: ${_totalExpenses.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildChart(_expenseData, loc.expenses),
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
                              loc.fieldWithMostExpenses(_fieldWithMostExpenses),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (_expenseBreakdown.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${loc.expenseBreakdown}:',
                                style: const TextStyle(
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
                                        '${_translateTask(e.key, loc)}:',
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
                    ],

                    if (_showProfits && _profitData.isNotEmpty) ...[
                      Text(
                        '${loc.totalProfits}: ${_totalProfits.toStringAsFixed(2)} €',
                        style: const TextStyle(
                          fontSize: 18,
                          color: Color(0xFF655B40),
                        ),
                      ),
                      const SizedBox(height: 30),
                      _buildChart(_profitData, loc.profits),
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
                              loc.fieldWithMostProfits(_fieldWithMostProfits),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              loc.oilSold(_oilKgSold.toStringAsFixed(2)),
                              style: const TextStyle(
                                fontSize: 16,
                                color: Colors.white,
                              ),
                            ),
                            if (_profitData.containsKey('Other')) ...[
                              const SizedBox(height: 8),
                              Text(
                                '${loc.otherProfits}:',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${_profitData['Other']?.toStringAsFixed(2) ?? '0.00'} €',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 30),
                    ],

                    if (_showExpenses && _fieldExpenseDetails.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF655B40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.detailedExpensesByField,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            for (final expenseType in [
                              'Irrigation',
                              'Fertilization',
                              'Spraying',
                              'Other',
                            ])
                              if (_expenseData.containsKey(expenseType)) ...[
                                Text(
                                  '${_translateTask(expenseType, loc)}:',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                ..._fieldExpenseDetails.entries.map((
                                  fieldEntry,
                                ) {
                                  final value =
                                      fieldEntry.value[expenseType] ?? 0;
                                  return value > 0
                                      ? Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 2,
                                        ),
                                        child: Row(
                                          children: [
                                            Text(
                                              '${fieldEntry.key}:',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              '${value.toStringAsFixed(2)} €',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      )
                                      : const SizedBox.shrink();
                                }).toList(),
                                const SizedBox(height: 8),
                              ],
                          ],
                        ),
                      ),

                    if (_showProfits && _fieldProfitDetails.isNotEmpty)
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF655B40),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              loc.detailedProfitsByField,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            for (final profitType in [
                              'Oil Sold',
                              'Sacks Sold',
                              'Other',
                            ])
                              ..._fieldProfitDetails.entries.map((fieldEntry) {
                                final value = fieldEntry.value[profitType] ?? 0;
                                return value > 0
                                    ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${fieldEntry.key}:',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            profitType == 'Oil Sold'
                                                ? '${value.toStringAsFixed(2)} kg'
                                                : profitType == 'Sacks Sold'
                                                ? '${value.toInt()} ${loc.sacks}'
                                                : '${value.toStringAsFixed(2)} €',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : const SizedBox.shrink();
                              }).toList(),
                            const SizedBox(height: 4),
                            ..._fieldProfitDetails.entries.map((fieldEntry) {
                              final sacksSold =
                                  fieldEntry.value['sacksSold'] ?? 0;
                              return sacksSold > 0
                                  ? Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 2,
                                    ),
                                    child: Row(
                                      children: [
                                        Text(
                                          '${fieldEntry.key}:',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const Spacer(),
                                        Text(
                                          '${sacksSold.toInt()} ${loc.sacks}',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                  : const SizedBox.shrink();
                            }).toList(),
                            if (_profitData.containsKey('Other')) ...[
                              const SizedBox(height: 4),
                              ..._fieldProfitDetails.entries.map((fieldEntry) {
                                final otherProfits =
                                    fieldEntry.value['otherProfits'] ?? 0;
                                return otherProfits > 0
                                    ? Padding(
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 2,
                                      ),
                                      child: Row(
                                        children: [
                                          Text(
                                            '${fieldEntry.key}:',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            '${otherProfits.toStringAsFixed(2)} €',
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                    : const SizedBox.shrink();
                              }).toList(),
                            ],
                          ],
                        ),
                      ),

                    Container(
                      width: double.infinity,
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF655B40),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            loc.summary,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${loc.totalExpenses}:',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_totalExpenses.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${loc.totalProfits}:',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_totalProfits.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${loc.netBalance}:',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  '${_netProfit.toStringAsFixed(2)} €',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 75),
                  ],
                ),
              ),
        ],
      ),
      bottomNavigationBar: Container(
        color: const Color(0xFF655B40),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              context,
              'assets/field.png',
              AppLocalizations.of(context)!.fields,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FieldsScreen(user: widget.user),
                  ),
                );
              },
            ),
            _buildNavItem(
              context,
              'assets/expensesfooter.png',
              AppLocalizations.of(context)!.expenses,
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AllFieldsExpensesScreen(user: widget.user),
                  ),
                );
              },
            ),
            _buildNavItem(
              context,
              'assets/stats.png',
              AppLocalizations.of(context)!.analytics,
              () {},
            ),
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

class ChartData {
  final String category;
  final double value;

  ChartData(this.category, this.value);
}
