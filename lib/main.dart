import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'dart:convert';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:googleapis/calendar/v3.dart' as google_calendar;
import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;


const List<String> priorities = <String>['Urgent', 'High', 'Medium', 'Low'];

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ToDo List App',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  var selectedIndex = 0;
  @override
  Widget build(BuildContext context) {
    Widget page;
    switch (selectedIndex) {
      case 0:
        page = TaskPage();
      case 1:
        page = AddTask(); // Add tasks
      default:
        throw UnimplementedError('no widget for $selectedIndex');
    }
    return LayoutBuilder(builder: (context, constraints) {
      return Scaffold(
        body: Row(
          children: [
            SafeArea(
              child: NavigationRail(
                extended: constraints.maxWidth >= 600,
                destinations: [
                  NavigationRailDestination(
                    icon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                      icon: Icon(Icons.add_circle), label: Text("Add tasks")),
                ],
                selectedIndex: selectedIndex,
                onDestinationSelected: (value) {
                  setState(() {
                    selectedIndex = value;
                  });
                },
              ),
            ),
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: page,
              ),
            ),
          ],
        ),
      );
    });
  }
}

class TaskPage extends StatefulWidget {
  const TaskPage({super.key});

  @override
  State<TaskPage> createState() => _TaskPageState();
}

class _TaskPageState extends State<TaskPage> {
  static const List<String> priorities = <String>['Urgent', 'High', 'Medium', 'Low'];
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(duration: const Duration(seconds: 1));
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  // Map priority to colors
  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'Urgent':
        return Colors.red[900]!;
      case 'High':
        return Colors.red;
      case 'Medium':
        return Colors.yellow[700]!;
      case 'Low':
        return Colors.blue;
      default:
        return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tasks'),
      ),
      body: Stack(
        children: [
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance.collection('tasks').snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(child: Text('Error: ${snapshot.error}'));
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No tasks available'));
              }

              final tasks = snapshot.data!.docs;

              final sortedTasks = tasks.toList()
                ..sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aPriorityIndex = priorities.indexOf(aData['priority'] ?? '');
                  final bPriorityIndex = priorities.indexOf(bData['priority'] ?? '');
                  return aPriorityIndex.compareTo(bPriorityIndex);
                });

              return ListView.builder(
                itemCount: sortedTasks.length,
                itemBuilder: (context, index) {
                  final task = sortedTasks[index].data() as Map<String, dynamic>;
                  final taskId = sortedTasks[index].id;
                  final priority = task['priority'] as String? ?? '';

                  final titleTextColor = _getPriorityColor(priority);

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: RichText(
                        text: TextSpan(
                          text: task['task'] ?? 'Untitled Task',
                          style: TextStyle(
                            color: titleTextColor,
                            fontSize: 16.5,
                            fontWeight: FontWeight.bold,
                            decoration: priority == 'Urgent'
                                ? TextDecoration.underline
                                : TextDecoration.none,
                            decorationColor: titleTextColor, // Matches underline color
                            decorationThickness: 2.0, // Thickness of the underline
                          ),
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (task['description'] != null && task['description'].isNotEmpty)
                            Text('${task['description']}'),
                          if (task['dueDate'] != null && task['dueDate'].isNotEmpty)
                            Text('Due Date: ${task['dueDate']}'),
                          if (task['dueTime'] != null && task['dueTime'].isNotEmpty)
                            Text('Due Time: ${task['dueTime']}'),
                        ],
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          HoverIconButton(
                            onPressed: () {
                              _showEditDialog(task, taskId);
                            },
                            icon: Icons.edit,
                            hoverColor: Colors.black,
                          ),
                          HoverIconButton(
                            onPressed: () async {
                              _confettiController.play();

                              await FirebaseFirestore.instance
                                  .collection('tasks')
                                  .doc(taskId)
                                  .delete();
                            },
                            icon: Icons.done_outline_rounded,
                            hoverColor: Colors.green,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Align(
            alignment: Alignment.topLeft,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: 0,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              maxBlastForce: 7,
              minBlastForce: 3,
              particleDrag: 0.05,
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirectionality: BlastDirectionality.explosive,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              maxBlastForce: 7,
              minBlastForce: 3,
              particleDrag: 0.05,
            ),
          ),
          Align(
            alignment: Alignment.topRight,
            child: ConfettiWidget(
              confettiController: _confettiController,
              blastDirection: pi,
              emissionFrequency: 0.05,
              numberOfParticles: 30,
              gravity: 0.2,
              maxBlastForce: 7,
              minBlastForce: 3,
              particleDrag: 0.05,
            ),
          ),
        ],
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> task, String taskId) {
    final TextEditingController descriptionController =
        TextEditingController(text: task['description']);
    final TextEditingController dueDateController =
        TextEditingController(text: task['dueDate']);
    final TextEditingController dueTimeController =
        TextEditingController(text: task['dueTime']);
    String? selectedPriority = task['priority'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Edit Task: ${task['task']}'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Priority Dropdown
                DropdownButtonFormField<String>(
                  value: selectedPriority,
                  decoration: const InputDecoration(labelText: 'Priority'),
                  items: priorities.map((priority) {
                    return DropdownMenuItem(
                      value: priority,
                      child: Text(priority),
                    );
                  }).toList(),
                  onChanged: (value) {
                    selectedPriority = value;
                  },
                ),
                const SizedBox(height: 16),
                // Description Field
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                // Due Date Field
                TextField(
                  controller: dueDateController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Due Date',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  onTap: () async {
                    DateTime? pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null && mounted) {
                      setState(() {
                        dueDateController.text = pickedDate.toString().split(' ')[0];                        
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),
                // Due Time Field
                TextField(
                  controller: dueTimeController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Due Time',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.access_time),
                  ),
                  onTap: () async {
                    TimeOfDay? pickedTime = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (pickedTime != null && mounted) {
                      setState(() {
                        dueTimeController.text = pickedTime.format(context);                        
                      });
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: const Text('Save'),
              onPressed: () async {
                // Store references to the methods using `context` before the async call
                final navigator = Navigator.of(context);
                final scaffoldMessenger = ScaffoldMessenger.of(context);

                try {
                  // Perform the async Firestore update
                  await FirebaseFirestore.instance.collection('tasks').doc(taskId).update({
                    'priority': selectedPriority,
                    'description': descriptionController.text.trim(),
                    'dueDate': dueDateController.text.trim(),
                    'dueTime': dueTimeController.text.trim(),
                  });

                  if (mounted) {
                    // Safely use the stored `navigator` and `scaffoldMessenger`
                    navigator.pop();
                    scaffoldMessenger.showSnackBar(
                      const SnackBar(content: Text('Task updated successfully!')),
                    );
                  }
                } catch (e) {
                  if (mounted) {
                    // Safely use the stored `scaffoldMessenger` to show the error message
                    scaffoldMessenger.showSnackBar(
                      SnackBar(content: Text('Error updating task: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}

class HoverIconButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final Color hoverColor;

  const HoverIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.hoverColor,
  });

  @override
  HoverIconButtonState createState() => HoverIconButtonState();
}

class HoverIconButtonState extends State<HoverIconButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
      },
      onExit: (_) {
        setState(() => _isHovered = false);
      },
      child: IconButton(
        icon: Icon(
          widget.icon,
          color: _isHovered ? widget.hoverColor : Colors.grey, // Changes color on hover
        ),
        onPressed: widget.onPressed,
      ),
    );
  }
}

class AddTask extends StatefulWidget {
  const AddTask({super.key});

  @override
  AddTaskState createState() => AddTaskState();
}

class AddTaskState extends State<AddTask> {
  final TextEditingController _taskController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _dueDate;
  TimeOfDay? _dueTime;
  Future<void> _addTaskToGoogleCalendar() async {
    if (_taskController.text.isEmpty || _dueDate == null || _dueTime == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Please fill out all fields')),
        );
      }
      return;
    }

    final DateTime start = DateTime(
      _dueDate!.year,
      _dueDate!.month,
      _dueDate!.day,
      _dueTime!.hour,
      _dueTime!.minute,
    );

    final DateTime end = start.add(Duration(hours: 1));

    final googleCalendar = GoogleCalendarService();
    await googleCalendar.addEvent(
      _taskController.text,
      _descriptionController.text,
      start,
      end,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Task added to Google Calendar!')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add Task')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _taskController,
              decoration: InputDecoration(labelText: 'Task Name'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            TextButton(
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                setState(() {
                  _dueDate = pickedDate;
                });
              },
              child: Text(_dueDate == null
                  ? 'Pick Due Date'
                  : 'Due Date: ${_dueDate.toString().split(' ')[0]}'),
            ),
            TextButton(
              onPressed: () async {
                TimeOfDay? pickedTime = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.now(),
                );
                setState(() {
                  _dueTime = pickedTime;
                });
              },
              child: Text(_dueTime == null
                  ? 'Pick Due Time'
                  : 'Due Time: ${_dueTime!.format(context)}'),
            ),
            ElevatedButton(
              onPressed: _addTaskToGoogleCalendar,
              child: Text('Add Task to Calendar'),
            ),
          ],
        ),
      ),
    );
  }
}

class Dropdown extends StatefulWidget {
  const Dropdown({super.key});

  @override
  State<Dropdown> createState() => _DropdownState();
}

class _DropdownState extends State<Dropdown> {
  String? dropdownValue;
  String baseCase = "Choose a priority";

  @override
  Widget build(BuildContext context) {
    return DropdownButton<String>(
      value: dropdownValue,
      hint: Text(baseCase),
      onChanged: (String? value) {
        if (value != null) {
          setState(() {
            dropdownValue = value;
          });
        }
      },
      items: [
        DropdownMenuItem<String>(
          value: null,
          child: Text(baseCase),
        ),
        ...priorities.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }),
      ],
    );
  }
}

class GoogleCalendarService {
  static const _clientId = '1053752620044-otc743pj5jidbb70c9ul9citp77vahil.apps.googleusercontent.com';
  //static const _redirectUri = 'http://localhost';
  static const _scopes = [google_calendar.CalendarApi.calendarScope];

  static const _redirectUri = 'http://localhost:3000/auth/callback';

  Future<google_calendar.CalendarApi> _getCalendarApi() async {
    final authUrl =
        'https://accounts.google.com/o/oauth2/auth?client_id=$_clientId&redirect_uri=$_redirectUri&response_type=code&scope=${_scopes.join(" ")}';

    final authResult = await FlutterWebAuth2.authenticate(
      url: authUrl,
      callbackUrlScheme: 'localhost',
    );

    final code = Uri.parse(authResult).queryParameters['code'];

    final response = await http.post(
      Uri.parse('https://oauth2.googleapis.com/token'),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'code': code,
        'client_id': _clientId,
        'client_secret': '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',
        'redirect_uri': _redirectUri,
        'grant_type': 'authorization_code',
      },
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to exchange authorization code.');
    }

    final tokens = json.decode(response.body);
    final accessCredentials = AccessCredentials(
      AccessToken('Bearer', tokens['access_token'], DateTime.now().add(Duration(seconds: tokens['expires_in']))),
      tokens['refresh_token'],
      _scopes,
    );

    final client = authenticatedClient(http.Client(), accessCredentials);
    return google_calendar.CalendarApi(client);
  }

  Future<void> addEvent(String summary, String description, DateTime start, DateTime end) async {
    final calendarApi = await _getCalendarApi();

    final event = google_calendar.Event(
      summary: summary,
      description: description,
      start: google_calendar.EventDateTime(dateTime: start),
      end: google_calendar.EventDateTime(dateTime: end),
    );

    await calendarApi.events.insert(event, 'primary');
  }
}