import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'addnewfield.dart';
import 'userhomepage.dart';
import 'user.dart';

class FieldsScreen extends StatefulWidget {
  final User user;

  const FieldsScreen({super.key, required this.user});

  @override
  FieldsScreenState createState() => FieldsScreenState();
}

class FieldsScreenState extends State<FieldsScreen> {
  List<Field> _fields = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFields();
  }

  Future<void> _loadFields() async {
    try {
      final response = await http.post(
        Uri.parse('http://localhost:5000/api/getFields'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': widget.user.email}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> fieldsData = data['fields'];

        setState(() {
          _fields =
              fieldsData
                  .map(
                    (field) => Field(
                      field['location'],
                      field['size']?.toDouble() ?? 0.0,
                      field['oliveNo'] ?? 0,
                      field['cubics']?.toDouble() ?? 0.0,
                      field['price']?.toDouble() ?? 0.0,
                    ),
                  )
                  .toList();
          _isLoading = false;
        });

        widget.user.fields = _fields;
      } else {
        throw Exception('Failed to load fields');
      }
    } catch (error) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error loading fields: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF655B40),
        title: const Text('Fields', style: TextStyle(color: Colors.white)),
        automaticallyImplyLeading: false,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 25),
                      _fields.isEmpty
                          ? const Center(
                            child: Text(
                              'You do not have any fields yet, click the + button on the bottom right to add your fields',
                              style: TextStyle(
                                fontSize: 18,
                                color: Color(0xFF655B40),
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                          : ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _fields.length,
                            itemBuilder: (context, index) {
                              final field = _fields[index];
                              return Column(
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(bottom: 25),
                                    padding: const EdgeInsets.all(15),
                                    height: 150,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(10),
                                      gradient: LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: [
                                          Color(0xFF5A6E3A),
                                          Color(0xFF655B40),
                                        ],
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color.fromARGB(64, 0, 0, 0),
                                          blurRadius: 10,
                                          spreadRadius: 0,
                                          offset: const Offset(0, 5),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: 30,
                                              padding: const EdgeInsets.only(
                                                right: 5,
                                              ),
                                              child: Image.asset(
                                                'assets/location.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            Text(
                                              field.location,
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 22,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: 30,
                                              padding: const EdgeInsets.only(
                                                right: 5,
                                              ),
                                              child: Image.asset(
                                                'assets/size.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            Text(
                                              '${field.size} m²',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 10),
                                        Row(
                                          children: [
                                            Container(
                                              height: 30,
                                              width: 30,
                                              padding: const EdgeInsets.only(
                                                right: 5,
                                              ),
                                              child: Image.asset(
                                                'assets/leaf.png',
                                                fit: BoxFit.contain,
                                              ),
                                            ),
                                            const Text(
                                              'Koroneiki',
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 18,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (index == _fields.length - 1)
                                    const SizedBox(height: 50),
                                ],
                              );
                            },
                          ),
                    ],
                  ),
                ),
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddNewFieldScreen(user: widget.user),
            ),
          );
          _loadFields();
        },
        backgroundColor: const Color(0xFF655B40),
        child: const Icon(Icons.add, color: Colors.white),
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
                  icon: Image.asset('assets/home.png', height: 35, width: 35),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => UserHomePage(user: widget.user),
                      ),
                    );
                  },
                ),
                const Text("Home", style: TextStyle(color: Colors.white)),
              ],
            ),
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
                const Text("Fields", style: TextStyle(color: Colors.white)),
              ],
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: Image.asset('assets/stats.png', height: 35, width: 35),
                  onPressed: () {
                    Navigator.pushNamed(context, '/statistics');
                  },
                ),
                const Text("Statistics", style: TextStyle(color: Colors.white)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
