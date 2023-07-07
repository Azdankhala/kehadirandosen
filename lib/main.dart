import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';


void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => DosenProvider(),
      child: MaterialApp(
        title: 'Absensi App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('images/unas.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: HomePage(),
          ),
        ),
      ),
    );
  }
}


class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Attendance'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          const Center(
            child: Text(
              'List Kehadiran Pimpinan',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Center(
            child: Image.asset(
              'images/unas.png',
              height: 140, // Increase the height by 10%
              width: 140, // Increase the width by 10%
            ),
          ),
          Expanded(
            child: Consumer<DosenProvider>(
              builder: (context, provider, _) {
                return ListView.builder(
                  itemCount: provider.listDosen.length,
                  itemBuilder: (context, index) {
                    final dosen = provider.listDosen[index];
                    return ListTile(
                      title: Text(dosen.nama),
                      subtitle: Row(
                        children: [
                          CircleAvatar(
                            radius: 8,
                            backgroundColor:
                            dosen.status ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(dosen.status ? 'Hadir' : 'Tidak Hadir'),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ElevatedButton(
                child: const Text('Pimpinan'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MahasiswaPage()),
                  );
                },
              ),
              ElevatedButton(
                child: const Text('Dosen'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => DosenLoginPage()),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class DosenModel {
  String nama;
  bool status;

  DosenModel(this.nama, this.status);
}

class DosenProvider with ChangeNotifier {
  List<DosenModel> _listDosen = [
    DosenModel('John Doe', true),
    DosenModel('Jane Smith', false),
    DosenModel('Michael Johnson', true),
  ];

  List<DosenModel> get listDosen => _listDosen;

  void updateStatus(int index, bool value) {
    _listDosen[index].status = value;
    notifyListeners();
  }
}

// class MahasiswaLoginPage extends StatefulWidget {
//   @override
//   _MahasiswaLoginPageState createState() => _MahasiswaLoginPageState();
// }
//
// class _MahasiswaLoginPageState extends State<MahasiswaLoginPage> {
//   final TextEditingController _usernameController = TextEditingController();
//   final TextEditingController _passwordController = TextEditingController();
//
//   bool _isLoggingIn = false;
//   bool _loginError = false;
//
//   Future<bool> _performLogin() async {
//     final connection = PostgreSQLConnection(
//       'your_database_host',
//       5432,
//       'your_database_name',
//       username: 'your_username',
//       password: 'your_password',
//     );
//
//     await connection.open();
//
//     final result = await connection.query(
//       'SELECT COUNT(*) FROM mahasiswa WHERE username = @username AND password = @password;',
//       substitutionValues: {
//         'username': _usernameController.text,
//         'password': _passwordController.text,
//       },
//     );
//
//     await connection.close();
//
//     final count = result[0][0] as int;
//     return count > 0;
//   }
//
//   void _login() async {
//     setState(() {
//       _isLoggingIn = true;
//       _loginError = false;
//     });
//
//     final success = await _performLogin();
//
//     if (success) {
//       Navigator.push(
//         context,
//         MaterialPageRoute(builder: (context) => MahasiswaPage()),
//       );
//     } else {
//       setState(() {
//         _loginError = true;
//         _isLoggingIn = false;
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text('Mahasiswa Login'),
//       ),
//       body: Padding(
//         padding: const EdgeInsets.all(16.0),
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             TextFormField(
//               enableSuggestions: false,
//               autocorrect: false,
//               controller: _usernameController,
//               decoration: const InputDecoration(
//                   labelText: 'Username',
//                   hintText: 'Enter your username'
//               ),
//             ),
//             TextFormField(
//               enableSuggestions: false,
//               autocorrect: false,
//               controller: _passwordController,
//               decoration: const InputDecoration(
//                   labelText: 'Password',
//                   hintText: 'Enter your password'
//               ),
//               obscureText: true,
//             ),
//             if (_loginError)
//               const Text(
//                 'Username or password is incorrect',
//                 style: TextStyle(
//                   color: Colors.red,
//                 ),
//               ),
//             ElevatedButton(
//               onPressed: _isLoggingIn ? null : _login,
//               child: _isLoggingIn ? const CircularProgressIndicator() : const Text('Login'),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

class MahasiswaPage extends StatefulWidget {
  @override
  _MahasiswaPageState createState() => _MahasiswaPageState();
}

class _MahasiswaPageState extends State<MahasiswaPage> {
  late DosenProvider dosenProvider;
  late String formattedDate;
  late String formattedTime;
  bool isDateStatusUpdated = false;
  late ValueNotifier<DateTime> selectedDate;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    formattedTime = DateFormat('HH:mm').format(DateTime.now());
    selectedDate = ValueNotifier(DateTime.now());
    initializeDateFormatting();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dosenProvider = Provider.of<DosenProvider>(context);
  }

  @override
  void dispose() {
    selectedDate.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kehadiran Pimpinan'),
      ),
      body: Column(
        children: [
          Container(),
          SizedBox(
            height: 100, // Adjust the height as needed
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ValueListenableBuilder<DateTime>(
                valueListenable: selectedDate,
                builder: (context, value, _) {
                  return TableCalendar(
                    firstDay: DateTime.utc(2022),
                    lastDay: DateTime.utc(2023),
                    focusedDay: value,
                    calendarFormat: CalendarFormat.month,
                    selectedDayPredicate: (day) {
                      return isSameDay(selectedDate.value, day);
                    },
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        selectedDate.value = selectedDay;
                      });
                    },
                  );
                },
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dosenProvider.listDosen.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(
                    dosenProvider.listDosen[index].nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    dosenProvider.listDosen[index].status
                        ? '${DateFormat('dd MMMM yyyy').format(selectedDate.value)}, Jam $formattedTime '
                        : 'Tidak Hadir',
                  ),
                  trailing: Switch(
                    value: dosenProvider.listDosen[index].status,
                    onChanged: (value) {
                      setState(() {
                        dosenProvider.updateStatus(index, value);
                        if (value && !isDateStatusUpdated) {
                          formattedTime =
                              DateFormat('HH:mm').format(DateTime.now());
                          formattedDate =
                              DateFormat('dd MMMM yyyy').format(DateTime.now());
                          isDateStatusUpdated = true;
                        } else if (!value) {
                          isDateStatusUpdated = false;
                        }
                      });
                    },
                    activeTrackColor: Colors.green.withOpacity(0.5),
                    activeColor: Colors.green,
                    inactiveThumbColor: Colors.grey,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class DosenLoginPage extends StatefulWidget {
  @override
  _DosenLoginPageState createState() => _DosenLoginPageState();
}

class _DosenLoginPageState extends State<DosenLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoggingIn = false;
  bool _loginError = false;

  Future<bool> _performLogin() async {
    final connection = PostgreSQLConnection(
      'your_database_host',
      5432,
      'your_database_name',
      username: 'your_username',
      password: 'your_password',
    );

    await connection.open();

    final result = await connection.query(
      'SELECT COUNT(*) FROM dosen WHERE username = @username AND password = @password;',
      substitutionValues: {
        'username': _usernameController.text,
        'password': _passwordController.text,
      },
    );

    await connection.close();

    final count = result[0][0] as int;
    return count > 0;
  }

  void _login() async {
    setState(() {
      _isLoggingIn = true;
      _loginError = false;
    });

    final success = await _performLogin();

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => DosenAbsenPage()),
      );
    } else {
      setState(() {
        _loginError = true;
        _isLoggingIn = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Dosen Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextFormField(
              enableSuggestions: false,
              autocorrect: false,
              controller: _usernameController,
              decoration: const InputDecoration(
                  labelText: 'Username',
                  hintText: 'Enter your username'
              ),
            ),
            TextFormField(
              enableSuggestions: false,
              autocorrect: false,
              controller: _passwordController,
              decoration: const InputDecoration(
                  labelText: 'Password',
                  hintText: 'Enter your password'
              ),
              obscureText: true,
            ),
            if (_loginError)
              const Text(
                'Username or password is incorrect',
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ElevatedButton(
              onPressed: _isLoggingIn ? null : _login,
              child: _isLoggingIn ? const CircularProgressIndicator() : const Text('Login'),
            ),
          ],
        ),
      ),
    );
  }
}

class DosenAbsenPage extends StatefulWidget {
  const DosenAbsenPage({super.key});

  @override
  _DosenAbsenPageState createState() => _DosenAbsenPageState();
}

class _DosenAbsenPageState extends State<DosenAbsenPage> {
  final List<Dosen> listDosen = [
    Dosen('John Doe', true),
    Dosen('Jane Smith', false),
    Dosen('Michael Johnson', true),
  ];

  String formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Kehadiran Pimpinan'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              formattedDate,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: listDosen.length,
              itemBuilder: (context, index) {
                return ListTile(
                  title: Text(listDosen[index].nama),
                  subtitle: Text(listDosen[index].status ? 'Hadir' : 'Tidak Hadir'),
                  trailing: Switch(
                    value: listDosen[index].status,
                    onChanged: (value) {
                      setState(() {
                        listDosen[index].status = value;
                      });
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class Dosen {
  String nama;
  bool status;

  Dosen(this.nama, this.status);
}
