import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
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

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universitas Nasional'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Image.asset(
              'images/unas.png',
              height: 140, // Increase the height by 10%
              width: 140, // Increase the width by 10%
            ),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text(
              'Daftar Kehadiran Pimpinan',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: InputDecoration(
                labelText: 'Cari Nama',
                prefixIcon: Icon(Icons.search),
              ),
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
            ),
          ),
          Expanded(
            child: Consumer<DosenProvider>(
              builder: (context, provider, _) {
                final filteredList = provider.listDosen.where((dosen) {
                  final name = dosen.nama.toLowerCase();
                  final query = searchQuery.toLowerCase();
                  return name.contains(query);
                }).toList();

                return ListView.builder(
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final dosen = filteredList[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: dosen.status ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        title: Text(dosen.nama),
                        subtitle: Row(
                          children: [
                            CircleAvatar(
                              radius: 8,
                              backgroundColor: dosen.status ? Colors.green : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Text(dosen.status ? 'Hadir' : 'Tidak Hadir'),
                          ],
                        ),
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
              Expanded(
                child: ElevatedButton(
                  child: const Text('Sign In'),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => MahasiswaLoginPage()),
                    );
                  },
                ),
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

class MahasiswaLoginPage extends StatefulWidget {
  @override
  _MahasiswaLoginPageState createState() => _MahasiswaLoginPageState();
}

class _MahasiswaLoginPageState extends State<MahasiswaLoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoggingIn = false;
  bool _loginError = false;

  Future<bool> _performLogin() async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',
      8080,
      'unas',
      username: 'postgres',
    );

    await connection.open();

    final result = await connection.query(
      'SELECT COUNT(*) FROM kehadiranpimpinan WHERE username = @username AND password = @password;',
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
        MaterialPageRoute(builder: (context) => MahasiswaPage()),
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
        title: const Text('Login'),
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
  late Timer timer;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    formattedTime = DateFormat('HH:mm').format(DateTime.now());
    selectedDate = ValueNotifier(DateTime.now());
    initializeDateFormatting();

    // Start the timer to update the time every second
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        formattedTime = DateFormat('HH:mm').format(DateTime.now());
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dosenProvider = Provider.of<DosenProvider>(context);
  }

  @override
  void dispose() {
    selectedDate.dispose();
    timer.cancel(); // Cancel the timer when the widget is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kehadiran'),
      ),
      body: Column(
        children: [
          SizedBox(height: 10),
          Center(
            child: Column(
              children: [
                Text(
                  formattedTime,
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 30,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: dosenProvider.listDosen.length,
              itemBuilder: (context, index) {
                final dosen = dosenProvider.listDosen[index];
                return Container(
                  decoration: BoxDecoration(
                    color: dosen.status ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                  padding: const EdgeInsets.all(8),
                  child: ListTile(
                    title: Text(
                      dosen.nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      dosen.status
                          ? '${DateFormat('dd MMMM yyyy').format(DateTime.now())}, Jam $formattedTime '
                          : 'Tidak Hadir',
                    ),
                    trailing: Switch(
                      value: dosen.status,
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






