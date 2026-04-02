import 'package:flutter/material.dart';
import '../auth/login_screen.dart';
import 'senior_connection_screen.dart';

/// ------------------------------------------------------------------------
/// FILE: role_selection_screen.dart
/// PURPOSE: This is the very first UI screen users see when they open the app.
/// It asks them "Who are you?" and lets them choose if they are a Senior,
/// Caretaker, Volunteer, or Admin. 
/// Depending on their choice, it sends them to the LoginScreen with specific colors.
/// ------------------------------------------------------------------------

class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Scaffold is the basic canvas for any screen. 
    return Scaffold(
      // We are putting everything inside a Container so we can give the whole
      // screen a custom background color (a gradient).
      body: Container(
        decoration: const BoxDecoration(
          // LinearGradient transitions smoothly from one color to another.
          gradient: LinearGradient(
            begin: Alignment.topCenter, // Starts at the top
            end: Alignment.bottomCenter, // Ends at the bottom
            colors: [
              Color(0xFF4CAF50), // Green (Top)
              Color(0xFF2196F3), // Blue (Bottom)
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
              crossAxisAlignment: CrossAxisAlignment.center, // Centers everything horizontally
              children: [

                /// App Logo Section
                Container(
                  padding: const EdgeInsets.all(25),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle, // Makes the box a perfect circle
                    // Gives the circle a 3D shadow effect popping off the page
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.25),
                        blurRadius: 25,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  // The actual heart icon inside the white circle
                  child: const Icon(
                    Icons.favorite,
                    size: 90,
                    color: Color(0xFF4CAF50),
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
                    letterSpacing: 2, // Spreads the letters slightly apart
                  ),
                ),

                const SizedBox(height: 8),

                // App Subtitle / Slogan
                const Text(
                  'Care & Connect',
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.white70,
                    fontWeight: FontWeight.w500,
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

                /// Below, we call a custom reusable function `_buildRoleCard` four times.
                /// This saves us from copying and pasting the exact same card design 4 times.
                
                // 1. The Senior Button
                _buildRoleCard(
                  context,
                  icon: Icons.person_pin,
                  title: 'I am a Senior',
                  description: 'Connect to my family',
                  color: const Color(0xFF9C27B0), // Purple theme
                  role: 'senior',
                ),

                // 2. The Family Button
                _buildRoleCard(
                  context,
                  icon: Icons.family_restroom,
                  title: 'I am a Family Member',
                  description: 'Manage care for a senior',
                  color: const Color(0xFF4CAF50), // Green theme
                  role: 'family', // Internal Role ID
                ),

                // 2. The Caretaker Button
                _buildRoleCard(
                  context,
                  icon: Icons.health_and_safety,
                  title: 'I am a Caretaker',
                  description: 'Provide care services',
                  color: const Color(0xFF2196F3), // Blue theme
                  role: 'caretaker',
                ),

                // 3. The Volunteer Button
                _buildRoleCard(
                  context,
                  icon: Icons.volunteer_activism,
                  title: 'I am a Volunteer',
                  description: 'Help seniors',
                  color: const Color(0xFFFF9800), // Orange theme
                  role: 'volunteer',
                ),


              ],
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
      // Adds space at the bottom of each card so they don't touch each other
      padding: const EdgeInsets.only(bottom: 20),
      
      // Material widget helps give things a physical appearance with elevation (shadows)
      child: Material(
        elevation: 8, // The height of the shadow
        borderRadius: BorderRadius.circular(22), // Rounded corners
        shadowColor: Colors.black26,
        
        // InkWell is a special button that shows a "ripple" splash effect when you tap it
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          // onTap defines what happens when the user presses this card
          onTap: () {
            if (role == 'senior') {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SeniorConnectionScreen()),
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
          // The visual layout of the card itself
          child: Container(
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(22),
              // Give the card a very subtle background tint based on the specific role's color
              gradient: LinearGradient(
                colors: [
                  Colors.white,
                  color.withOpacity(0.12),
                ],
              ),
            ),
            // Row places widgets horizontally (side-by-side)
            child: Row(
              children: [

                /// 1. Icon Box on the left
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    icon,
                    size: 40,
                    color: color,
                  ),
                ),

                const SizedBox(width: 18),

                /// 2. Text Section in the middle
                // Expanded tells this section to "take up all the remaining horizontal space"
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align text to the left
                    children: [
                      Text(
                        title,
                        maxLines: 1, // Prevent the text from wrapping to a second line
                        overflow: TextOverflow.ellipsis, // Add "..." if text is too long
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                /// 3. Arrow Icon on the far right
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 20,
                  color: color,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}