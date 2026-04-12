import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../utils/refresh_mixin.dart';
import '../utils/role_helper.dart';
import 'appointment_detail_screen.dart';
import 'medicine_detail_screen.dart';
import 'medicines_screen.dart';
import 'create_appointment_screen.dart';
import 'add_medicine_screen.dart';

class HealthRecordsScreen extends StatefulWidget {
  final VoidCallback onDataChanged;
  final int? seniorId;
  // userRole controls whether Add/Upload buttons are visible
  final String userRole;

  const HealthRecordsScreen(
      {Key? key,
      required this.onDataChanged,
      this.seniorId,
      this.userRole = kRoleFamily})
      : super(key: key);

  @override
  State<HealthRecordsScreen> createState() => _HealthRecordsScreenState();
}

class _HealthRecordsScreenState extends State<HealthRecordsScreen>
    with SingleTickerProviderStateMixin, PeriodicRefreshMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();

  List<dynamic> _appointments = [];
  List<dynamic> _medicines = [];
  bool _isLoadingAppointments = true;
  bool _isLoadingMedicines = true;

  @override
  Future<void> onRefresh() => _loadAllData();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadAppointments(),
      _loadMedicines(),
    ]);
  }

  Future<void> _loadAppointments({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoadingAppointments = true);
    final result = await _apiService.getAppointments(seniorId: widget.seniorId);
    if (mounted) {
      setState(() {
        _isLoadingAppointments = false;
        if (result['success']) {
          _appointments = result['data'];
          // Sort appointments by date and time
          _appointments.sort((a, b) {
            int dateComp = (a['appointment_date'] ?? '').compareTo(b['appointment_date'] ?? '');
            if (dateComp != 0) return dateComp;
            return (a['appointment_time'] ?? '').compareTo(b['appointment_time'] ?? '');
          });
        }
      });
    }
  }

  Future<void> _loadMedicines({bool showLoading = true}) async {
    if (showLoading) setState(() => _isLoadingMedicines = true);
    final result = await _apiService.getMedicines(seniorId: widget.seniorId);
    if (mounted) {
      setState(() {
        _isLoadingMedicines = false;
        if (result['success']) {
          _medicines = result['data'];
          // Sort medicines by Date and Time of Day
          _medicines.sort((a, b) {
            // 1. Sort by start_date ASC
            final dateA = (a['start_date'] ?? '').toString();
            final dateB = (b['start_date'] ?? '').toString();
            int dateComp = dateA.compareTo(dateB);
            if (dateComp != 0) return dateComp;

            // 2. Sort by Time of Day priority
            final order = ['morning', 'noon', 'afternoon', 'evening', 'night'];
            final timeA = (a['time_of_day'] ?? '').toString().toLowerCase();
            final timeB = (b['time_of_day'] ?? '').toString().toLowerCase();
            
            final idxA = order.indexOf(timeA);
            final idxB = order.indexOf(timeB);
            
            if (idxA != -1 && idxB != -1) return idxA.compareTo(idxB);
            if (idxA != -1) return -1;
            if (idxB != -1) return 1;
            return timeA.compareTo(timeB);
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            color: Theme.of(context).primaryColor,
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 4,
              labelStyle:
                  const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              unselectedLabelStyle: const TextStyle(fontSize: 18),
              tabs: const [
                Tab(text: 'Appointments'),
                Tab(text: 'Medicines'),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildAppointmentsTab(),
                _buildMedicinesTab(),
              ],
            ),
          ),
        ],
      ),
      // Only Family Members can add medicines / records
      floatingActionButton: (canFamilyWrite(widget.userRole) &&
              _tabController.index == 1)
          ? FloatingActionButton.extended(
              onPressed: _addMedicine,
              backgroundColor: Theme.of(context).primaryColor,
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Add medicine', style: TextStyle(fontSize: 18)),
            )
          : null,
    );
  }

  Future<void> _addMedicine() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
          builder: (context) => AddMedicineScreen(seniorId: widget.seniorId)),
    );
    if (result == true) {
      _loadMedicines(showLoading: false);
      widget.onDataChanged();
    }
  }

  Widget _buildAppointmentsTab() {
    if (_isLoadingAppointments) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_appointments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 20),
            const Text('No appointments yet', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 30),
            // Only Family Members can create appointments from empty state
            if (canFamilyWrite(widget.userRole))
              ElevatedButton.icon(
                onPressed: _createAppointment,
                icon: const Icon(Icons.add, size: 28),
                label: const Text('Create Appointment',
                    style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
                ),
              ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadAppointments,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _appointments.length,
        itemBuilder: (context, index) {
          final appointment = _appointments[index];
          return _buildAppointmentCard(appointment);
        },
      ),
    );
  }

  Widget _buildAppointmentCard(Map<String, dynamic> appointment) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AppointmentDetailScreen(appointment: appointment),
            ),
          );
          _loadAppointments(showLoading: false);
          widget.onDataChanged();
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child:
                    Icon(Icons.event, color: Theme.of(context).primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      appointment['title'] ?? 'Appointment',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${appointment['appointment_date']} • ${_formatTo12Hour(appointment['appointment_time'])}',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, size: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMedicinesTab() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Medicines',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              TextButton.icon(
                onPressed: _openFullMedicinesPage,
                icon: const Icon(Icons.open_in_new, size: 20),
                label: const Text('See all'),
                style: TextButton.styleFrom(
                    foregroundColor: Theme.of(context).primaryColor),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingMedicines
              ? const Center(child: CircularProgressIndicator())
              : _medicines.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.medication_outlined,
                              size: 80, color: Colors.grey[400]),
                          const SizedBox(height: 20),
                          const Text('No medicines found',
                              style: TextStyle(fontSize: 24)),
                          const SizedBox(height: 12),
                          const Text(
                            'Add medicines in Django admin',
                            style:
                                TextStyle(fontSize: 18, color: Colors.black54),
                          ),
                          const SizedBox(height: 20),
                          TextButton.icon(
                            onPressed: _openFullMedicinesPage,
                            icon: const Icon(Icons.refresh),
                            label: const Text('Open medicines page'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadMedicines,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _medicines.length,
                        itemBuilder: (context, index) {
                          final medicine = _medicines[index];
                          return _buildMedicineCard(medicine);
                        },
                      ),
                    ),
        ),
      ],
    );
  }

  Future<void> _openFullMedicinesPage() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => MedicinesScreen(seniorId: widget.seniorId)),
    );
    _loadMedicines(showLoading: false);
    widget.onDataChanged();
  }

  Widget _buildMedicineCard(Map<String, dynamic> medicine) {
    final isActive = medicine['is_active'] ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MedicineDetailScreen(medicine: medicine),
            ),
          );
          _loadMedicines(showLoading: false);
        },
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                child: Icon(Icons.medication,
                    color: Theme.of(context).primaryColor, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      medicine['medicine_name'] ?? 'Medicine',
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      medicine['dosage'] ?? '',
                      style:
                          const TextStyle(fontSize: 16, color: Colors.black87),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.green.withOpacity(0.2)
                      : Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  isActive ? 'ACTIVE' : 'INACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.green : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTo12Hour(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 'N/A';
    try {
      final parts = timeStr.split(':');
      if (parts.length < 2) return timeStr;
      int hour = int.parse(parts[0]);
      int minute = int.parse(parts[1]);
      final period = hour >= 12 ? 'PM' : 'AM';
      hour = hour % 12;
      if (hour == 0) hour = 12;
      final minuteStr = minute.toString().padLeft(2, '0');
      return '$hour:$minuteStr $period';
    } catch (e) {
      return timeStr;
    }
  }

  Future<void> _createAppointment() async {
    final userId = widget.seniorId ?? await _apiService.getUserId();
    if (userId == null) return;

    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => CreateAppointmentScreen(seniorId: userId),
      ),
    );

    if (result == true) {
      _loadAppointments(showLoading: false);
      widget.onDataChanged();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
