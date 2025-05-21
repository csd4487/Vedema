import 'dart:async';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    final loc = AppLocalizations.of(context)!;
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _textController.add(loc.microphonePermissionDenied);
      return;
    }

    bool available = await _speech.initialize(
      onStatus: (status) {
        if (status == 'notListening' || status == 'done') {
          _stopListening();
        }
      },
      onError: (error) {
        _textController.add("${loc.speechError}: ${error.errorMsg}");
      },
    );

    if (!available) {
      _textController.add(loc.speechNotAvailable);
      return;
    }

    _isListening = true;
    _listeningController.add(true);

    final isGreek = Localizations.localeOf(context).languageCode == 'el';
    final localeId = isGreek ? 'el_GR' : 'en_US';

    _speech.listen(
      onResult: (result) {
        String recognized = result.recognizedWords;
        _textController.add(recognized);

        if (result.finalResult) {
          _handleCommand(context, recognized.toLowerCase(), user, loc);
        }
      },
      localeId: localeId,
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

  void _handleCommand(
    BuildContext context,
    String command,
    User user,
    AppLocalizations loc,
  ) {
    if (command.contains(loc.voiceAddNote.toLowerCase())) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AddNewNotePage(user: user)),
      );
    } else if (command.contains(loc.voiceNotes.toLowerCase())) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => NotesPage(user: user)),
      );
    } else {
      _fetchAndNavigateToField(context, command, user, loc);
    }
  }

  Future<void> _fetchAndNavigateToField(
    BuildContext context,
    String command,
    User user,
    AppLocalizations loc,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('https://94b6-79-131-87-183.ngrok-free.app/api/getFields'),
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
            SnackBar(content: Text("${loc.noFieldMatch}: $command")),
          );
        }
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(loc.failedToFetchFields)));
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("${loc.error}: ${e.toString()}")));
    }
  }
}
