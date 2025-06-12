import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp();
  } catch (e) {
    // ignore: avoid_print
    final logger = Logger();
    logger.e('Firebase initialization error: $e');
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Qatar Utility',
      theme: ThemeData(
        primaryColor: Colors.deepPurple,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          primary: Colors.deepPurple,
          secondary: Colors.amber,
        ),
        scaffoldBackgroundColor: Colors.grey[100],
        textTheme: const TextTheme(
          titleLarge: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.black87),
          titleMedium: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.black54),
          bodyMedium: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        cardTheme: const CardThemeData(
          elevation: 5,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(15))),
          clipBehavior: Clip.antiAlias,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
          ),
        ),
      ),
      home: const LoginSelectorScreen(),
    );
  }
}

// Utility function to parse time and generate time slots
List<String> generateTimeSlots(String availability) {
  final RegExp regex = RegExp(r'(\d{1,2})(AM|PM)\s*-\s*(\d{1,2})(AM|PM)');
  final match = regex.firstMatch(availability);
  if (match == null) return [];

  int startHour = int.parse(match.group(1)!);
  String startPeriod = match.group(2)!;
  int endHour = int.parse(match.group(3)!);
  String endPeriod = match.group(4)!;

  if (startPeriod == 'PM' && startHour != 12) startHour += 12;
  if (startPeriod == 'AM' && startHour == 12) startHour = 0;
  if (endPeriod == 'PM' && endHour != 12) endHour += 12;
  if (endPeriod == 'AM' && endHour == 12) endHour = 0;

  List<String> timeSlots = [];
  for (int hour = startHour; hour <= endHour; hour++) {
    String period = hour < 12 ? 'AM' : 'PM';
    int displayHour = hour % 12 == 0 ? 12 : hour % 12;
    timeSlots.add('$displayHour:00 $period');
  }
  return timeSlots;
}

class LoginSelectorScreen extends StatelessWidget {
  const LoginSelectorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Welcome to Qatar Utility',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CustomerLoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: const Text('Customer Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const RetailerLoginScreen()),
                ),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 32),
                  backgroundColor: Theme.of(context).primaryColor,
                ),
                child: const Text('Retailer Login', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CustomerLoginScreen extends StatefulWidget {
  const CustomerLoginScreen({super.key});

  @override
  State<CustomerLoginScreen> createState() => _CustomerLoginScreenState();
}

class _CustomerLoginScreenState extends State<CustomerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enable location services')),
          );
        }
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permission denied')),
            );
          }
          return;
        }
      }
      // ignore: deprecated_member_use
      Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => CategoryScreen(
              userLocation: 'Lat: ${position.latitude}, Long: ${position.longitude}',
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Login'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}

class RetailerLoginScreen extends StatefulWidget {
  const RetailerLoginScreen({super.key});

  @override
  State<RetailerLoginScreen> createState() => _RetailerLoginScreenState();
}

class _RetailerLoginScreenState extends State<RetailerLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const RetailerDashboardScreen()),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Login failed: ${e.message}')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Login'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
              obscureText: true,
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Theme.of(context).primaryColor,
                    ),
                    child: const Text('Login', style: TextStyle(fontSize: 18, color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}

class RetailerDashboardScreen extends StatefulWidget {
  const RetailerDashboardScreen({super.key});

  @override
  State<RetailerDashboardScreen> createState() => _RetailerDashboardScreenState();
}

class _RetailerDashboardScreenState extends State<RetailerDashboardScreen> {
  final _workerNameController = TextEditingController();
  final _availabilityController = TextEditingController();
  final _serviceController = TextEditingController();
  final _priceController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  Future<void> _addWorker() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please log in')),
      );
      return;
    }
    if (_workerNameController.text.isEmpty ||
        _availabilityController.text.isEmpty ||
        _serviceController.text.isEmpty ||
        _priceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }
    try {
      await _firestore.collection('workers').add({
        'name': _workerNameController.text,
        'availability': _availabilityController.text,
        'service': _serviceController.text,
        'price': _priceController.text,
        'retailerId': user.uid,
        'createdAt': FieldValue.serverTimestamp(),
      });
      _workerNameController.clear();
      _availabilityController.clear();
      _serviceController.clear();
      _priceController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Worker added successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error adding worker: $e')),
      );
    }
  }

  @override
  void dispose() {
    _workerNameController.dispose();
    _availabilityController.dispose();
    _serviceController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Retailer Dashboard'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Worker', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 16),
            TextField(
              controller: _workerNameController,
              decoration: InputDecoration(
                labelText: 'Worker Name',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _availabilityController,
              decoration: InputDecoration(
                labelText: 'Availability (e.g., 9AM - 1PM)',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _serviceController,
              decoration: InputDecoration(
                labelText: 'Service (e.g., Plumbing)',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _priceController,
              decoration: InputDecoration(
                labelText: 'Price (e.g., 50 QAR/hr)',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _addWorker,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Theme.of(context).primaryColor,
              ),
              child: const Text('Add Worker', style: TextStyle(fontSize: 18, color: Colors.white)),
            ),
            const SizedBox(height: 20),
            Text('Workers', style: Theme.of(context).textTheme.titleLarge),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('workers')
                    .where('retailerId', isEqualTo: user.uid)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Error loading workers'));
                  }
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final workers = snapshot.data!.docs;
                  return ListView.builder(
                    itemCount: workers.length,
                    itemBuilder: (context, index) {
                      final worker = workers[index].data() as Map<String, dynamic>;
                      return Card(
                        child: ListTile(
                          title: Text(worker['name'] ?? 'Unknown'),
                          subtitle: Text(
                            '${worker['service'] ?? ''} | ${worker['availability'] ?? ''} | ${worker['price'] ?? ''}',
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class CategoryScreen extends StatelessWidget {
  final String userLocation;
  const CategoryScreen({super.key, required this.userLocation});

  static const List<Map<String, dynamic>> categories = [
    {'name': 'Plumbing', 'icon': Icons.plumbing},
    {'name': 'Cleaning', 'icon': Icons.cleaning_services},
    {'name': 'Electrical', 'icon': Icons.electrical_services},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Explore Services'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Your Location: $userLocation', style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                ),
                itemCount: categories.length,
                itemBuilder: (context, index) {
                  final category = categories[index];
                  return GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            ProviderListScreen(category: category['name']),
                        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                            FadeTransition(opacity: animation, child: child),
                      ),
                    ),
                    child: Card(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Colors.white, Colors.grey[200]!],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(category['icon'], size: 50, color: Theme.of(context).primaryColor),
                            const SizedBox(height: 10),
                            Text(
                              category['name'],
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
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
}

class ProviderListScreen extends StatelessWidget {
  final String category;
  const ProviderListScreen({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$category Providers'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('workers')
              .where('service', isEqualTo: category)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(child: Text('Error loading providers'));
            }
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            final providers = snapshot.data!.docs;
            if (providers.isEmpty) {
              return const Center(child: Text('No providers available', style: TextStyle(fontSize: 18)));
            }
            return ListView.builder(
              itemCount: providers.length,
              itemBuilder: (context, index) {
                final provider = providers[index].data() as Map<String, dynamic>;
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    PageRouteBuilder(
                      pageBuilder: (context, animation, secondaryAnimation) => BookingScreen(
                        provider: {
                          'name': provider['name'] ?? 'Unknown',
                          'price': provider['price'] ?? 'N/A',
                          'time': provider['availability'] ?? 'N/A',
                        },
                        category: category,
                      ),
                      transitionsBuilder: (context, animation, secondaryAnimation, child) =>
                          FadeTransition(opacity: animation, child: child),
                    ),
                  ),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: Theme.of(context).colorScheme.secondary,
                            child: Text(
                              provider['name']?[0] ?? '?',
                              style: const TextStyle(fontSize: 24, color: Colors.white),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  provider['name'] ?? 'Unknown',
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${provider['price'] ?? 'N/A'} | ${provider['availability'] ?? 'N/A'}',
                                  style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.arrow_forward_ios, color: Theme.of(context).primaryColor),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class BookingScreen extends StatefulWidget {
  final Map<String, String> provider;
  final String category;
  const BookingScreen({super.key, required this.provider, required this.category});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final _nameController = TextEditingController();
  String? _selectedTime;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _book() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _nameController.text.isEmpty || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please log in, enter your name, and select a time'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    try {
      await _firestore.collection('bookings').add({
        'customerId': user.uid,
        'customerName': _nameController.text,
        'providerName': widget.provider['name'],
        'category': widget.category,
        'time': _selectedTime,
        'price': widget.provider['price'],
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Booked ${widget.provider['name']} for ${_nameController.text} at $_selectedTime in ${widget.category}',
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error booking: $e')),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final timeSlots = generateTimeSlots(widget.provider['time']!);
    return Scaffold(
      appBar: AppBar(
        title: Text('Book ${widget.provider['name']}'),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepPurple, Colors.purple[300]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      child: Text(
                        widget.provider['name']![0],
                        style: const TextStyle(fontSize: 24, color: Colors.white),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(widget.provider['name']!, style: Theme.of(context).textTheme.titleMedium),
                        Text(
                          '${widget.provider['price']} | ${widget.provider['time']}',
                          style: Theme.of(context).textTheme.bodyMedium!.copyWith(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Your Name',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _selectedTime,
              decoration: InputDecoration(
                labelText: 'Preferred Time',
                border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
                filled: true,
                fillColor: Colors.white,
              ),
              items: timeSlots.map((time) {
                return DropdownMenuItem<String>(value: time, child: Text(time));
              }).toList(),
              onChanged: (value) => setState(() => _selectedTime = value),
              validator: (value) => value == null ? 'Please select a time' : null,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _book,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
                child: const Text('Confirm Booking', style: TextStyle(fontSize: 18, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}