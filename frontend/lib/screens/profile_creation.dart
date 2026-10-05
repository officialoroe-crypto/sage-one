import 'package:flutter/material.dart';

class ProfileCreationScreen extends StatefulWidget {
  const ProfileCreationScreen({required this.onComplete, super.key});
  final ValueChanged<Map<String, dynamic>> onComplete;

  @override
  State<ProfileCreationScreen> createState() => _ProfileCreationScreenState();
}

class _ProfileCreationScreenState extends State<ProfileCreationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _location = TextEditingController();
  String _study = 'Not specified';
  String _language = 'English';

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _location.dispose();
    super.dispose();
  }

  void _continue() {
    if (!_formKey.currentState!.validate()) return;
    widget.onComplete({
      'name': _name.text.trim(),
      'phone': _phone.text.trim(),
      'location': _location.text.trim(),
      'study_level': _study,
      'preferred_language': _language,
    });
  }

  InputDecoration _decoration(String label, IconData icon) => InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white.withOpacity(.035),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(.08))),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.white.withOpacity(.08))),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF020306),
        body: Stack(
          children: [
            const Positioned.fill(child: _ProfileBackdrop()),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 470),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const _ProfileMark(),
                          const SizedBox(height: 22),
                          const Text('CREATE YOUR PROFILE', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3.2, fontWeight: FontWeight.w400)),
                          const SizedBox(height: 8),
                          const Text('SAGE will use this foundation to personalize your workspace and future opportunities.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white54, height: 1.45)),
                          const SizedBox(height: 28),
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(color: const Color(0xFF06101A).withOpacity(.82), borderRadius: BorderRadius.circular(24), border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.10))),
                            child: Column(
                              children: [
                                TextFormField(controller: _name, decoration: _decoration('Full name', Icons.person_outline), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your name' : null),
                                const SizedBox(height: 14),
                                TextFormField(controller: _phone, keyboardType: TextInputType.phone, decoration: _decoration('Phone number', Icons.phone_outlined), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your phone number' : null),
                                const SizedBox(height: 14),
                                TextFormField(controller: _location, decoration: _decoration('Location', Icons.location_on_outlined), validator: (v) => v == null || v.trim().isEmpty ? 'Enter your location' : null),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _study,
                                  decoration: _decoration('Study level', Icons.school_outlined),
                                  items: const ['Not specified', 'School', 'Higher secondary', 'Bachelor', 'Master', 'Other'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                  onChanged: (v) => setState(() => _study = v ?? _study),
                                ),
                                const SizedBox(height: 14),
                                DropdownButtonFormField<String>(
                                  value: _language,
                                  decoration: _decoration('Preferred language', Icons.translate),
                                  items: const ['English', 'Nepali'].map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                                  onChanged: (v) => setState(() => _language = v ?? _language),
                                ),
                                const SizedBox(height: 22),
                                SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: _continue, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0C6179), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: const Text('Continue'))),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text('You can review and update profile information later.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
}

class _ProfileMark extends StatelessWidget {
  const _ProfileMark();
  @override
  Widget build(BuildContext context) => Center(child: Container(width: 72, height: 72, decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFF173B61), Color(0xFF06101A), Color(0xFF020306)]), border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.35)), boxShadow: [BoxShadow(color: const Color(0xFF17D8FF).withOpacity(.13), blurRadius: 28, spreadRadius: 4)]), child: const Center(child: Text('S', style: TextStyle(color: Color(0xFFBDF5FF), fontSize: 38, fontWeight: FontWeight.w200))));
}

class _ProfileBackdrop extends StatelessWidget {
  const _ProfileBackdrop();
  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: BoxDecoration(gradient: RadialGradient(center: const Alignment(0, -.35), radius: 1.15, colors: [const Color(0xFF0A2340).withOpacity(.68), const Color(0xFF030812).withOpacity(.95), const Color(0xFF020306)], stops: const [0, .5, 1])));
}
