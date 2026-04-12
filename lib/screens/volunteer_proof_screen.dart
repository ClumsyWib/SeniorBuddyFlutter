import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../services/report_service.dart';
import '../utils/style_utils.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:pdf/pdf.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class VolunteerProofOfServiceScreen extends StatefulWidget {
  final Color primaryColor;
  const VolunteerProofOfServiceScreen({Key? key, required this.primaryColor}) : super(key: key);

  @override
  State<VolunteerProofOfServiceScreen> createState() => _VolunteerProofOfServiceScreenState();
}

class _VolunteerProofOfServiceScreenState extends State<VolunteerProofOfServiceScreen> {
  final ApiService _api = ApiService();
  bool _isLoading = true;
  Map<String, dynamic> _proofData = {};

  @override
  void initState() {
    super.initState();
    _loadProofData();
  }

  Future<void> _loadProofData() async {
    final result = await _api.getVolunteerProofOfService();
    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success']) {
          _proofData = result['data'];
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgSoft,
      appBar: AppBar(
        title: const Text('Proof of Service', style: TextStyle(color: Colors.white)),
        backgroundColor: widget.primaryColor,
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: widget.primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  _buildCertificateCard(),
                  const SizedBox(height: 32),
                  _buildStatsSection(),
                  const SizedBox(height: 40),
                  _buildActionButtons(),
                ],
              ),
            ),
    );
  }

  Widget _buildCertificateCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: widget.primaryColor.withOpacity(0.2), width: 2),
        boxShadow: [
          BoxShadow(
            color: widget.primaryColor.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          )
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.verified_user, size: 64, color: widget.primaryColor),
          const SizedBox(height: 24),
          const Text(
            'CERTIFICATE OF SERVICE',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
              color: AppColors.textMain,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            height: 1,
            width: 100,
            color: widget.primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          const Text(
            'This document verifies that',
            style: TextStyle(color: AppColors.textSub, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 12),
          Text(
            _proofData['volunteer_name'] ?? 'Volunteer',
            style: AppTextStyles.h1.copyWith(fontSize: 26, color: widget.primaryColor),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'has successfully completed ${_proofData['total_hours'] ?? 0} hours of dedicated community service through Senior Buddy.',
            style: AppTextStyles.bodyMain,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _signBlock('Organization', 'Senior Buddy'),
              _signBlock('Issue Date', DateFormat('MMM dd, yyyy').format(DateTime.now())),
            ],
          )
        ],
      ),
    );
  }

  Widget _signBlock(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        const SizedBox(height: 4),
        Container(height: 1, width: 80, color: Colors.grey[300]),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: AppColors.textSub)),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Service Breakdown', style: AppTextStyles.h2),
        const SizedBox(height: 16),
        _statLine(Icons.task_alt, 'Total Tasks Completed', '${_proofData['total_tasks'] ?? 0}'),
        _statLine(Icons.timer_outlined, 'Impact Hours', '${_proofData['total_hours'] ?? 0} hrs'),
        _statLine(Icons.star_outline, 'Community Rating', '${_proofData['average_rating'] ?? 0.0} ★'),
        _statLine(Icons.calendar_month_outlined, 'Member Since', _formatDate(_proofData['join_date'])),
      ],
    );
  }

  Widget _statLine(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: widget.primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, color: widget.primaryColor, size: 20),
          ),
          const SizedBox(width: 16),
          Text(label, style: AppTextStyles.bodyMain),
          const Spacer(),
          Text(value, style: AppTextStyles.h2.copyWith(fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          flex: 5,
          child: OutlinedButton.icon(
            onPressed: () => _handlePreview(),
            icon: Icon(Icons.remove_red_eye_outlined,
                color: widget.primaryColor, size: 20),
            label: Text('Preview',
                style: TextStyle(
                    color: widget.primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: widget.primaryColor, width: 2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 6,
          child: ElevatedButton.icon(
            onPressed: _isLoading ? null : () => _handleDownload(),
            icon: const Icon(Icons.file_download_outlined,
                color: Colors.white, size: 20),
            label: const Text('Download PDF',
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 14)),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal[700],
              elevation: 4,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handlePreview() async {
    setState(() => _isLoading = true);
    try {
      final pdf = await ReportService.buildCertificatePdf(
        volunteerName: _proofData['volunteer_name'] ?? 'Volunteer',
        totalHours: '${_proofData['total_hours'] ?? 0}',
        totalTasks: '${_proofData['total_tasks'] ?? 0}',
        joinDate: _formatDate(_proofData['join_date']),
      );

      if (!mounted) return;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Certificate Preview'),
              backgroundColor: widget.primaryColor,
            ),
            body: PdfPreview(
              build: (format) => pdf.save(),
              allowSharing: true,
              allowPrinting: true,
              initialPageFormat: PdfPageFormat.a4.landscape,
              canChangePageFormat: false,
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleDownload() async {
    setState(() => _isLoading = true);
    try {
      final pdf = await ReportService.buildCertificatePdf(
        volunteerName: _proofData['volunteer_name'] ?? 'Volunteer',
        totalHours: '${_proofData['total_hours'] ?? 0}',
        totalTasks: '${_proofData['total_tasks'] ?? 0}',
        joinDate: _formatDate(_proofData['join_date']),
      );

      final bytes = await pdf.save();
      final fileName =
          'Certificate_${(_proofData['volunteer_name'] ?? 'Volunteer').toString().replaceAll(' ', '_')}.pdf';

      // Using Printing.sharePdf is the most professional way to "download" on mobile.
      // It avoids the Print dialog and allows "Save to Files" or "Downloads" 
      // without triggering Permission Denied errors.
      await Printing.sharePdf(
        bytes: bytes,
        filename: fileName,
      );
      
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Action failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatDate(dynamic dateStr) {
    if (dateStr == null) return 'N/A';
    try {
      final dt = DateTime.parse(dateStr.toString());
      return DateFormat('MMM yyyy').format(dt);
    } catch (_) {
      return dateStr.toString();
    }
  }
}
