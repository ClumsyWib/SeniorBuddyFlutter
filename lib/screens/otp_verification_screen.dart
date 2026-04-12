import 'package:flutter/material.dart';
import 'dart:async';
import '../services/api_service.dart';
import '../utils/style_utils.dart';

class OTPVerificationScreen extends StatefulWidget {
  final String username;
  final String email;
  final String purpose; // 'login' or 'reset'
  final Function(Map<String, dynamic>)? onVerified;

  const OTPVerificationScreen({
    Key? key,
    required this.username,
    required this.email,
    required this.purpose,
    this.onVerified,
  }) : super(key: key);

  @override
  State<OTPVerificationScreen> createState() => _OTPVerificationScreenState();
}

class _OTPVerificationScreenState extends State<OTPVerificationScreen> {
  final ApiService _api = ApiService();
  final List<TextEditingController> _controllers = List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(6, (_) => FocusNode());
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    for (var node in _focusNodes) node.dispose();
    for (var controller in _controllers) controller.dispose();
    super.dispose();
  }


  Future<void> _verify() async {
    String otp = _controllers.map((e) => e.text).join();
    if (otp.length < 6) return;

    setState(() => _isLoading = true);
    
    final result = await _api.verify2FA(
      username: widget.username,
      otpCode: otp,
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        if (widget.onVerified != null) {
          widget.onVerified!(result['data']);
        } else {
          Navigator.pop(context, result['data']);
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Invalid code', style: const TextStyle(color: Colors.white)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Security Verify', 
          style: TextStyle(color: AppColors.textMain, fontWeight: FontWeight.w700, fontSize: 18)
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textMain),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.familyPrimary.withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 72,
                    color: AppColors.familyPrimary,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  'Two-Factor Authentication',
                  style: AppTextStyles.h1,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    'To protect your account, enter the 6-digit code from your authenticator app for "${widget.username}".',
                    style: AppTextStyles.bodySub.copyWith(height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(6, (index) => _buildOtpBox(index)),
                ),
                const SizedBox(height: 48),
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.familyPrimary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                      elevation: 8,
                      shadowColor: AppColors.familyPrimary.withOpacity(0.4),
                    ),
                    child: _isLoading 
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                        )
                      : const Text(
                          'Verify & Continue',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                        ),
                  ),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.withOpacity(0.1)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 18, color: AppColors.familyPrimary.withOpacity(0.7)),
                      const SizedBox(width: 10),
                      Text(
                        'This code rotates every 30 seconds',
                        style: AppTextStyles.bodySub.copyWith(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40), // Space for keyboard
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 48,
      height: 62,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: TextField(
          controller: _controllers[index],
          focusNode: _focusNodes[index],
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          // Removed maxLength: 1 to allow pasting multiple characters
          style: const TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: AppColors.textMain),
          decoration: InputDecoration(
            counterText: '',
            border: InputBorder.none,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.withOpacity(0.1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: AppColors.familyPrimary, width: 2),
            ),
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (value) {
            if (value.length > 1) {
              // Handle Paste Logic
              String pastedValue = value.trim();
              if (pastedValue.length > 6) pastedValue = pastedValue.substring(0, 6);
              
              // Fill all controllers from the start
              for (int i = 0; i < pastedValue.length; i++) {
                if (i < 6) {
                  _controllers[i].text = pastedValue[i];
                }
              }
              
              // Move focus to the end or verify
              if (pastedValue.length == 6) {
                _focusNodes[5].unfocus();
                _verify();
              } else {
                _focusNodes[pastedValue.length].requestFocus();
              }
              return;
            }

            // Normal single character entry
            if (value.isNotEmpty) {
              if (index < 5) {
                _focusNodes[index + 1].requestFocus();
              } else {
                _focusNodes[index].unfocus();
                _verify();
              }
            } else if (value.isEmpty && index > 0) {
              _focusNodes[index - 1].requestFocus();
            }
          },
        ),
      ),
    );
  }
}
