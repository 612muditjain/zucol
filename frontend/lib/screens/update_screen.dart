import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Add image_picker to pubspec.yaml
import 'package:http/http.dart' as http;
import 'package:zucol/widgets/custom_text_field.dart';
import 'package:zucol/widgets/profile_image_picker.dart';

class UpdateProfileScreen extends StatefulWidget {
  final String userId;
  final Map<String, dynamic> userDetails;

  const UpdateProfileScreen({
    Key? key,
    required this.userId,
    required this.userDetails,
  }) : super(key: key);

  @override
  _UpdateProfileScreenState createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  late TextEditingController usernameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  File? selectedImage; // To store the selected image file
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    // Initialize controllers with existing user details
    usernameController =
        TextEditingController(text: widget.userDetails['username']);
    emailController = TextEditingController(text: widget.userDetails['email']);
    phoneController = TextEditingController(
      text: widget.userDetails['phone'].startsWith('+91')
          ? widget.userDetails['phone']
          : '+91${widget.userDetails['phone']}',
    );
  }

  Future<void> pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> updateProfile() async {
    final url = 'http://192.168.50.125:3000/update-profile/${widget.userId}'; // Replace with actual API URL

    setState(() {
      isLoading = true;
    });

    try {
      // Create a multipart request
      var request = http.MultipartRequest('PUT', Uri.parse(url));

      // Add form data fields
      request.fields['username'] = usernameController.text;
      request.fields['email'] = emailController.text;
      request.fields['phone'] = phoneController.text;

      // Add the image file if one is selected
      if (selectedImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'profileImage',
          selectedImage!.path,
        ));
      }

      // Send the request and await response
      var response = await request.send();

      if (response.statusCode == 200) {
        // Successfully updated profile
        Navigator.pop(context, true); // Return success to the previous screen
      } else {
        // Handle failure
        var responseData = await response.stream.bytesToString();
        print('Failed to update profile: $responseData');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update profile')),
        );
      }
    } catch (error) {
      print('Error updating profile: $error');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error updating profile: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleImageSelected(File image) {
    setState(() {
      selectedImage = image;
    });
    // You can also upload the image or save it here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Update Profile'),
        backgroundColor: Colors.grey[500],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // Profile image preview and pick button
            ProfileImagePicker(
              onImageSelected: _handleImageSelected,
            ),
            const SizedBox(height: 24),
            CustomTextField(
              controller: usernameController,
              hintText: 'Username',
              prefixIcon: Icons.person_outline,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Username is required';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: emailController,
              hintText: 'Email',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                // Check if the email ends with @gmail.com
                if (!RegExp(r'^[\w-\.]+@gmail\.com$').hasMatch(value)) {
                  return 'Enter a valid email with @gmail.com';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: phoneController,
              hintText: 'Phone Number',
              prefixIcon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                if (!RegExp(r'^\+91[0-9]{10}$').hasMatch(value)) {
                  return 'Enter a valid phone number starting with +91';
                }
                return null;
              },
              onChanged: (value) {
                // Ensure the phone number always starts with +91 and has a length of 13 characters
                if (!value.startsWith('+91')) {
                  phoneController.text = '+91';
                  phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: phoneController.text.length),
                  );
                }
                // Ensure the phone number has a length of 13 (i.e., +91 followed by 10 digits)
                if (value.length > 13) {
                  phoneController.text = value.substring(0, 13);
                  phoneController.selection = TextSelection.fromPosition(
                    TextPosition(offset: phoneController.text.length),
                  );
                }
              },
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: updateProfile,
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}
