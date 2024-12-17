import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:zucol/screens/home_screen.dart';
import 'package:zucol/widgets/social_login_button.dart';
import 'dart:convert';
import '../widgets/custom_text_field.dart';
import '../widgets/custom_button.dart';
import '../constants/app_text_styles.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>(); // Form key
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  // State variables for toggling password visibility
  bool _isPasswordVisible = false;

  Future<void> _login() async {
    // Validate the form before proceeding
    if (!_formKey.currentState!.validate()) {
      return; // Stop login if validation fails
    }

    final String email = _emailController.text;
    final String password = _passwordController.text;
    setState(() {
      _isLoading = true;
    });

    final response = await http.post(
      Uri.parse('http://192.168.50.125:3000/api/login'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email, 'password': password}),
    );

    setState(() {
      _isLoading = false;
    });

    if (response.statusCode == 200) {
      final responseData = json.decode(response.body);
      final userDetails = responseData['userDetails'];
      final String userId = userDetails['id'];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userId: userId),
        ),
      );
    } else {
      final Map<String, dynamic> error = json.decode(response.body);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error['message'] ?? 'Login failed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form( // Wrap with Form widget
              key: _formKey, // Assign form key
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Text('Welcome Back!', style: AppTextStyles.heading1),
                  const SizedBox(height: 8),
                  Text('Sign In to Continue', style: AppTextStyles.subtitle),
                  const SizedBox(height: 32),

                  // Email TextField with Validation
                  CustomTextField(
                    controller: _emailController,
                    hintText: 'Email',
                    prefixIcon: Icons.email_outlined,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Email is required';
                      }
                      if (!value.endsWith('@gmail.com')) {
                        return 'Please enter a valid @gmail.com email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password TextField with Validation
                  CustomTextField(
                    controller: _passwordController,
                    hintText: 'Password',
                    prefixIcon: Icons.lock_outline,
                    isPassword: !_isPasswordVisible,
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility
                            : Icons.visibility_off,
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

                  // Login Button
                  CustomButton(
                    text: _isLoading ? 'Signing In...' : 'SIGN IN',
                    onPressed: _login,
                  ),
                  const SizedBox(height: 24),

                  Center(
                    child: Text('or login with', style: AppTextStyles.subtitle),
                  ),
                  const SizedBox(height: 24),

                  // Dummy Social Login Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SocialLoginButton(
                        icon: 'images/Google.png',
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      SocialLoginButton(
                        icon: 'images/hash.png',
                        onPressed: () {},
                      ),
                      const SizedBox(width: 16),
                      SocialLoginButton(
                        icon: 'images/linkedin.png',
                        onPressed: () {},
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),

                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Don\'t have an account? ',
                            style: AppTextStyles.body),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/signup');
                          },
                          child: Text('SIGN UP.!',
                              style: AppTextStyles.link),
                        ),
                      ],
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
