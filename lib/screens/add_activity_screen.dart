import 'package:flutter/material.dart';
import '../services/api_service.dart';

class AddActivityScreen extends StatefulWidget {
  final int seniorId;
  final String seniorName;
  final Color? roleColor;
  const AddActivityScreen(
      {Key? key,
      required this.seniorId,
      required this.seniorName,
      this.roleColor})
      : super(key: key);

  @override
  State<AddActivityScreen> createState() => _AddActivityScreenState();
}

class _AddActivityScreenState extends State<AddActivityScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _notesController = TextEditingController();

  String _selectedType = 'meal';
  bool _isLoading = false;

  final List<Map<String, dynamic>> _activityTypes = [
    {'value': 'meal', 'label': 'Meal / Nutrition', 'icon': Icons.restaurant},
    {
      'value': 'medicine',
      'label': 'Medicine / Treatment',
      'icon': Icons.medication
    },
    {
      'value': 'exercise',
      'label': 'Exercise / Mobility',
      'icon': Icons.directions_run
    },
    {
      'value': 'hygiene',
      'label': 'Hygiene / Bathing',
      'icon': Icons.clean_hands
    },
    {
      'value': 'mood',
      'label': 'Mood / Social Interaction',
      'icon': Icons.emoji_emotions
    },
    {'value': 'rest', 'label': 'Rest / Sleep', 'icon': Icons.bed},
    {'value': 'other', 'label': 'Other', 'icon': Icons.assignment},
  ];

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final result = await _apiService.createDailyActivity(
      seniorId: widget.seniorId,
      activityType: _selectedType,
      notes: _notesController.text.trim(),
    );

    if (mounted) {
      setState(() => _isLoading = false);
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Activity logged successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: ${result['error']}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Care Activity'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Log activity for ${widget.seniorName}',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              const Text('Activity Type',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 2.2,
                ),
                itemCount: _activityTypes.length,
                itemBuilder: (context, index) {
                  final type = _activityTypes[index];
                  final isSelected = _selectedType == type['value'];
                  return _buildTypeCard(type, isSelected);
                },
              ),
              const SizedBox(height: 24),
              const Text('Notes / Observation',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notesController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText:
                      'Add details about the activity (e.g., "Ate breakfast well", "Refused walk today")',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                    backgroundColor: widget.roleColor ?? Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15)),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text('Save Activity',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTypeCard(Map<String, dynamic> type, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedType = type['value']),
      borderRadius: BorderRadius.circular(15),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          border: Border.all(
            color: isSelected
                ? (widget.roleColor ?? Theme.of(context).primaryColor)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(type['icon'],
                color: isSelected
                    ? (widget.roleColor ?? Theme.of(context).primaryColor)
                    : Colors.grey[600]),
            const SizedBox(width: 8),
            Text(
              type['label'].split(' ')[0], // Only first word for label
              style: TextStyle(
                color: isSelected
                    ? (widget.roleColor ?? Theme.of(context).primaryColor)
                    : Colors.grey[600],
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
