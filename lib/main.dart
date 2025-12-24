import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;
import 'package:google_mlkit_translation/google_mlkit_translation.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';
import 'package:permission_handler/permission_handler.dart';

// --- MAIN ENTRY POINT ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const LectureLiveApp());
}

class LectureLiveApp extends StatelessWidget {
  const LectureLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LectureLive (Free)',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
      ),
      home: const RoleSelectionScreen(),
    );
  }
}

// --- SCREEN 1: ROLE SELECTION ---
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.blue.shade50,
            ],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Header Section
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.indigo, Colors.blue],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.indigo.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.translate, size: 72, color: Colors.white),
                        const SizedBox(height: 16),
                        const Text(
                          'LectureLive',
                          style: TextStyle(
                            fontSize: 36,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Real-Time Lecture Translation',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 56),
                  
                  // Role Selection Cards
                  _buildRoleCard(
                    context,
                    title: "Teacher",
                    subtitle: "Share lectures in real-time",
                    icon: Icons.mic_rounded,
                    color: Colors.blue,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const TeacherScreen()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _buildRoleCard(
                    context,
                    title: "Student",
                    subtitle: "Receive translated lectures",
                    icon: Icons.school_rounded,
                    color: Colors.teal,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const StudentScreen()),
                    ),
                  ),
                  
                  const SizedBox(height: 40),
                  
                  // Footer Info
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.indigo.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.indigo.shade400, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Translations run locally on your device',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.indigo.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [color, color.withOpacity(0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 36, color: Colors.white),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward_rounded, color: Colors.white.withOpacity(0.7)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// --- SCREEN 2: TEACHER INTERFACE (Audio -> Firestore) ---
class TeacherScreen extends StatefulWidget {
  const TeacherScreen({super.key});

  @override
  State<TeacherScreen> createState() => _TeacherScreenState();
}

class _TeacherScreenState extends State<TeacherScreen> {
  late stt.SpeechToText _speech;
  bool _isListening = false;
  String _lectureId = '';
  String _lastWords = '';
  final ScrollController _scrollController = ScrollController();
  final List<String> _transcriptLog = [];
  final Set<String> _uploadedTexts = {}; // Track uploaded content to avoid duplicates
  String _errorMessage = '';
  final TextEditingController _mockTextController = TextEditingController();
  bool _useTypingMode = false; // Toggle between typing and speaking

  @override
  void initState() {
    super.initState();
    _speech = stt.SpeechToText();
    // Generate a simple 6-char ID
    _lectureId = const Uuid().v4().substring(0, 6).toUpperCase();
    _useTypingMode = false;
  }

  Future<void> _listen() async {
    if (_useTypingMode) {
      // Typing mode
      if (!_isListening) {
        setState(() => _isListening = true);
        _showWebMockInputDialog();
      } else {
        setState(() => _isListening = false);
      }
      return;
    }

    // Speaking mode (unified for all platforms)
    // Check permissions on all platforms
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      _showErrorSnackBar("Microphone permission denied");
      return;
    }

    if (!_isListening) {
      bool available = await _speech.initialize(
        onStatus: (val) {
          print('Status: $val');
          // Restart listening if it stopped while still recording
          if (val == 'notListening' && _isListening) {
            _restartListening();
          }
        },
        onError: (val) {
          print('Error: $val');
          _showErrorSnackBar("Listening error: $val");
        },
      );

      if (available) {
        setState(() {
          _isListening = true;
          _errorMessage = '';
        });
        _startListening();
      } else {
        _showErrorSnackBar("Speech recognition not available");
        setState(() => _errorMessage = "Speech recognition not available");
      }
    } else {
      setState(() => _isListening = false);
      _speech.stop();
    }
  }

  void _showWebMockInputDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Type Text"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Enter text to simulate speech:"),
            const SizedBox(height: 16),
            TextField(
              controller: _mockTextController,
              decoration: const InputDecoration(
                hintText: "Type something...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() => _isListening = false);
            },
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              if (_mockTextController.text.isNotEmpty) {
                _uploadTranscript(_mockTextController.text);
                setState(() {
                  _transcriptLog.add(_mockTextController.text);
                  _mockTextController.clear();
                });
                _scrollToBottom();
                Navigator.pop(context);
              }
            },
            child: const Text("Submit"),
          ),
        ],
      ),
    );
  }

  void _startListening() {
    _speech.listen(
      onResult: (val) {
        setState(() {
          _lastWords = val.recognizedWords;
        });

        // Upload BOTH partial and final results in real-time
        if (val.recognizedWords.isNotEmpty) {
          final String text = val.recognizedWords.trim();
          
          // Create a unique ID based on text + timestamp to allow similar phrases
          final String docId = '${DateTime.now().millisecondsSinceEpoch}_${text.hashCode}';
          
          // Only upload if we haven't uploaded this exact variant recently
          if (!_uploadedTexts.contains(docId)) {
            _uploadedTexts.add(docId);
            _uploadTranscript(text, isFinal: val.finalResult);
            
            // Only add to local log on FINAL result to avoid spam in UI
            if (val.finalResult) {
              setState(() {
                _transcriptLog.add(text);
                _lastWords = '';
              });
              _scrollToBottom();
            }
          }
        }
      },
      listenFor: const Duration(minutes: 15),
      pauseFor: const Duration(seconds: 30),
      partialResults: true,
    );
  }

  void _restartListening() {
    if (_isListening && !_useTypingMode) {
      _speech.stop();
      Future.delayed(const Duration(milliseconds: 100), () {
        if (_isListening && !_useTypingMode && mounted) {
          _startListening();
        }
      });
    }
  }

  Future<void> _uploadTranscript(String text, {bool isFinal = true}) async {
    if (text.trim().isEmpty) return;
    
    try {
      String normalizedId = _lectureId.trim().toUpperCase();
      
      await FirebaseFirestore.instance
          .collection('lectures')
          .doc(normalizedId)
          .collection('original')
          .add({
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'isFinal': isFinal,
      });
      
      print('Uploaded${isFinal ? " (final)" : " (partial)"}: $text');
    } catch (e) {
      print("Upload error: $e");
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _autoScrollIfNeeded();
    }
  }

  void _autoScrollIfNeeded() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 100) {
        _scrollController.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    try {
      _speech.cancel();
    } catch (e) {
      print('Error canceling speech: $e');
    }
    _scrollController.dispose();
    _mockTextController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Teacher Mode"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(85),
          child: Column(
            children: [
              Container(
                color: Colors.blue[50],
                padding: const EdgeInsets.all(8),
                child: Text("Lecture ID: $_lectureId", 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
              ),
              Container(
                color: Colors.blue[50],
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    const Text("Mode: ", style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: SegmentedButton<bool>(
                        segments: const [
                          ButtonSegment(
                            value: false,
                            label: Text("Speak"),
                            icon: Icon(Icons.mic),
                          ),
                          ButtonSegment(
                            value: true,
                            label: Text("Type"),
                            icon: Icon(Icons.edit),
                          ),
                        ],
                        selected: {_useTypingMode},
                        onSelectionChanged: (Set<bool> newSelection) {
                          setState(() {
                            _useTypingMode = newSelection.first;
                            if (_isListening) {
                              _isListening = false;
                              if (!_useTypingMode) {
                                _speech.stop();
                              }
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _listen,
        backgroundColor: _isListening ? Colors.red : Colors.blue,
        icon: Icon(_isListening 
          ? Icons.stop 
          : (_useTypingMode ? Icons.edit : Icons.mic)),
        label: Text(_isListening 
          ? 'Stop' 
          : (_useTypingMode ? 'Type Text' : 'Start Speaking')),
      ),
      body: _errorMessage.isNotEmpty
          ? Center(
              child: Text(
                _errorMessage,
                style: const TextStyle(color: Colors.red, fontSize: 16),
                textAlign: TextAlign.center,
              ),
            )
          : Column(
              children: [
                if (kIsWeb && !_useTypingMode)
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Colors.blue[50],
                    child: Row(
                      children: [
                        const Icon(Icons.mic, color: Colors.blue),
                        const SizedBox(width: 8),
                        const Expanded(
                          child: Text(
                            "Use your browser microphone to speak or switch to 'Type' for text input",
                            style: TextStyle(color: Colors.blue, fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                Expanded(
                  child: _transcriptLog.isEmpty && _lastWords.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.mic_off, size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 16),
                              Text(
                                'No speech detected yet',
                                style: TextStyle(color: Colors.grey[600], fontSize: 16),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _useTypingMode ? 'Start typing to broadcast' : 'Start speaking to broadcast',
                                style: TextStyle(color: Colors.grey[500], fontSize: 14),
                              ),
                            ],
                          ),
                        )
                      : SingleChildScrollView(
                          controller: _scrollController,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.05),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Icon(Icons.record_voice_over,
                                              color: Theme.of(context).primaryColor, size: 20),
                                          const SizedBox(width: 8),
                                          const Text(
                                            'Live Transcript',
                                            style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          const Spacer(),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: Colors.red,
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              'Live',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Broadcasting to students',
                                        style: TextStyle(
                                          color: Colors.grey[600],
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      SelectableText(
                                        '${_transcriptLog.join(' ')}${_lastWords.isNotEmpty ? ' $_lastWords' : ''}',
                                        style: TextStyle(
                                          fontSize: 16,
                                          height: 1.8,
                                          color: Colors.grey[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
    );
  }
}

// --- SCREEN 3: STUDENT SETUP ---
class StudentScreen extends StatefulWidget {
  const StudentScreen({super.key});

  @override
  State<StudentScreen> createState() => _StudentScreenState();
}

class _StudentScreenState extends State<StudentScreen> {
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  TranslateLanguage? _selectedLang;
  TranslateLanguage? _sourceLanguage;

  @override
  void dispose() {
    _idController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Join a Class"),
        elevation: 0,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.indigo.shade50,
              Colors.teal.shade50,
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32),
            child: Column(
              children: [
                // Header Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.indigo.shade200),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.teal.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(Icons.school_rounded, color: Colors.teal, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Enter Lecture Details",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Fill in your information to join the class",
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Student Name Input
                _buildInputField(
                  label: "Your Name (Optional)",
                  controller: _nameController,
                  icon: Icons.person_rounded,
                  hint: "Enter your name",
                ),
                const SizedBox(height: 20),

                // Lecture ID Input
                _buildInputField(
                  label: "Lecture ID",
                  controller: _idController,
                  icon: Icons.confirmation_number_rounded,
                  hint: "6-character ID",
                  textCapitalization: TextCapitalization.characters,
                  isRequired: true,
                ),
                const SizedBox(height: 28),

                // Language Selection Section
                Text(
                  "Language Settings",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
                const SizedBox(height: 16),

                // Source Language Dropdown
                _buildLanguageDropdown(
                  label: "Source Language",
                  icon: Icons.language_rounded,
                  value: _sourceLanguage,
                  items: [
                    TranslateLanguage.english,
                    TranslateLanguage.spanish,
                    TranslateLanguage.french,
                    TranslateLanguage.german,
                    TranslateLanguage.hindi,
                    TranslateLanguage.bengali,
                    TranslateLanguage.gujarati,
                    TranslateLanguage.kannada,
                    TranslateLanguage.marathi,
                    TranslateLanguage.tamil,
                    TranslateLanguage.telugu,
                    TranslateLanguage.urdu,
                  ],
                  onChanged: (val) => setState(() => _sourceLanguage = val),
                ),
                const SizedBox(height: 16),

                // Target Language Dropdown
                _buildLanguageDropdown(
                  label: "Target Language",
                  icon: Icons.translate_rounded,
                  value: _selectedLang,
                  items: [
                    TranslateLanguage.spanish,
                    TranslateLanguage.hindi,
                    TranslateLanguage.french,
                    TranslateLanguage.german,
                    TranslateLanguage.chinese,
                    TranslateLanguage.japanese,
                    TranslateLanguage.bengali,
                    TranslateLanguage.gujarati,
                    TranslateLanguage.kannada,
                    TranslateLanguage.marathi,
                    TranslateLanguage.tamil,
                    TranslateLanguage.telugu,
                    TranslateLanguage.urdu,
                  ],
                  onChanged: (val) => setState(() => _selectedLang = val),
                ),
                const SizedBox(height: 36),

                // Join Button
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    icon: Icon(
                      (_selectedLang != null && _sourceLanguage != null && _idController.text.isNotEmpty)
                          ? Icons.arrow_forward_rounded
                          : Icons.lock_rounded,
                      size: 24,
                    ),
                    label: const Text(
                      "Join Class",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: (_selectedLang != null && _sourceLanguage != null && _idController.text.isNotEmpty)
                          ? Colors.teal
                          : Colors.grey.shade400,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      elevation: 4,
                    ),
                    onPressed: (_selectedLang != null && _sourceLanguage != null && _idController.text.isNotEmpty)
                        ? () {
                            String normalizedId = _idController.text.trim().toUpperCase();

                            if (normalizedId.length != 6) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Lecture ID must be exactly 6 characters"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => OfflineTranslationView(
                                  lectureId: normalizedId,
                                  studentName: _nameController.text.trim().isNotEmpty
                                      ? _nameController.text.trim()
                                      : "Anonymous",
                                  sourceLanguage: _sourceLanguage!,
                                  targetLanguage: _selectedLang!,
                                ),
                              ),
                            );
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    required String hint,
    TextCapitalization textCapitalization = TextCapitalization.none,
    bool isRequired = false,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        decoration: InputDecoration(
          labelText: isRequired ? "$label *" : label,
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.teal),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
      ),
    );
  }

  Widget _buildLanguageDropdown({
    required String label,
    required IconData icon,
    required TranslateLanguage? value,
    required List<TranslateLanguage> items,
    required Function(TranslateLanguage?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: DropdownButtonFormField<TranslateLanguage>(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Colors.teal, width: 2),
          ),
          prefixIcon: Icon(icon, color: Colors.teal),
          contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        ),
        value: value,
        items: items.map((lang) {
          return DropdownMenuItem(
            value: lang,
            child: Text(lang.name.toUpperCase()),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }
}

// --- SCREEN 4: OFFLINE TRANSLATOR (Firestore -> ML Kit) ---
class OfflineTranslationView extends StatefulWidget {
  final String lectureId;
  final String studentName;
  final TranslateLanguage sourceLanguage;
  final TranslateLanguage targetLanguage;

  const OfflineTranslationView({
    super.key, 
    required this.lectureId,
    required this.studentName,
    required this.sourceLanguage,
    required this.targetLanguage,
  });

  @override
  State<OfflineTranslationView> createState() => _OfflineTranslationViewState();
}

class _OfflineTranslationViewState extends State<OfflineTranslationView> {
  late OnDeviceTranslator _translator;
  bool _isModelReady = false;
  String _statusMessage = "Initializing...";
  double _downloadProgress = 0.0;
  
  // FIXED: Store translations by DOC ID, not by text content
  final Map<String, String> _translations = {}; // docId -> TranslatedText
  final Set<String> _translatingIds = {}; // docIds currently being translated to prevent dupes
  
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _initializeTranslator();
  }

  Future<bool> _checkModelDownloaded(TranslateLanguage lang) async {
    try {
      final modelManager = OnDeviceTranslatorModelManager();
      return await modelManager.isModelDownloaded(lang.bcpCode);
    } catch (e) {
      print("Error checking ${lang.name} model: $e");
      return false;
    }
  }

  Future<void> _initializeTranslator() async {
    final modelManager = OnDeviceTranslatorModelManager();
    
    setState(() => _statusMessage = "Checking language packs...");

    try {
      bool isSourceDownloaded = await _checkModelDownloaded(widget.sourceLanguage);
      bool isTargetDownloaded = await _checkModelDownloaded(widget.targetLanguage);

      if (!isSourceDownloaded || !isTargetDownloaded) {
        setState(() => _statusMessage = "Downloading language model (approx 30MB)...");
        if (!isSourceDownloaded) {
          try {
            await modelManager.downloadModel(widget.sourceLanguage.bcpCode);
            setState(() => _downloadProgress = 50.0);
          } catch (e) {
            print("Error downloading source model: $e");
          }
        }
        if (!isTargetDownloaded) {
          try {
            await modelManager.downloadModel(widget.targetLanguage.bcpCode);
            setState(() => _downloadProgress = 100.0);
          } catch (e) {
            print("Error downloading target model: $e");
          }
        }
      }

      _translator = OnDeviceTranslator(
        sourceLanguage: widget.sourceLanguage,
        targetLanguage: widget.targetLanguage,
      );

      setState(() {
        _isModelReady = true;
        _statusMessage = "Ready";
        _downloadProgress = 100.0;
      });
    } catch (e) {
      setState(() => _statusMessage = "Error loading model: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to initialize: $e"), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _translateText(String docId, String text) async {
    // If empty text, nothing to translate
    if (text.trim().isEmpty) return;
    
    try {
      String translated;
      
      if (kIsWeb) {
        // Mock for web
        translated = "[${widget.targetLanguage.name.toUpperCase()}] $text";
      } else {
        translated = await _translator.translateText(text);
      }
      
      if (mounted) {
        setState(() {
          _translations[docId] = translated;
          _translatingIds.remove(docId); // Done translating
        });
        _autoScrollIfNeeded();
      }
    } catch (e) {
      print("Translation error for doc $docId: $e");
      if (mounted) {
        // Remove from tracking to allow retry on next pass or user action
        setState(() {
          _translatingIds.remove(docId);
        });
      }
    }
  }

  void _autoScrollIfNeeded() {
    Future.delayed(const Duration(milliseconds: 50), () {
      if (!_scrollController.hasClients) return;
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 100) {
        _scrollController.jumpTo(pos.maxScrollExtent);
      }
    });
  }

  @override
  void dispose() {
    if (!kIsWeb && _isModelReady) {
      try {
        _translator.close();
      } catch (e) {
        print("Error closing translator: $e");
      }
    }
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isModelReady) {
      return Scaffold(
        appBar: AppBar(title: const Text("Preparing Translation")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 20),
              Text(_statusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              if (kIsWeb)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.orange[100],
                    border: Border.all(color: Colors.orange),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    "⚠️ Web Testing Mode: Using mock translations",
                    style: TextStyle(color: Colors.orange, fontSize: 14),
                    textAlign: TextAlign.center,
                  ),
                ),
              if (_downloadProgress > 0 && _downloadProgress < 100)
                Column(
                  children: [
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: _downloadProgress / 100,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text("${_downloadProgress.toStringAsFixed(0)}%"),
                  ],
                ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.targetLanguage.name.toUpperCase()} (${widget.studentName})"),
        actions: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(child: Text(widget.lectureId, style: const TextStyle(fontWeight: FontWeight.bold))),
          )
        ],
      ),
      body: kIsWeb
          ? Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  color: Colors.orange[100],
                  child: Row(
                    children: [
                      const Icon(Icons.info, color: Colors.orange),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "Testing Mode: Mock translations shown",
                          style: TextStyle(color: Colors.orange, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: _buildTranslationListWidget(),
                ),
              ],
            )
          : _buildTranslationListWidget(),
    );
  }

  Widget _buildTranslationListWidget() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lectures')
          .doc(widget.lectureId)
          .collection('original')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        
        if (snapshot.hasError) {
          return Center(
            child: Text("Error: ${snapshot.error}", style: const TextStyle(color: Colors.red)),
          );
        }
        
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final allDocs = snapshot.data?.docs ?? [];
        final List<QueryDocumentSnapshot> visibleDocs = [];

        // Filter out intermediate partial results to prevent repeated/stuttering output.
        // We keep a document if:
        // 1. It is marked as 'isFinal' (a complete sentence/segment).
        // 2. OR it is the very last document in the stream (the current live partial).
        for (int i = 0; i < allDocs.length; i++) {
          final doc = allDocs[i];
          final data = doc.data() as Map<String, dynamic>?;
          final bool isFinal = data?['isFinal'] == true;
          
          if (isFinal || i == allDocs.length - 1) {
             visibleDocs.add(doc);
          }
        }

        // 1. Trigger translations for VISIBLE documents only
        WidgetsBinding.instance.addPostFrameCallback((_) {
          for (var doc in visibleDocs) {
            final docId = doc.id;
            // If we haven't translated it AND we aren't currently translating it
            if (!_translations.containsKey(docId) && !_translatingIds.contains(docId)) {
              final data = doc.data() as Map<String, dynamic>?;
              final originalText = data?['text'] as String? ?? '';
              if (originalText.isNotEmpty) {
                // Mark as in-progress synchronously to prevent duplicate calls in next frame
                _translatingIds.add(docId);
                _translateText(docId, originalText);
              }
            }
          }
        });

        // 2. Reconstruct the full text from VISIBLE documents
        final String continuousTranslation = visibleDocs
            .map((doc) => _translations[doc.id] ?? '') // Get translation or empty if loading
            .where((text) => text.isNotEmpty)
            .join(' ');

        if (continuousTranslation.isEmpty && visibleDocs.isEmpty) {
           return Center(
             child: Column(
               mainAxisAlignment: MainAxisAlignment.center,
               children: [
                 Icon(Icons.hearing, size: 48, color: Colors.grey),
                 const SizedBox(height: 16),
                 const Text("Waiting for teacher to speak..."),
               ],
             ),
           );
        }

        return SingleChildScrollView(
          controller: _scrollController,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Icon(
                          Icons.translate_rounded,
                          color: Theme.of(context).primaryColor,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Live Translation",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                widget.targetLanguage.name.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 3,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                "Live",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    
                    // Divider
                    Container(
                      height: 1,
                      color: Colors.grey.shade200,
                    ),
                    const SizedBox(height: 20),
                    
                    // Continuous Translation Text
                    SelectableText(
                      continuousTranslation,
                      style: const TextStyle(
                        fontSize: 18,
                        height: 1.8,
                        color: Colors.black87,
                      ),
                    ),
                    
                    // Loading indicator for pending translations
                    if (_translatingIds.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.green.shade400),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Translating live...",
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.green.shade600,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}