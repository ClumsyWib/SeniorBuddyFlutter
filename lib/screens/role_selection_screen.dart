import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../auth/login_screen.dart';
import '../services/text_scale_provider.dart';
import 'senior_connection_screen.dart';

/// ------------------------------------------------------------------------
/// FILE: role_selection_screen.dart
/// PURPOSE: This is the very first UI screen users see when they open the app.
/// It asks them "Who are you?" and lets them choose if they are a Senior,
/// Caretaker, Volunteer, or Family Member.
/// Depending on their choice, it sends them to the LoginScreen with specific colors.
/// ------------------------------------------------------------------------

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold is the basic canvas for any screen.
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Scaffold(
        // We are putting everything inside a Container so we can give the whole
        // screen a custom background color (a gradient).
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF1A237E), // Deep indigo
                Color(0xFF283593),
                Color(0xFF1565C0), // Rich blue
              ],
            ),
          ),
          // SafeArea prevents the content from overlapping with the phone's notch or status bar.
          child: SafeArea(
            // SingleChildScrollView makes the screen scrollable. This is very important
            // so that on small phones, the buttons don't get cut off at the bottom.
            child: SingleChildScrollView(
              // Padding adds empty space around the edges
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
  
              // Column stacks widgets vertically (one on top of the other)
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Centers everything horizontally
                children: [
                  /// App Logo Section
                  Container(
                    padding: const EdgeInsets.all(26),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.30),
                          blurRadius: 40,
                          spreadRadius: 8,
                          offset: const Offset(0, 0),
                        ),
                        BoxShadow(
                          color: Colors.black.withOpacity(0.20),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.favorite_rounded,
                      size: 90,
                      color: Color(0xFF7C3AED), // Senior Purple as the heart color
                    ),
                  ),

                  const SizedBox(height: 30), // Empty space spacer

                  /// App Title Section
                  const Text(
                    'Senior Buddy',
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Care & Connect',
                    style: TextStyle(
                      fontSize: 17,
                      color: Colors.white.withOpacity(0.75),
                      fontWeight: FontWeight.w500,
                      letterSpacing: 0.5,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Prompting the user to make a choice
                  const Text(
                    'Who are you?',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 30),

                  // 1. The Senior Button
                  _buildRoleCard(
                    context,
                    icon: Icons.person_pin,
                    title: 'I am a Senior',
                    description: 'Connect to my family',
                    color: const Color(0xFF7C3AED), // Deep Violet
                    role: 'senior',
                  ),

                  // 2. The Family Button
                  _buildRoleCard(
                    context,
                    icon: Icons.family_restroom,
                    title: 'I am a Family Member',
                    description: 'Manage care for a senior',
                    color: const Color(0xFF059669), // Emerald Green
                    role: 'family',
                  ),

                  // 3. The Caretaker Button
                  _buildRoleCard(
                    context,
                    icon: Icons.health_and_safety,
                    title: 'I am a Caretaker',
                    description: 'Provide care services',
                    color: const Color(0xFF2563EB), // Royal Blue
                    role: 'caretaker',
                  ),

                  // 4. The Volunteer Button
                  _buildRoleCard(
                    context,
                    icon: Icons.volunteer_activism,
                    title: 'I am a Volunteer',
                    description: 'Help seniors',
                    color: const Color(0xFFD97706), // Rich Amber
                    role: 'volunteer',
                  ),
  
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// This is a custom helper method that draws a "Role Selection Card"
  /// It takes inputs (icon, title, color, etc.) and returns a fully built clickable widget.
  Widget _buildRoleCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required Color color,
    required String role,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Material(
        elevation: 6,
        borderRadius: BorderRadius.circular(20),
        shadowColor: color.withOpacity(0.30),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          // onTap defines what happens when the user presses this card
          onTap: () {
            // Update the provider to reset/set senior mode text scaling
            if (role == 'senior') {
              Provider.of<TextScaleProvider>(context, listen: false)
                  .setSeniorMode(true);
            } else {
              Provider.of<TextScaleProvider>(context, listen: false).reset();
            }

            if (role == 'senior') {
              Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (context) => const SeniorConnectionScreen()),
              );
              return;
            }
            // Navigator.push transitions the app from the current screen to a new screen.
            Navigator.push(
              context,
              MaterialPageRoute(
                // We send the user to the LoginScreen, and we "pass along" the role they picked!
                builder: (context) => LoginScreen(
                  role: role,
                  roleTitle: title,
                  roleColor: color, // The Login Screen will adopt this color
                ),
              ),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  color.withOpacity(0.08),
                ],
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, size: 38, color: color),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C2E),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: 18, color: color),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
