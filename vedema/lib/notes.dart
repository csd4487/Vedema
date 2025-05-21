import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:http/http.dart' as http;
import 'user.dart';
import 'addnewnote.dart';

class NotesPage extends StatefulWidget {
  final User user;

  const NotesPage({super.key, required this.user});

  @override
  _NotesPageState createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  List<dynamic> notes = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadNotes();
  }

  Future<void> loadNotes() async {
    setState(() {
      isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/getNotes'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final List<dynamic> notesList = jsonDecode(response.body)['notes'];

        notesList.sort((a, b) {
          try {
            DateTime dateA = DateTime.parse(a['date']);
            DateTime dateB = DateTime.parse(b['date']);
            return dateB.compareTo(dateA);
          } catch (e) {
            return 0;
          }
        });

        _checkAndSendEmails(notesList);

        setState(() {
          notes = notesList;
          isLoading = false;
        });
      } else {
        throw Exception(AppLocalizations.of(context)!.failedToLoadNotes);
      }
    } catch (e) {
      print('Error: $e');
      setState(() {
        isLoading = false;
      });
    }
  }

  void _checkAndSendEmails(List<dynamic> notesList) {
    DateTime today = DateTime.now();

    for (var note in notesList) {
      DateTime noteDate = DateTime.parse(note['date']);
      if (noteDate.year == today.year &&
          noteDate.month == today.month &&
          noteDate.day == today.day &&
          note['emailSent'] == false) {
        _sendEmail(note);
      }
    }
  }

  Future<void> _sendEmail(dynamic note) async {
    try {
      final response = await http.post(
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/sendEmail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'note': note['text'],
          'date': note['date'],
        }),
      );

      if (response.statusCode == 200) {
        print(AppLocalizations.of(context)!.emailSent);
      } else {
        print(AppLocalizations.of(context)!.failedToSendEmail);
      }
    } catch (e) {
      print("${AppLocalizations.of(context)!.errorSendingEmail}: $e");
    }
  }

  Future<void> _confirmDeleteNote(BuildContext context, dynamic note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: Text(AppLocalizations.of(context)!.confirmDeletion),
            content: Text(AppLocalizations.of(context)!.deleteConfirmation),
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
      _deleteNote(note);
    }
  }

  Future<void> _deleteNote(dynamic note) async {
    try {
      final response = await http.post(
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/deleteNote'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'text': note['text'],
          'date': note['date'],
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          notes.remove(note);
        });
        print(AppLocalizations.of(context)!.noteDeleted);
      } else {
        print(AppLocalizations.of(context)!.failedToDelete);
      }
    } catch (e) {
      print("${AppLocalizations.of(context)!.deleteError}: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.notes, style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF655B40),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : notes.isEmpty
              ? Padding(
                padding: const EdgeInsets.only(top: 45),
                child: Text(
                  localizations.noNotesMessage,
                  style: TextStyle(
                    color: const Color(0xFF655B40),
                    fontSize: 18,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  children: [
                    const SizedBox(height: 25),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: notes.length,
                      itemBuilder: (context, index) {
                        final note = notes[index];
                        return Container(
                          margin: const EdgeInsets.only(bottom: 20),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF4A5C4A),
                                const Color(0xFF655B40).withOpacity(0.7),
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note['text'],
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                note['date'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: IconButton(
                                  icon: Image.asset(
                                    'assets/delete.png',
                                    width: 25,
                                    height: 25,
                                  ),
                                  onPressed:
                                      () => _confirmDeleteNote(context, note),
                                ),
                              ),
                            ],
                          ),
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
              builder: (context) => AddNewNotePage(user: widget.user),
            ),
          );
          if (mounted) {
            loadNotes();
          }
        },
        backgroundColor: const Color(0xFF655B40),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
