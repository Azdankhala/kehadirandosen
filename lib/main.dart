import 'package:flutter/material.dart';
import 'package:postgres/postgres.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:ui';


void main() {
  final dosenProvider = DosenProvider(); // Create the instance here

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: dosenProvider), // Provide the instance
      ],
      child: MyApp(),
    ),
  );
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final dosenProvider = DosenProvider(); // Create the instance here

    return ChangeNotifierProvider<DosenProvider>(
      create: (_) => dosenProvider, // Pass the instance to the provider
      child: MaterialApp(
        title: 'Absensi App',
        theme: ThemeData(
          primarySwatch: Colors.green,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        initialRoute: '/mahasiswa', // Set the login page as the initial route
        routes: {
          '/mahasiswa': (context) => MahasiswaLoginPage(),
          '/home': (context) => HomePage(),
          '/mahasiswa_page': (context) => MahasiswaPage(),
        },
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
                Navigator.pop(context, true);
              },
              child: Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
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

      // Instead of using pushReplacementNamed, use pushAndRemoveUntil
      // to navigate to the LoginPage and remove all previous routes from the stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => MahasiswaLoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(50),
        child: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.green.shade400, Colors.green.shade800],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),
          title: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(height: 8),
                Text(
                  'Universitas Nasional',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          actions: [
            if (isLoggedIn)
              IconButton(
                icon: Icon(Icons.logout),
                onPressed: logout,
              ),
          ],
        ),
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
            if (!isLoggedIn)
              ListTile(
                leading: Icon(Icons.login),
                title: Text('Sign In'),
                onTap: () {
                  Navigator.pushNamed(context, '/mahasiswa');
                },
              ),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.list),
                title: Text('List Pimpinan'),
                onTap: () {
                  Navigator.pushNamed(context, '/mahasiswa_page');
                },
              ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
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
                  Provider.of<DosenProvider>(context, listen: false)
                      .updateSearchQuery(value);
                },
              ),
            ),
            Consumer<DosenProvider>(
              builder: (context, provider, _) {
                final filteredList = provider.filterDosenList();

                if (filteredList.isEmpty) {
                  return Center(
                    child: Text('No data found.'),
                  );
                }

                return ListView.builder(
                  physics: NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: filteredList.length,
                  itemBuilder: (context, index) {
                    final dosen = filteredList[index];
                    return buildDosenCard(dosen, index);
                  },
                );
              },
            ),
            const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildDosenCard(DosenModel dosen, int index) {
    final dosenProvider = Provider.of<DosenProvider>(context);
    return Container(
      decoration: BoxDecoration(
        color: dosen.status ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
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
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                CircleAvatar(
                  radius: 8,
                  backgroundColor: dosenProvider.listDosen[index].status ? Colors.green : Colors.grey,
                ),
                const SizedBox(width: 8),
                Text(
                  dosenProvider.listDosen[index].status ? 'Hadir' : 'Tidak Hadir',
                  style: TextStyle(
                    color: dosenProvider.listDosen[index].status ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
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
    DosenModel(
        'Rektor Universitas Nasional',
        'Dr. El Amry Bermawi Putera, M.A.',
        true,
        'images/rektor.png'),
    DosenModel(
        'Wakil Rektor Bidang Akademik, Kemahasiswaan dan Alumni',
        'Dr. Suryono Efendi, S.E., M.B.A., M.M.',
        false,
        'images/warek1.png'),
    DosenModel(
        'Wakil Rektor Bidang Administrasi Umum, Keuangan, dan SDM',
        'Prof. Dr. Drs. Eko Sugiyanto, M.Si.',
        true,
        'images/warek2.png'),
    DosenModel(
        'Wakil Rektor Bidang Penelitian, Pengabdian Kepada Masyarakat dan Kerjasama',
        'Prof. Dr. Ernawati Sinaga, M.S., Apt.',
        true,
        'images/warek3.png'),
    DosenModel(
        'Sekretaris Rektorat',
        'Yusuf Wibisono, S.I.P., M.Si.',
        true,
        'images/sekretarisrektor.png'),
    DosenModel(
        'Penasihat Manajemen UNAS',
        'Prof. Dr. Umar Basalim, DES.',
        true,
        'images/penasehat.png'),
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

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
  }
}


class MahasiswaLoginPage extends StatefulWidget {
  @override
  _MahasiswaLoginPageState createState() => _MahasiswaLoginPageState();
}

class _MahasiswaLoginPageState extends State<MahasiswaLoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoggingIn = false;
  bool _loginError = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  Future<bool> _performLogin() async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',
      8080,
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
        MaterialPageRoute(builder: (context) => HomePage()),
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
        title: Text('Login'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(height: 32), // Add some spacing
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'images/unas.png',
                      height: 200, // Increase the height to your desired size
                    ),
                  ),
                  SizedBox(height: 16),
                  TextFormField(
                    enableSuggestions: false,
                    autocorrect: false,
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
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
                      padding:
                      EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.green,
                    ),
                  ),
                  SizedBox(height: 20), // Add some spacing
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the Mahasiswa page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MahasiswaLoginPage()),
                          );
                        },
                        child: Text('Mahasiswa'),
                        style: ElevatedButton.styleFrom(
                          padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ),
                      SizedBox(width: 20), // Add some spacing
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the Dosen page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => MahasiswaLoginPage()),
                          );
                        },
                        child: Text('Dosen'),
                        style: ElevatedButton.styleFrom(
                          padding:
                          EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}



class DosenNewModel {
  int id;
  String nama;
  String jabatan;
  bool status;
  String imageUrl;
  String? waktuHadir;

  DosenNewModel({
    required this.id,
    required this.nama,
    required this.jabatan,
    required this.status,
    required this.imageUrl,
    this.waktuHadir,
  });
}


class MahasiswaPage extends StatefulWidget {
  @override
  _MahasiswaPageState createState() => _MahasiswaPageState();
}


class _MahasiswaPageState extends State<MahasiswaPage> {
  late String formattedDate;
  late String formattedTime;
  bool isLoggedIn = false;
  List<DosenNewModel> listDosenNewModel = [];
  late Timer timer;
  late String? loggedInUsername;

  @override
  void initState() {
    super.initState();
    formattedDate = DateFormat('dd MMMM yyyy').format(DateTime.now());
    formattedTime = DateFormat('HH:mm').format(DateTime.now());

    checkLoginStatus();
    getData();
    startTimer();
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

  void startTimer() {
    timer = Timer.periodic(Duration(seconds: 1), (Timer t) {
      setState(() {
        formattedTime = DateFormat('HH:mm').format(DateTime.now());
      });
    });
  }

  void logout() async {
    await SessionManager.setLoggedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => MahasiswaLoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  void getData() async {
    final connection = PostgreSQLConnection(
      '10.0.2.2',
      8080,
      'unas',
      username: 'postgres',
    );

    await connection.open();

    final result = await connection.query('SELECT id, name, jabatan, status, imageurl FROM tbl_dosen');

    await connection.close();

    setState(() {
      listDosenNewModel = result
          .map((row) => DosenNewModel(
        id: row[0] as int,
        nama: row[1] as String,
        jabatan: row[2] as String,
        status: row[3] as bool,
        imageUrl: row[4] as String,
        waktuHadir: null, // Set waktuHadir to null for every Dosen
      ))
          .toList();
    });
  }

  void _toggleStatus(int index) async {
    bool newStatus = !listDosenNewModel[index].status;
    String? waktuHadir = newStatus ? DateFormat('HH:mm').format(DateTime.now()) : null;

    if (newStatus && listDosenNewModel[index].status == false) {
      waktuHadir = DateFormat('HH:mm').format(DateTime.now());
    }

    final connection = PostgreSQLConnection(
      '10.0.2.2',
      8080,
      'unas',
      username: 'postgres',
    );

    await connection.open();

    await connection.execute(
      'UPDATE tbl_dosen SET status = @status, "waktuHadir" = @waktuHadir WHERE id = @id',
      substitutionValues: {
        'status': newStatus,
        'waktuHadir': waktuHadir,
        'id': listDosenNewModel[index].id,
      },
    );

    await connection.close();

    setState(() {
      listDosenNewModel[index].status = newStatus;
      listDosenNewModel[index].waktuHadir = waktuHadir;
    });

    // Update the status in DosenProvider
    Provider.of<DosenProvider>(context, listen: false).updateStatus(index, newStatus);
  }



  Future<bool> confirmDialog(BuildContext context, int index) async {
    return (await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Confirmation'),
          content: RichText(
            text: TextSpan(
              text: 'Are you sure you want to update the status for ',
              style: DefaultTextStyle.of(context).style,
              children: <TextSpan>[
                TextSpan(
                  text: listDosenNewModel[index].nama,
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                TextSpan(text: '?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
            TextButton(
              child: Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
          ],
        );
      },
    )) ??
        false;
  }

   @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Absensi Kehadiran'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade400, Colors.green.shade800],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.green,
              ),
              child: Stack(
                children: [
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: Text(
                      'Menu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isLoggedIn)
              ListTile(
                leading: Icon(Icons.home),
                title: Text('Home'),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => HomePage()),
                  );
                },
              ),
            ListTile(
              leading: Icon(Icons.logout),
              title: Text('Sign Out'),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green.shade100],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              elevation: 4,
              margin: EdgeInsets.all(16),
              color: Colors.green,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tanggal',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Waktu',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: ListView.builder(
              itemCount: listDosenNewModel.length,
              itemBuilder: (context, index) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 4,
                  margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundImage: AssetImage(listDosenNewModel[index].imageUrl),
                    ),
                    title: Text(
                      listDosenNewModel[index].jabatan,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(listDosenNewModel[index].nama),
                        Row(
                          children: [
                            Text(
                              'Status: ',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Flexible(
                              child: ElevatedButton.icon(
                                onPressed: () => _toggleStatus(index),
                                icon: Icon(
                                  listDosenNewModel[index].status
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: Colors.white,
                                ),
                                label: Text(
                                  listDosenNewModel[index].status ? 'Hadir' : 'Tidak Hadir',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: listDosenNewModel[index].status
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            ),
                            if (listDosenNewModel[index].status) // Display waktuHadir only if status is "Hadir"
                              Padding(
                                padding: const EdgeInsets.only(top: 4.0),
                                child: Text(
                                  'Waktu Hadir: ${listDosenNewModel[index].waktuHadir}',
                                  style: TextStyle(
                                    color: Colors.black,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      )
    );
  }

@override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}
