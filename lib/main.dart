// Imports necessary Flutter and third-party libraries/packages
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'dart:core';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Main entry point of the application
void main() {
  final dosenProvider = DosenProvider(); // Create the instance here
  runApp(
    MultiProvider(
      providers: [
        // Providing `DosenProvider` to descendant widgets
        ChangeNotifierProvider.value(value: dosenProvider),
      ],
      child: const MyApp(),
    ),
  );
}

// Root widget of the application
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final dosenProvider = DosenProvider(); // Initializes the dosenProvider for the context

    return ChangeNotifierProvider<DosenProvider>(
      create: (_) => dosenProvider, // Makes the provider instance available throughout the app
      child: MaterialApp(
        title: 'Absensi App',
        theme: ThemeData(
          primaryColor: Colors.green.shade700,
          visualDensity: VisualDensity.adaptivePlatformDensity,
          cardTheme: CardTheme(
            elevation: 5,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
          ),
          buttonTheme: ButtonThemeData(
            buttonColor: Colors.green.shade700,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            textTheme: ButtonTextTheme.primary,
          ),
        ),
        initialRoute: '/mahasiswa', // Set the login page as the initial route
        routes: {
          '/mahasiswa': (context) => const MahasiswaLoginPage(),
          '/home': (context) => const HomePage(),
          '/mahasiswa_page': (context) => const MahasiswaPage(),
        },
      ),
    );
  }
}


class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}
// State associated with HomePage widget
class _HomePageState extends State<HomePage> {
  bool isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    // Check user's login status upon widget initialization
    checkLoginStatus();
  }

  // Asynchronously checks the user's login status
  void checkLoginStatus() async {
    try {
      bool loggedIn = await SessionManager.isLoggedIn();
      setState(() {
        isLoggedIn = loggedIn;
      });

      if (!isLoggedIn) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const MahasiswaLoginPage()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error checking login status: $e')),
      );
    }
  }

  // Handles the logout procedure
  void logout() async {
    bool confirmLogout = await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout Confirmation'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Yes'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('No'),
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

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const MahasiswaLoginPage()),
            (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(50),
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
          title: const Center(
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
                icon: const Icon(Icons.logout),
                onPressed: logout,
              ),
          ],
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
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
                leading: const Icon(Icons.login),
                title: const Text('Sign In'),
                onTap: () {
                  Navigator.pushNamed(context, '/mahasiswa');
                },
              ),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.list),
                title: const Text('List Pimpinan'),
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
                    prefixIcon: const Icon(Icons.search),
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
                    return const Center(
                      child: Text('No data found.'),
                    );
                  }

                  return ListView.builder(
                    physics: const NeverScrollableScrollPhysics(),
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

  // Renders a card UI for each dosen data
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
                image: NetworkImage('http://10.0.2.2:8000/${dosen.imageUrl}'),
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
              dosen.name,
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

// Model representing the data structure of a Dosen
class DosenModel {
  final String jabatan;
  final String name;
  bool status;
  final String imageUrl;

  DosenModel({
    required this.jabatan,
    required this.name,
    required this.status,
    required this.imageUrl,
  });

  // Konstruktor untuk mengubah data dari JSON ke objek DosenModel
  factory DosenModel.fromJson(Map<String, dynamic> json) {
    return DosenModel(
      jabatan: json['jabatan'],
      name: json['name'],
      status: json['status'] ?? false,
      imageUrl: json['image_url'],
    );
  }
}

// Provider for managing Dosen data and its state changes
class DosenProvider extends ChangeNotifier {
  List<DosenModel> _listDosen = [];
  String _searchQuery = '';

  DosenProvider() {
    // Panggil fungsi getData saat provider ini diinisialisasi
    getData();
  }

  List<DosenModel> get listDosen => _listDosen;
  String get searchQuery => _searchQuery;

  void updateSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    notifyListeners();
  }

  // Filter Dosen based on the current search query
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

  // Update attendance status of a Dosen at a given index
  void updateStatus(int index, bool value) {
    _listDosen[index].status = value;
    notifyListeners();
  }

  void getData() async {
    final token = await SessionManager.getToken();
    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/dosen'),
      headers: {
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final List<dynamic> responseData = jsonDecode(response.body)['data'];
      _listDosen = responseData.map((data) => DosenModel.fromJson(data)).toList();
      notifyListeners();
    } else {
      print('Error fetching data from /api/dosen');
    }
  }
}

// Utility class for managing user sessions
class SessionManager {
  static const String isLoggedInKey = 'isLoggedIn';
  static const String tokenKey = 'token';  // New constant for the token key

  static Future<void> setLoggedIn(bool isLoggedIn) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(isLoggedInKey, isLoggedIn);
  }

  static Future<bool> isLoggedIn() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getBool(isLoggedInKey) ?? false;
  }

  // New methods for handling the token
  static Future<void> setToken(String token) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
  }

  static Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString(tokenKey);
  }
}

// Login page widget for Mahasiswa
class MahasiswaLoginPage extends StatefulWidget {
  const MahasiswaLoginPage({super.key});

  @override
  _MahasiswaLoginPageState createState() => _MahasiswaLoginPageState();
}

// This stateful widget handles the logic for the Mahasiswa login page.
class _MahasiswaLoginPageState extends State<MahasiswaLoginPage>
    with SingleTickerProviderStateMixin {

  // Controllers for the text fields
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  // Animation-related variables
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  // State variables for login status and error handling
  bool _isLoggingIn = false;
  bool _loginError = false;

  // Initialize animation and other settings
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeIn,
      ),
    );
    _animationController.forward();
  }

  // Handle login button click and  Method to perform login action by querying the API
  void _login() async {
    setState(() {
      _isLoggingIn = true;
      _loginError = false;
    });

    try {
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8000/api/login'),
        body: {
          'username': _usernameController.text,
          'password': _passwordController.text,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['message'] == 'success') {
          await SessionManager.setLoggedIn(true);
          await SessionManager.setToken(data['data']['token']);
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomePage()),
          );
        }
        else {
          setState(() {
            _loginError = true;
            _isLoggingIn = false;
          });
        }
      } else {
        setState(() {
          _loginError = true;
          _isLoggingIn = false;
        });
      }
    } catch (e) {
      setState(() {
        _loginError = true;
        _isLoggingIn = false;
      });
      print('Error during login: $e');
    }
  }

  // Build the widget tree for this page
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Login'),
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
                  const SizedBox(height: 32),
                  Align(
                    alignment: Alignment.topCenter,
                    child: Image.asset(
                      'images/unas.png',
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    enableSuggestions: false,
                    autocorrect: false,
                    controller: _usernameController,
                    decoration: InputDecoration(
                      labelText: 'Username',
                      hintText: 'Enter your username',
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    enableSuggestions: false,
                    autocorrect: false,
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      hintText: 'Enter your password',
                      prefixIcon: const Icon(Icons.lock),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    obscureText: true,
                  ),
                  if (_loginError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Text(
                        'Username or password is incorrect',
                        style: TextStyle(
                          color: Colors.red,
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoggingIn ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      backgroundColor: Colors.green,
                    ),
                    child: _isLoggingIn
                        ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                        : const Text('Login'),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MahasiswaLoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Mahasiswa'),
                      ),
                      const SizedBox(width: 20), // Add some spacing
                      ElevatedButton(
                        onPressed: () {
                          // Navigate to the Dosen page
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (context) => const MahasiswaLoginPage()),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          padding:
                          const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          backgroundColor: Colors.green,
                        ),
                        child: const Text('Dosen'),
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

  // Dispose of resources when they are no longer needed
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

// Model representing the data structure of a Dosen
class DosenNewModel {
  int id;
  String name;
  String jabatan;
  bool status;
  String imageUrl;
  String? waktuHadir;

  DosenNewModel({
    required this.id,
    required this.name,
    required this.jabatan,
    required this.status,
    required this.imageUrl,
    this.waktuHadir,
  });
}

class MahasiswaPage extends StatefulWidget {
  const MahasiswaPage({super.key});

  @override
  _MahasiswaPageState createState() => _MahasiswaPageState();
}


class _MahasiswaPageState extends State<MahasiswaPage> {
  late String formattedDate;
  late String formattedTime;
  String? loggedInUser;
  bool isLoggedIn = false;
  List<DosenNewModel> listDosenNewModel = [];
  late Timer timer;
  late String? loggedInUsername;

  @override
  void initState() {
    super.initState();
    getUserData();
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
        MaterialPageRoute(builder: (context) => const MahasiswaLoginPage()),
      );
    }
  }

  void startTimer() {
    timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      setState(() {
        formattedTime = DateFormat('HH:mm').format(DateTime.now());
      });
    });
  }

  void logout() async {
    await SessionManager.setLoggedIn(false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const MahasiswaLoginPage()),
          (Route<dynamic> route) => false,
    );
  }

  void main() {
    DateTime currentTime = DateTime.now();
    print("Waktu sekarang: $currentTime");
  }

  Future<void> getUserData() async {
    try {
      final token = await SessionManager.getToken();
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8000/api/user'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          loggedInUsername = data['username'];
        });
      } else {
        print('Error fetching user data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error occurred: $e');
    }
  }

  void getData() async {
    // Pastikan Anda memiliki token untuk otorisasi
    final token = await SessionManager.getToken();

    final response = await http.get(
      Uri.parse('http://10.0.2.2:8000/api/user'),
      headers: {
        'Authorization': 'Bearer $token',  // asumsi menggunakan Bearer token
      },
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      setState(() {
        listDosenNewModel = [
          DosenNewModel(
            id: data['id'],
            name: data['name'],
            jabatan: data['jabatan'],
            status: false,  // Asumsi default status adalah false, karena tidak ada informasi status di respons
            imageUrl: data['image_url'],
            waktuHadir: null, // Tidak ada informasi waktu_hadir di respons
          ),
        ];
      });
    } else {
      // Tampilkan pesan kesalahan jika ada
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching data from the server')),
      );
    }
  }

  void _toggleStatus(int index) async {
    final token = await SessionManager.getToken();
    final dosen = listDosenNewModel[index];
    final newStatus = !dosen.status;
    final waktuHadir = newStatus ? DateFormat('HH:mm').format(DateTime.now()) : null;

    final response = await http.post(
      Uri.parse('http://10.0.2.2:8000/api/absensi'),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'id_dosen': dosen.id.toString(),
        'waktu_hadir': waktuHadir,
        'status': newStatus ? '1' : '0',
      }),
    );

    if (response.statusCode == 201) {
      final responseData = jsonDecode(response.body);
      if (responseData['message'] == 'success') {
        setState(() {
          dosen.status = newStatus;
          dosen.waktuHadir = waktuHadir;
        });
        print('Error detail: ${response.body}');
        print('Updated Dosen Status: ${dosen.status}');
        print('Updated Dosen Waktu Hadir: ${dosen.waktuHadir}');
      } else {
        // Handle specific error messages if necessary
        print('Error updating status: ${responseData['message']}');
      }
    } else {
      print('Error updating status with status code: ${response.statusCode}');
    }
  }

  Future<bool> confirmDialog(BuildContext context, int index) async {
    return (await showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.orange),
              SizedBox(width: 10),
              Text('Confirmation'),
            ],
          ),
          content: RichText(
            text: TextSpan(
              text: 'Do you want to update the status for ',
              style: const TextStyle(color: Colors.black, fontSize: 16),
              children: <TextSpan>[
                TextSpan(
                  text: listDosenNewModel[index].name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                const TextSpan(text: '?'),
              ],
            ),
          ),
          actionsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          buttonPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          actions: <Widget>[
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('No'),
              onPressed: () {
                Navigator.of(context).pop(false);
              },
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Yes'),
              onPressed: () {
                Navigator.of(context).pop(true);
              },
            ),
          ],
        );
      },
    )) ?? false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.green[100],
      appBar: AppBar(
        title: const Text('Absensi Kehadiran'),
        backgroundColor: Colors.green.shade700,
        elevation: 5, // Added a bit of shadow
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green.shade700, Colors.greenAccent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.person, size: 64, color: Colors.white),
                  SizedBox(height: 10),
                  Text(
                    'Username', // Replace with dynamic username if available
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(),
            if (isLoggedIn)
              ListTile(
                leading: const Icon(Icons.home, color: Colors.green),
                title: const Text('Home', style: TextStyle(color: Colors.green)),
                onTap: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const HomePage()),
                  );
                },
              ),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: logout,
            ),
          ],
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Colors.green[100]!],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            Card(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              margin: const EdgeInsets.all(16),
              elevation: 4,
              color: Colors.green,  // Changed the color here from purple
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedDate,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Waktu',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      formattedTime,
                      style: const TextStyle(
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
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage('http://10.0.2.2:8000/${listDosenNewModel[index].imageUrl}'),
                        radius: 28,
                      ),
                      title: Text(
                        listDosenNewModel[index].jabatan,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,  // Slightly larger text
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(listDosenNewModel[index].name),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                listDosenNewModel[index].status ? Icons.check : Icons.close,
                                color: listDosenNewModel[index].status ? Colors.green : Colors.red,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                listDosenNewModel[index].status ? 'Hadir' : 'Tidak Hadir',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              if (listDosenNewModel[index].status) ...[
                                const SizedBox(width: 8),
                                Text(
                                  'Waktu Hadir: ${listDosenNewModel[index].waktuHadir}',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.edit, color: Colors.green),
                        onPressed: () {
                          confirmDialog(context, index).then((confirmed) {
                            if (confirmed) {
                              _toggleStatus(index);
                            }
                          });
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }
}

