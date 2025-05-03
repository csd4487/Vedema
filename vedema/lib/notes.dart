import 'dart:convert';
import 'package:flutter/material.dart';
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
        Uri.parse('http://192.168.1.2:5000/api/getNotes'),
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
        throw Exception('Failed to load notes');
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
        Uri.parse('http://10.0.2.2:5000/api/sendEmail'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': widget.user.email,
          'note': note['text'],
          'date': note['date'],
        }),
      );

      if (response.statusCode == 200) {
        print("Email sent successfully.");
      } else {
        print("Failed to send email.");
      }
    } catch (e) {
      print("Error sending email: $e");
    }
  }

  Future<void> _confirmDeleteNote(BuildContext context, dynamic note) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder:
          (_) => AlertDialog(
            title: const Text("Confirm Deletion"),
            content: const Text("Are you sure you want to delete this note?"),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text("Cancel"),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text("Yes"),
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
        Uri.parse('http://192.168.1.2:5000/api/deleteNote'),
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
        print("Note deleted");
      } else {
        print("Failed to delete note");
      }
    } catch (e) {
      print("Delete error: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Notes", style: TextStyle(color: Colors.white)),
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
              ? const Padding(
                padding: EdgeInsets.only(top: 45),
                child: Text(
                  'You do not have any notes yet, click the + button on the bottom right to add a note',
                  style: TextStyle(color: Color(0xFF655B40), fontSize: 18),
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        right: 10.0,
                                      ),
                                      child: Text(
                                        note['text'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                        ),
                                      ),
                                    ),
                                  ),
                                  Transform.translate(
                                    offset: const Offset(10, -10),
                                    child: IconButton(
                                      icon: Image.asset(
                                        'assets/delete.png',
                                        width: 25,
                                        height: 25,
                                      ),
                                      onPressed:
                                          () =>
                                              _confirmDeleteNote(context, note),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                note['date'],
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
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
