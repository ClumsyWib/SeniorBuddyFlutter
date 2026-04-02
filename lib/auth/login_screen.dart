import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../home/family_home_screen.dart';

import '../home/caretaker_home_screen.dart';
import '../home/senior_home_screen.dart';
import '../home/volunteer_home_screen.dart';
import 'signup_screen.dart';
import '../screens/senior_connection_screen.dart';

/// The LoginScreen widget allows users to log into the application.
/// It dynamically changes its color and title based on the user's role
/// (e.g., family, caretaker, admin, etc.).
class LoginScreen extends StatefulWidget {
  // The unique identifier for the user's role (e.g., "family", "admin")
  final String role;
  // The display name of the role (e.g., "Senior Citizen", "Administrator")
  final String roleTitle;
  // The primary color associated with this role, used throughout the screen's UI
  final Color roleColor;

  /// Constructor requires [role], [roleTitle], and [roleColor] when navigating to this screen.
  const LoginScreen({
    Key? key,
    required this.role,
    required this.roleTitle,
    required this.roleColor,
  }) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

/// The state class handles the UI building and form interaction for the LoginScreen.
class _LoginScreenState extends State<LoginScreen> {
  // A global key that uniquely identifies the Form widget and allows validation of the form fields.
  final _formKey = GlobalKey<FormState>();

  // Controllers to read the text input by the user for username/email and password.
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Boolean to toggle password visibility (hide text by default).
  bool _obscurePassword = true;

  // Boolean state to show a loading indicator while the login request is processing.
  bool _isLoading = false;

  // An instance of the ApiService to interact with the backend server.
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    // It's important to dispose of controllers when the widget is destroyed to prevent memory leaks.
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  /// This function handles the login process when the user taps "Login".
  void _handleLogin() async {
    // First, validate all fields in the form (checks if inputs are empty).
    if (_formKey.currentState!.validate()) {
      // Get the trimmed text from the user input.
      String username = _usernameController.text.trim();
      
      // We no longer strip '@' because we use full email as username now.

      // Show the loading indicator.
      setState(() => _isLoading = true);

      // Call the login function from the ApiService with the provided credentials.
      final result = await _apiService.login(
        username: username,
        password: _passwordController.text,
        role: widget.role,
      );

      // Ensure the widget is still mounted in the UI tree before continuing (in case the user navigated away).
      if (!mounted) return;

      // Stop the loading indicator.
      setState(() => _isLoading = false);

      // Check if the backend responded with success.
      if (result['success']) {
        Widget homeScreen;
        String? actualRole = result['actual_role'];
        bool isMismatch = result['is_mismatch'] ?? false;
        
        // Use actual role if mismatch, otherwise use requested role
        String finalRole = isMismatch ? actualRole! : widget.role;

        // Determine which home screen to navigate to based on the final determined role.
        switch (finalRole) {

          case 'caretaker':
            homeScreen = const CaretakerHomeScreen();
            break;
          case 'senior':
            homeScreen = const SeniorHomeScreen();
            break;
          case 'volunteer':
            homeScreen = const VolunteerHomeScreen();
            break;
          default:
            homeScreen = const FamilyHomeScreen();
        }

        // If there was a role mismatch, inform the user before navigating
        if (isMismatch) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Logging you in as ${actualRole!.toUpperCase()}'),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 2),
            ),
          );
        }

        // Navigate to the appropriate home screen, clearing the stack so the user can't "go back" to login/role selection.
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => homeScreen),
          (route) => false,
        );
      } else {
        // If login failed, show the error message returned from the backend in a SnackBar.
        final errorMsg = result['error']?.toString() ?? 'Login failed. Please check your details.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              errorMsg,
              style: const TextStyle(fontSize: 18),
            ),
            backgroundColor: Colors.red, // Red color to indicate an error
          ),
        );
      }
    }
  }

  /// Handles the action when the user taps the Google Sign-In button.
  void _handleGoogleSignIn() {
    // Currently, Google Sign-In is not fully implemented, so we show a "Coming Soon" message.
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Google Sign-In Coming Soon!',
          style: TextStyle(fontSize: 18),
        ),
        backgroundColor: widget.roleColor,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Scaffold provides the basic visual layout structure of the screen.
    return Scaffold(
      // AppBar at the top of the screen.
      appBar: AppBar(
        title: const Text(
          'Login',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        // Use the dynamic color passed to this screen for the AppBar.
        backgroundColor: widget.roleColor,
      ),
      // SafeArea ensures UI elements don't get covered by device notches or status bars.
      body: SafeArea(
        // SingleChildScrollView allows the screen to scroll, preventing keyboard overlap issues.
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          // Form widget to group together multiple input fields for validation.
          child: Form(
            key: _formKey,
            // Column stacks its children vertically.
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch, // Stretch widgets to fill horizontal space
              children: [
                const SizedBox(height: 30), // Empty vertical space

                /// Role Icon
                /// A circular icon displayed at the top to represent the currently selected role.
                Center(
                  child: Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      // Make the background a transparent version of the role color.
                      color: widget.roleColor.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _getRoleIcon(), // Dynamic icon based on role
                      size: 80,
                      color: widget.roleColor,
                    ),
                  ),
                ),

                const SizedBox(height: 30),

                /// Welcome Text
                Text(
                  'Welcome Back!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: widget.roleColor,
                  ),
                ),

                const SizedBox(height: 10),

                // Subtitle indicating which role the user is logging in as.
                Text(
                  widget.roleTitle,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 20,
                    color: Colors.black54,
                  ),
                ),

                const SizedBox(height: 40),

                /// Username / Email Input Field
                // Using TextFormField which integrates with the Form widget for validation.
                TextFormField(
                  controller: _usernameController,
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Email or Username',
                    prefixIcon: Icon(Icons.person, color: widget.roleColor), // Icon on the left side
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Validation logic to ensure the field is not empty when submitted.
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter your email'
                      : null,
                ),

                const SizedBox(height: 20),

                /// Password Input Field
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword, // Hides the input text with dots if true
                  style: const TextStyle(fontSize: 20),
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: Icon(Icons.lock, color: widget.roleColor),
                    // Icon on the right side to toggle password visibility.
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off // Icon for "hidden"
                            : Icons.visibility,    // Icon for "visible"
                        color: widget.roleColor,
                      ),
                      onPressed: () {
                        // Toggle the visibility state when tapped
                        setState(() => _obscurePassword = !_obscurePassword);
                      },
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  validator: (value) =>
                  value == null || value.isEmpty
                      ? 'Please enter your password'
                      : null,
                ),

                const SizedBox(height: 30),

                /// Primary Login Button
                ElevatedButton(
                  // Unclickable if loading
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: widget.roleColor,
                    padding: const EdgeInsets.symmetric(vertical: 18), // Taller button for better touch target
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  // Show loading spinner or "Login" text depending on state.
                  child: _isLoading
                      ? const CircularProgressIndicator(
                    color: Colors.white,
                  )
                      : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// Sign Up Link
                // Using Wrap so that long text wraps neatly to the next line without overflow errors.
                Wrap(
                  alignment: WrapAlignment.center,
                  children: [
                    const Text(
                      "Don't have an account? ",
                      style: TextStyle(
                        fontSize: 20,
                        color: Colors.black54,
                      ),
                    ),
                    // GestureDetector makes the text tappable like a button.
                    GestureDetector(
                      onTap: () {
                        // Navigate to the SignupScreen, passing the current role information.
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SignupScreen(
                              role: widget.role,
                              roleTitle: widget.roleTitle,
                              roleColor: widget.roleColor, // Pass color down to Signup
                            ),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up',
                        style: TextStyle(
                          fontSize: 20,
                          color: widget.roleColor,
                          fontWeight: FontWeight.bold, // Make the link stand out
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20), // Bottom padding
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Helper method to return the appropriate icon based on the user's selected role.
  IconData _getRoleIcon() {
    switch (widget.role) {
      case 'family':
        return Icons.family_restroom;
      case 'caretaker':
        return Icons.health_and_safety;
      case 'volunteer':
        return Icons.volunteer_activism;

      default:
        return Icons.person; // Default generic fallback icon
    }
  }
}