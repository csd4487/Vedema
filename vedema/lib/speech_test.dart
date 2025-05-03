import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class SpeechTestScreen extends StatefulWidget {
  const SpeechTestScreen({super.key});

  @override
  State<SpeechTestScreen> createState() => _SpeechTestScreenState();
}

class _SpeechTestScreenState extends State<SpeechTestScreen> {
  final stt.SpeechToText _speech = stt.SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  String _status = 'idle';

  @override
  void initState() {
    super.initState();
    _initSpeech();
  }

  Future<void> _initSpeech() async {
    final status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      setState(() {
        _status = 'Microphone permission denied';
      });
      return;
    }

    final available = await _speech.initialize(
      onStatus: (val) {
        setState(() {
          _status = val;
        });
        print('Speech status: $val');
        if (val == 'notListening' || val == 'done') {
          _stopListening();
        }
      },
      onError: (err) {
        setState(() {
          _status = 'Error: ${err.errorMsg}';
        });
        print('Speech error: $err');
      },
    );

    if (!available) {
      setState(() {
        _status = 'Speech recognition not available';
      });
    }
  }

  void _startListening() {
    _speech.listen(
      onResult: (val) {
        setState(() {
          _lastWords = val.recognizedWords;
        });
        print('Recognized: ${val.recognizedWords}');
      },
      listenFor: const Duration(seconds: 10),
      pauseFor: const Duration(seconds: 5),
      partialResults: true,
      localeId: 'en_US',
    );
    setState(() {
      _isListening = true;
      _status = 'Listening...';
    });
  }

  void _stopListening() {
    _speech.stop();
    setState(() {
      _isListening = false;
      _status = 'Stopped';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Speech Test')),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            Text('Status: $_status', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Text(
              'Recognized: $_lastWords',
              style: const TextStyle(fontSize: 20, color: Colors.black87),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: _isListening ? _stopListening : _startListening,
              child: Text(_isListening ? 'Stop Listening' : 'Start Listening'),
            ),
          ],
        ),
      ),
    );
  }
}
