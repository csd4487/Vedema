import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import 'notes.dart';
import 'addnewnote.dart';
import 'user.dart';
import 'separatefield.dart';

class VoiceCommandHandler {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;

  final StreamController<String> _textController =
      StreamController<String>.broadcast();
  final StreamController<bool> _listeningController =
      StreamController<bool>.broadcast();

  Stream<String> get textStream => _textController.stream;
  Stream<bool> get listeningStream => _listeningController.stream;

  Future<void> toggleListening(BuildContext context, User user) async {
    if (_isListening) {
      _stopListening();
    } else {
      await _startListening(context, user);
    }
  }

  Future<void> _startListening(BuildContext context, User user) async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _textController.add('Microphone permission denied');
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _stopListening();
        }
      },
      onError: (error) {
        _textController.add('Speech error: ${error.errorMsg}');
      },
    );

    if (!available) {
      _textController.add('Speech not available');
      return;
    }

    _isListening = true;
    _listeningController.add(true);

    _speech.listen(
      onResult: (result) {
        String recognized = result.recognizedWords;
        print("Speech result: $recognized");
        _textController.add(recognized);

        if (result.finalResult) {
          print("Final result received: $recognized");
          _handleCommand(context, recognized.toLowerCase(), user);
        }
      },
      localeId: 'en_US',
      listenMode: stt.ListenMode.dictation,
      partialResults: true,
      cancelOnError: false,
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 3),
    );
  }

  void _stopListening() {
    _speech.stop();
    _isListening = false;
    _listeningController.add(false);
  }

  void _handleCommand(BuildContext context, String command, User user) {
    if (command.contains('add new note')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddNewNotePage(user: user)),
      );
    } else if (command.contains('notes')) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotesPage(user: user)),
      );
    } else {
      _fetchAndNavigateToField(context, command, user);
    }
  }

  Future<void> _fetchAndNavigateToField(
    BuildContext context,
    String command,
    User user,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.2:5000/api/getFields'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> fieldsData = data['fields'];

        final List<Field> fields =
            fieldsData.map((f) {
              return Field(
                f['location'] ?? '',
                (f['size'] ?? 0).toDouble(),
                f['oliveNo'] ?? 0,
                (f['cubics'] ?? 0).toDouble(),
                (f['price'] ?? 0).toDouble(),
                f['species'] ?? '',
              );
            }).toList();

        Field? matchedField = fields.firstWhereOrNull(
          (field) => field.location.toLowerCase() == command.toLowerCase(),
        );

        if (matchedField != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => SeparateFieldScreen(field: matchedField, user: user),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('No matching field found for: $command')),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to fetch fields')));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
    }
  }
}
