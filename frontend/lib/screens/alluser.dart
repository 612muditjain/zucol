import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool isLoading = true;
  List<dynamic> users = [];
  static const String baseUrl = 'http://192.168.50.125:3000'; // Define your base URL

  // Fetch all users from the backend
  Future<void> fetchUsers() async {
    const url = '$baseUrl/get-users'; // Replace with your API endpoint
    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          users = json.decode(response.body); // Decode user list
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
        });
        print('Failed to load users');
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      print('Error fetching users: $error');
    }
  }

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        backgroundColor: Colors.black12,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : users.isEmpty
          ? const Center(
        child: Text(
          'No users found',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      )
          : ListView.builder(
        itemCount: users.length,
        itemBuilder: (context, index) {
          final user = users[index];
          final profileImage = user['profileImage'] ?? ''; // Get profileImage
          final fullProfileImage = profileImage.startsWith('/uploads/')
              ? '$baseUrl$profileImage'
              : profileImage;

          return ListTile(
            leading: CircleAvatar(
              backgroundImage: (profileImage.isNotEmpty &&
                  Uri.parse(fullProfileImage).isAbsolute)
                  ? NetworkImage(fullProfileImage)
                  : const AssetImage('images/img.jpg') as ImageProvider,
            ),
            title: Text(user['username'] ?? 'Unknown User'),
            subtitle: Text(user['email'] ?? 'No Email Provided'),
          );
        },
      ),
    );
  }
}
