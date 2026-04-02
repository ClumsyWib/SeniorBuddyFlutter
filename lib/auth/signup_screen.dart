import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../home/family_home_screen.dart';

import '../home/caretaker_home_screen.dart';
import '../home/volunteer_home_screen.dart';
import '../home/senior_home_screen.dart';
import '../screens/senior_connection_screen.dart';

/// The SignupScreen widget allows new users to register an account in the app.
/// It dynamically changes its color and title based on the user's role
/// that they select before reaching this screen.
class SignupScreen extends StatefulWidget {
  // Role defines the account type: "senior", "caretaker", "volunteer", "admin"
  final String role;
  // Formal title to display in UI (e.g. "Senior Citizen")
  final String roleTitle;
  // The primary theme color representing this particular role
  final Color roleColor;

  /// Requires [role], [roleTitle], and [roleColor] when instantiated
  const SignupScreen({
    Key? key,
    required this.role,
    required this.roleTitle, 
    required this.roleColor,
  }) : super(key: key);

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

/// The state class that handles UI rendering and registration logic.
class _SignupScreenState extends State<SignupScreen> {
  // GlobalKey to identify the form and validate all text fields cleanly.
  final _formKey = GlobalKey<FormState>();

  // TextControllers manage the input entered into text fields by user.
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController(); // New Username controller
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Boolean flags to keep passwords hidden by default.
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  // Loading flag ensures a spinner shows while backend request runs.
  bool _isLoading = false;

  // Service helper to make network requests to the underlying Django API.
  final ApiService _apiService = ApiService();

  /// Helper to return a hardcoded primary color based on role, providing a fallback.
  Color get _primaryColor {
    switch (widget.role) {
      case 'family':
        return const Color(0xFF4CAF50); // Green
      case 'senior':
        return const Color(0xFF9C27B0); // Purple (Matches RoleSelectionScreen)
      case 'caretaker':
        return const Color(0xFF2196F3); // Blue
      case 'volunteer':
        return const Color(0xFFFF9800); // Orange

      default:
        return const Color(0xFF4CAF50);
    }
  }

  @override
  void dispose() {
    // Crucial: dispose all controllers to free up device memory when user leaves the screen.
    _nameController.dispose();
    _usernameController.dispose(); // Dispose Username controller
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  /// Processes the registration when user taps the "Sign Up" button.
  void _handleSignup() async {
    // Validate trigger checks every TextFormField inside the Form widget.
    if (_formKey.currentState!.validate()) {
      // Toggle loading spinner
      setState(() {
        _isLoading = true;
      });

      // Split the entered full name into first and last name strings.
      final nameParts = _nameController.text.trim().split(' ');
      final firstName = nameParts.first;
      // Re-join the rest if the name has more than one word.
      final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

      // Use the explicitly entered username.
      final username = _usernameController.text.trim();
      
      // Console prints for developer debugging
      print('🔵 Registering user:');
      print('   Username: $username');
      print('   Email: ${_emailController.text}');
      print('   Name: $firstName $lastName');
      print('   User Type: ${widget.role}');

      // Call the register function inside the ApiService.
      final result = await _apiService.register(
        username: username,
        email: _emailController.text.trim(),
        password: _passwordController.text,
        firstName: firstName,
        lastName: lastName,
        userType: widget.role,
        phoneNumber: _phoneController.text.trim(), // Included trimmed phone number
      );

      // Check if widget is still on-screen before interacting with BuildContext
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        if (result['success']) {
          print('🟢 Registration successful!');

          // Show a helpful green popup message indicating successful creation.
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Account created successfully!'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 2),
            ),
          );

          // Route the user directly into the app depending on their role type.
          Widget homeScreen;
          switch (widget.role) {

            case 'caretaker':
              homeScreen = const CaretakerHomeScreen();
              break;
            case 'volunteer':
              homeScreen = const VolunteerHomeScreen();
              break;
            case 'senior':
              homeScreen = const SeniorHomeScreen();
              break;
            case 'family':
            default:
              homeScreen = const FamilyHomeScreen();
          }

          // Clear the stack and make the Home screen the root.
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => homeScreen),
            (route) => false,
          );
        } else {
          // If the API call fails, we extract and parse the error messages to display them to the user.
          print('🔴 Registration failed: ${result['error']}');

          String errorMessage = 'Registration failed. ';
          // Attempting to unpack detailed error mapping from backend.
          if (result['error'] is Map) {
            final errors = result['error'] as Map;
            errors.forEach((key, value) {
              if (value is List) {
                // If it's a list string format, join them.
                errorMessage += '${value.join(", ")} ';
              } else {
                errorMessage += '$value ';
              }
            });
          } else {
            errorMessage += result['error'].toString();
          }

          // Show a red popup containing the parsed backend error message.
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage, style: const TextStyle(fontSize: 16)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Structure of the app page 
    return Scaffold(
      appBar: AppBar(
        title: Text('Sign Up as ${widget.roleTitle}'),
        // Dynamically style based on getter logic
        backgroundColor: _primaryColor,
        elevation: 0, // Makes the AppBar flat with the rest of the page
      ),
      // SafeArea prevents clipping issues behind system UI (status bars/device notches)
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),

                // Role Icon: Visually confirm mapping
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    _getRoleIcon(),
                    size: 80,
                    color: _primaryColor,
                  ),
                ),
                const SizedBox(height: 24),

                // Main Heading Title
                Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),

                // Supplemental instructions subtitle
                Text(
                  'Join as a ${widget.roleTitle.toLowerCase()}',
                  style: const TextStyle(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),

                // Safety Check for Seniors
                if (widget.role == 'senior')
                  Container(
                    margin: const EdgeInsets.only(bottom: 24),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber),
                    ),
                    child: Column(
                      children: [
                        const Text(
                          'Wait! Seniors don\'t need to sign up.',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Ask your family to create a profile for you, then use the connection code.',
                          textAlign: TextAlign.center,
                        ),
                        TextButton(
                          onPressed: () {
                            // Navigate to senior connection screen
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (_) => const SeniorConnectionScreen()),
                            );
                          },
                          child: const Text('Go to Connection Screen'),
                        ),
                      ],
                    ),
                  ),

                // Full Name TextField
                TextFormField(
                  controller: _nameController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Full Name',
                    labelStyle: const TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.person, color: _primaryColor, size: 28),
                    hintText: 'Enter your full name',
                  ),
                  // Form Validation implementation ensuring no blanks
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                
                // Username TextField
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Username',
                    labelStyle: const TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.account_circle, color: _primaryColor, size: 28),
                    hintText: 'Choose a unique username',
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a username';
                    }
                    if (value.length < 3) {
                      return 'Username must be at least 3 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Email Address TextField
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    labelStyle: const TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.email, color: _primaryColor, size: 28),
                    hintText: 'Enter your email',
                  ),
                  // Email strict validation mechanism formatting '@' checking
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!value.contains('@')) {
                      return 'Please enter a valid email';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Phone Contact Information TextField
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    labelStyle: const TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.phone, color: _primaryColor, size: 28),
                    hintText: 'Enter your phone number',
                  ),
                  // Phone numerical limit enforcing validation length checking to at least 10 chars
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your phone number';
                    }
                    if (value.length < 10) {
                      return 'Please enter a valid phone number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Account Password Entry field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Variable controls the hiding factor
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    labelStyle: const TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.lock, color: _primaryColor, size: 28),
                    hintText: 'Create a password',
                    suffixIcon: IconButton(
                      // Dynamically render either open or closed eye toggle button view icons
                      icon: Icon(
                        _obscurePassword ? Icons.visibility_off : Icons.visibility,
                        color: _primaryColor,
                        size: 28,
                      ),
                      onPressed: () {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      },
                    ),
                  ),
                  // Minimum 6 strings password implementation limit check validation string requirement metric
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 6) {
                      return 'Password must be at least 6 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Second Confirm password input verification prompt layer
                TextFormField(
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword, // Mask verification block typing
                  style: const TextStyle(fontSize: 18),
                  decoration: InputDecoration(
                    labelText: 'Confirm Password',
                    labelStyle: const TextStyle(fontSize: 18),
                    prefixIcon: Icon(Icons.lock_outline, color: _primaryColor, size: 28),
                    hintText: 'Re-enter your password',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        color: _primaryColor,
                        size: 28,
                      ),
                      onPressed: () {
                        // Triggers dynamic re-rendering on mask/unmask tap
                        setState(() {
                          _obscureConfirmPassword = !_obscureConfirmPassword;
                        });
                      },
                    ),
                  ),
                  // Safety mechanism linking direct check back over previous input context block equality map logic.
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please confirm your password';
                    }
                    if (value != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Register Creation Button action submission trigger. 
                ElevatedButton(
                  // Intercept press logic internally mapping function trigger if process not busy locking layout logic check parameters metrics internally. 
                  onPressed: _isLoading ? null : _handleSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  // Mutate internal content from standard string literal indication label to loader feedback animated cycle display 
                  child: _isLoading
                      ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                      : const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 22,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Redirection back linking to alternate Login component framework mapping page logic
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Already have an account? ',
                      style: TextStyle(fontSize: 16, color: Colors.black54),
                    ),
                    TextButton(
                      onPressed: () {
                        // Clear stacked layers mapping returning down to first history level context framework log index context metric indicator base logic. 
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Login',
                        style: TextStyle(
                          fontSize: 16,
                          color: _primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Logical translation fetching dynamic visual indicator mapping components for varying roles internally standardizing ui icon presentation outputs.
  IconData _getRoleIcon() {
    switch (widget.role) {
      case 'family':
        return Icons.family_restroom;
      case 'senior':
        return Icons.person_pin; // Matches RoleSelectionScreen
      case 'caretaker':
        return Icons.health_and_safety;
      case 'volunteer':
        return Icons.volunteer_activism;

      default:
        return Icons.person; 
    }
  }
}