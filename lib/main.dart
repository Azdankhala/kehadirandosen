import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<DosenProvider>(
      create: (_) => DosenProvider(),
      child: MaterialApp(
        title: 'Absensi App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: HomePage(),
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    checkLoginStatus();
  }

  void checkLoginStatus() async {
    bool loggedIn = await SessionManager.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });
  }

  void logout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Logout Confirmation'),
          content: Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true); // Setelah logout dikonfirmasi, pop dialog dengan nilai true
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false); // Jika logout dibatalkan, pop dialog dengan nilai false
              },
              child: Text('No'),
            ),
          ],
        );
      },
    );

    if (confirmLogout == true) {
      await SessionManager.setLoggedIn(false);
      Fluttertoast.showToast(
        msg: "Logout successful",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.green,
        textColor: Colors.white,
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MyApp()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Universitas Nasional'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Text(
                'Menu',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.list),
              title: Text('List Pimpinan'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => MahasiswaPage()),
                );
              },
            ),
            if (!isLoggedIn)
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Sign In'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => MahasiswaLoginPage()),
                  );
                },
              ),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.logout),
                title: Text('Sign Out'),
                onTap: logout,
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Image.asset(
                'images/unas.png',
                height: 140,
                width: 140,
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
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
                onChanged: (value) {
                  Provider.of<DosenProvider>(context, listen: false).updateSearchQuery(value);
                },
              ),
            ),
            Consumer<DosenProvider>(
              builder: (context, provider, _) {
                final filteredList = provider.filterDosenList();

                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final dosen = filteredList[index];
                    return Container(
                      decoration: BoxDecoration(
                        color: dosen.status
                            ? Colors.green.withOpacity(0.2)
                            : Colors.grey.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                      padding: const EdgeInsets.all(8),
                      child: ListTile(
                        leading: ClipOval(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              image: DecorationImage(
                                image: AssetImage(dosen.imageUrl),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        title: Text(
                          dosen.jabatan,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 8),
                            Text(
                              dosen.nama,
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundColor: dosen.status ? Colors.green : Colors.grey,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  dosen.status ? 'Hadir' : 'Tidak Hadir',
                                  style: TextStyle(
                                    color: dosen.status ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class DosenModel {
  String jabatan;
  String nama;
  bool status;
  String imageUrl;

  DosenModel(this.jabatan, this.nama, this.status, this.imageUrl);
}

class DosenProvider extends ChangeNotifier {
  List<DosenModel> _listDosen = [
    DosenModel('Rektor Universitas Nasional', 'Dr. El Amry Bermawi Putera, M.A.', true, 'images/rektor.png'),
    DosenModel('Wakil Rektor Bidang Akademik, Kemahasiswaan dan Alumni', 'Dr. Suryono Efendi, S.E., M.B.A., M.M.', false, 'images/warek1.png'),
    DosenModel('Wakil Rektor Bidang Administrasi Umum, Keuangan, dan SDM', 'Prof. Dr. Drs. Eko Sugiyanto, M.Si.', true, 'images/warek2.png'),
    DosenModel('Wakil Rektor Bidang Penelitian, Pengabdian Kepada Masyarakat dan Kerjasama', 'Prof. Dr. Ernawati Sinaga, M.S., Apt.', true, 'images/warek3.png'),
    DosenModel('Sekretaris Rektorat', 'Yusuf Wibisono, S.I.P., M.Si.', true, 'images/sekretarisrektor.png'),
    DosenModel('Penasihat Manajemen UNAS', 'Prof. Dr. Umar Basalim, DES.', true, 'images/penasehat.png'),
  ];

  String _searchQuery = '';

  List<DosenModel> get listDosen => _listDosen;

  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  List<DosenModel> filterDosenList() {
    if (_searchQuery.isEmpty) {
      return _listDosen;
    } else {
      return _listDosen.where((dosen) {
        final name = dosen.jabatan.toLowerCase();
        return name.contains(_searchQuery);
      }).toList();
    }
  }

  void updateStatus(int index, bool value) {
    _listDosen[index].status = value;
    notifyListeners();
  }
}

class SessionManager {
  static const String isLoggedInKey = 'isLoggedIn';

  // Save the user's login status
  static Future<void> setLoggedIn(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, isLoggedIn);
  }

  // Retrieve the user's login status
  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
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
      8080  ,
      'unas',
      username: 'postgres',
    );

    await connection.open();

    final result = await connection.query(
      'SELECT COUNT(*) FROM tbl_dosen WHERE username = @username AND password = @password;',
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
      await SessionManager.setLoggedIn(true);
      Navigator.pushReplacement(
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
              decoration: InputDecoration(
                labelText: 'Username',
                hintText: 'Enter your username',
                prefixIcon: Icon(Icons.person),
              ),
            ),
            SizedBox(height: 16),
            TextFormField(
              enableSuggestions: false,
              autocorrect: false,
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon: Icon(Icons.lock),
              ),
              obscureText: true,
            ),
            if (_loginError)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Username or password is incorrect',
                  style: TextStyle(
                    color: Colors.red,
                  ),
                ),
              ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoggingIn ? null : _login,
              child: _isLoggingIn
                  ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text('Login'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
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
  bool isLoggedIn = false;

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

    checkLoginStatus();
  }

  void checkLoginStatus() async {
    bool loggedIn = await SessionManager.isLoggedIn();
    setState(() {
      isLoggedIn = loggedIn;
    });

    if (!isLoggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => MahasiswaLoginPage()),
      );
    }
  }

  void logout() async {
    await SessionManager.setLoggedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => HomePage()),
          (Route<dynamic> route) => false,
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    dosenProvider = Provider.of<DosenProvider>(context);
  }

  @override
  void dispose() {
    selectedDate.dispose();
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kehadiran'),
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Waktu:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ValueListenableBuilder<DateTime>(
                  valueListenable: selectedDate,
                  builder: (context, value, child) {
                    return Text(
                      DateFormat('HH:mm').format(value),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tanggal:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ValueListenableBuilder<DateTime>(
                  valueListenable: selectedDate,
                  builder: (context, value, child) {
                    return Text(
                      DateFormat('dd MMMM yyyy').format(value),
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          SizedBox(height: 20),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  ListView.builder(
                    physics: NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: dosenProvider.listDosen.length,
                    itemBuilder: (context, index) {
                      final dosen = dosenProvider.listDosen[index];
                      return Container(
                        decoration: BoxDecoration(
                          color: dosen.status
                              ? Colors.green.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
                        padding: const EdgeInsets.all(8),
                        child: ListTile(
                          title: Text(
                            dosen.jabatan,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          subtitle: Text(
                            dosen.status
                                ? 'Hadir pada ${DateFormat('dd MMMM yyyy').format(DateTime.now())}, Jam $formattedTime'
                                : 'Tidak Hadir',
                            style: TextStyle(
                              fontSize: 16,
                            ),
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
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomAppBar(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: Icon(Icons.home),
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                        (Route<dynamic> route) => false,
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
