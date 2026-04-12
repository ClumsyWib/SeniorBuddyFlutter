import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Color roleColor;
  final String roleTitle;

  const ForgotPasswordScreen({
    Key? key,
    required this.roleColor,
    required this.roleTitle,
  }) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _otpController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = false;
  bool _otpSent = false;
  bool _obscurePassword = true;
  final ApiService _apiService = ApiService();

  @override
  void dispose() {
    _emailController.dispose();
    _otpController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSendOTP() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _apiService.requestPasswordResetOTP(_emailController.text.trim());
    
    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        setState(() => _otpSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'OTP sent to your email.'), backgroundColor: Colors.green),
        );
      } else {
        String errorMsg = 'Failed to send OTP.';
        if (result['error'] is Map) {
          errorMsg = result['error'].values.join(', ');
        } else if (result['error'] is String) {
          errorMsg = result['error'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _handleResetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final result = await _apiService.resetPassword(
        email: _emailController.text.trim(),
        otpCode: _otpController.text.trim(),
        newPassword: _newPasswordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Password reset successful! Please login with your new password.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back to login
      } else {
        String errorMsg = 'Failed to reset password';
        if (result['error'] is Map) {
          errorMsg = result['error'].values.join(', ');
        } else if (result['error'] is String) {
          errorMsg = result['error'];
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
        backgroundColor: widget.roleColor,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Icon(_otpSent ? Icons.verified_user_outlined : Icons.lock_reset, size: 80, color: widget.roleColor),
                const SizedBox(height: 24),
                Text(
                  _otpSent ? 'Enter OTP' : 'Forgot Password?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: widget.roleColor,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _otpSent 
                    ? 'Verify the 6-digit code sent to ${_emailController.text}'
                    : 'Enter email associated with your account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 32),
                
                // Email Field (Disabled if OTP sent)
                TextFormField(
                  controller: _emailController,
                  enabled: !_otpSent,
                  keyboardType: TextInputType.emailAddress,
                  decoration: InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email, color: widget.roleColor),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  validator: (value) => value == null || value.isEmpty
                      ? 'Enter your email'
                      : null,
                ),
                const SizedBox(height: 20),

                if (!_otpSent)
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleSendOTP,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.roleColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Send Reset Code',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),

                if (_otpSent) ...[
                  // OTP Field
                  TextFormField(
                    controller: _otpController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    decoration: InputDecoration(
                      labelText: '6-Digit OTP',
                      counterText: '',
                      prefixIcon: Icon(Icons.password, color: widget.roleColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value == null || value.length != 6
                        ? 'Enter 6-digit OTP'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // New Password
                  TextFormField(
                    controller: _newPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock, color: widget.roleColor),
                      suffixIcon: IconButton(
                        icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off
                                : Icons.visibility,
                            color: widget.roleColor),
                        onPressed: () =>
                            setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value != null && value.length < 6
                        ? 'Password too short'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  // Confirm Password
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon:
                          Icon(Icons.lock_outline, color: widget.roleColor),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (value) => value != _newPasswordController.text
                        ? 'Passwords do not match'
                        : null,
                  ),
                  const SizedBox(height: 32),

                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.roleColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Reset Password',
                            style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white)),
                  ),
                  
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => setState(() => _otpSent = false),
                    child: Text('Change Email', style: TextStyle(color: widget.roleColor)),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
