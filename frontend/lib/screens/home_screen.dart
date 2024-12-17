import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zucol/screens/alluser.dart';
import 'package:zucol/screens/login_screen.dart';
import 'package:zucol/screens/update_screen.dart';
import 'dart:convert';

import 'package:zucol/widgets/profile_info_card.dart';
import '../constants/app_text_styles.dart';
import '../widgets/custom_button.dart';

class HomeScreen extends StatefulWidget {
  final String userId;

  const HomeScreen({Key? key, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool isLoading = true;
  Map<String, dynamic> userDetails = {};
  int _currentIndex = 0;

  // Define base URL for API
  static const String baseUrl = 'http://192.168.50.125:3000';

  Future<void> fetchUserDetails() async {
    final url = '$baseUrl/user-details/${widget.userId}';
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          userDetails = json.decode(response.body);
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to load user details');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching user details: $error');
    }
  }
  Future<void> deleteAccount(BuildContext context) async {
    final url = '$baseUrl/delete-user/${widget.userId}';

    try {
      final response = await http.delete(Uri.parse(url));

      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('userId'); // Clear session data

        // Navigate to the login screen
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => LoginScreen()),
              (route) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete account: ${response.body}')),
        );
      }
    } catch (error) {
      print('Error deleting account: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error deleting account')),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUserDetails();
  }

  Future<void> logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final String username = userDetails['username'] ?? 'Unknown User';
    final String email = userDetails['email'] ?? 'No Email Provided';
    final String phone = userDetails['phone'] ?? 'No Phone Provided';
    final String profileImage = userDetails['profileImage'] ?? '';
    final String fullProfileImageUrl = profileImage.startsWith('/uploads/')
        ? '$baseUrl$profileImage'
        : profileImage;

    final List<Widget> _screens = [
      _buildProfileScreen(username, email, phone, fullProfileImageUrl),
      SettingsScreen(),
      const Center(child: Text('Third Screen Placeholder')),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: Colors.grey[500],
        actions: [
          IconButton(
            padding: const EdgeInsets.fromLTRB(0, 0, 15, 0),
            icon: const Icon(Icons.notifications, size: 26),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Colors.grey[500]),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundImage: (fullProfileImageUrl.isNotEmpty &&
                        Uri.tryParse(fullProfileImageUrl)?.isAbsolute == true)
                        ? NetworkImage(fullProfileImageUrl)
                        : const AssetImage('images/img.jpg') as ImageProvider,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    username,
                    style: const TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: const Text('Home'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.supervised_user_circle),
              title: const Text('Users'),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SettingsScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () {
                Navigator.pop(context);
                logoutUser(context);
              },
            ),
          ],
        ),
      ),
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.supervised_user_circle),
            label: 'Users',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'About',
          ),
        ],
      ),
    );
  }

  Widget _buildProfileScreen(
      String username, String email, String phone, String profileImage) {
    return isLoading
        ? const Center(child: CircularProgressIndicator())
        : SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 60,
              backgroundImage: (profileImage.isNotEmpty &&
                  Uri.tryParse(profileImage)?.isAbsolute == true)
                  ? NetworkImage(profileImage)
                  : const AssetImage('images/img.jpg') as ImageProvider,
            ),
            const SizedBox(height: 24),
            ProfileInfoCard(
              title: 'Username',
              value: username,
              icon: Icons.person_outline,
            ),
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Email',
              value: email,
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),
            ProfileInfoCard(
              title: 'Phone Number',
              value: phone,
              icon: Icons.phone_outlined,
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  final bool? confirm = await showDialog(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Delete Account'),
                      content: const Text(
                        'Are you sure you want to delete your account? This action cannot be undone.',
                      ),
                      actions: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(false),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(color: Colors.blue),
                              ),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(true),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: const [
                                  Icon(Icons.delete, color: Colors.red),
                                  SizedBox(width: 4), // Space between the icon and text
                                  Text(
                                    'Delete Account',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    deleteAccount(context);
                  }
                },
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.delete, color: Colors.red),
                    SizedBox(width: 4), // Space between the icon and text
                    Text(
                      'Delete Account',
                      style: TextStyle(color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),


            const SizedBox(height: 16),
            CustomButton(
              text: 'UPDATE PROFILE',
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UpdateProfileScreen(
                      userId: widget.userId,
                      userDetails: userDetails,
                    ),
                  ),
                );

                if (result == true) {
                  fetchUserDetails();
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: const Center(
        child: Text('No new notifications'),
      ),
    );
  }
}
