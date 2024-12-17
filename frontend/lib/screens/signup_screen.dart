import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zucol/screens/home_screen.dart';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../widgets/profile_image_picker.dart';
import '../constants/app_text_styles.dart';

class SignupScreen extends StatefulWidget {
  SignupScreen({Key? key}) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController(text: '+91');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  File? _profileImage;
  bool _isLoading = false;

  // State variables for toggling password visibility
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  // Method to call the Signup API
  Future<void> _signup() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final url = Uri.parse("http://192.168.50.125:3000/api/signup");
      final request = http.MultipartRequest("POST", url);

      // Adding form data
      request.fields["username"] = _usernameController.text;
      request.fields["email"] = _emailController.text;
      request.fields["phone"] = _phoneController.text;
      request.fields["password"] = _passwordController.text;

      // Adding profile image if selected
      if (_profileImage != null) {
        request.files.add(await http.MultipartFile.fromPath(
          "profileImage",
          _profileImage!.path,
        ));
      }

      final response = await request.send();


      if (response.statusCode == 201) {
        final responseData = await http.Response.fromStream(response);
        final data = json.decode(responseData.body);

        // Retrieve user details from the response
        final userDetails = data['user'];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Signup Successful! Welcome, ${userDetails['username']}")),
        );

        // Navigate to the HomeScreen and pass user details
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userId: userDetails['id'], // Pass user ID or other required data
            ),
          ),
        );
      } else {
        final responseData = await http.Response.fromStream(response);
        final data = json.decode(responseData.body);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? "Signup failed")),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred: $error")),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
  void _handleImageSelected(File image) {
    setState(() {
      _profileImage = image;
    });
    // You can also upload the image or save it here
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'Almost There!',
                    style: AppTextStyles.heading1,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We are excited to see you here!',
                    style: AppTextStyles.subtitle,
                  ),
                  const SizedBox(height: 32),
                  Center(
                    child: ProfileImagePicker(
                      onImageSelected: _handleImageSelected,
                    ),
                  ),
                  const SizedBox(height: 32),
                  CustomTextField(
                    controller: _usernameController,
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
                    controller: _emailController,
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
                    controller: _phoneController,
                    hintText: '1234567890',
                    prefixIcon: Icons.phone_outlined,
                    keyboardType: TextInputType.phone,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Phone number is required';
                      }
                      if (!RegExp(r'^\+91[0-9]{10}$').hasMatch(value)) {
                        return 'Enter a valid phone number starting with +91 and 10 digits';
                      }
                      return null;
                    },
                    onChanged: (value) {
                      if (!value.startsWith('+91')) {
                        _phoneController.text = '+91';
                        _phoneController.selection = TextSelection.fromPosition(
                          TextPosition(offset: _phoneController.text.length),
                        );
                      }
                    },
                  ),

                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Password is required';
                      }
                      if (value.length < 6) {
                        return 'Password must be at least 6 characters long';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  CustomTextField(
                    controller: _confirmPasswordController,
                    hintText: 'Confirm Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: !_isConfirmPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isConfirmPasswordVisible ? Icons.visibility : Icons.visibility_off,
                      ),
                      onPressed: () {
                        setState(() {
                          _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                        });
                      },
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Confirm Password is required';
                      }
                      if (value != _passwordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 32),
                  CustomButton(
                    text: 'SIGN UP',
                    isLoading: _isLoading,
                    onPressed: _signup,
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Don\'t have an account? ',
                          style: AppTextStyles.body,
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/');
                          },
                          child: Text(
                            'SIGN IN.!',
                            style: AppTextStyles.link,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  Center(
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: AppTextStyles.body,
                        children: [
                          const TextSpan(
                            text: 'By signing up, you agree to our ',
                          ),
                          TextSpan(
                            text: 'Terms & Conditions',
                            style: AppTextStyles.link,
                          ),
                          const TextSpan(
                            text: ' and ',
                          ),
                          TextSpan(
                            text: 'Privacy Policy',
                            style: AppTextStyles.link,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
