import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({this.onComplete, super.key});

  final VoidCallback? onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _intentController = TextEditingController();

  int _step = 0;
  bool _memoryConsent = false;
  final Set<String> _capabilities = <String>{};

  static const _capabilityOptions = <String>[
    'Content Creation',
    'Video Editing',
    'Photo Editing',
    'Social Media',
    'Videography',
    'Branding',
    'Marketing',
    'Business',
    'Technology',
    'Learning',
    'Music',
    'Other',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _intentController.dispose();
    super.dispose();
  }

  void _next() {
    if (_step < 3) {
      setState(() => _step++);
    } else {
      widget.onComplete?.call();
    }
  }

  void _back() {
    if (_step > 0) setState(() => _step--);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _step == 0
            ? null
            : IconButton(onPressed: _back, icon: const Icon(Icons.arrow_back)),
        title: const Text('Set up SAGE'),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 18),
              child: Row(
                children: List.generate(
                  4,
                  (index) => Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 220),
                      height: 3,
                      margin: EdgeInsets.only(right: index == 3 ? 0 : 6),
                      decoration: BoxDecoration(
                        color: index <= _step
                            ? Colors.cyanAccent
                            : Colors.white.withOpacity(.10),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 8, 22, 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _page(theme),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _next,
                  child: Text(_step == 3 ? 'Enter SAGE ONE' : 'Continue'),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(ThemeData theme) {
    switch (_step) {
      case 0:
        return _profilePage(theme);
      case 1:
        return _capabilitiesPage(theme);
      case 2:
        return _intentPage(theme);
      default:
        return _memoryPage(theme);
    }
  }

  Widget _heading(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 34),
        const SizedBox(height: 16),
        Text(title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(subtitle, style: const TextStyle(color: Colors.white70, height: 1.45)),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _field(TextEditingController controller, String label, IconData icon,
      {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _profilePage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Let SAGE know you.', 'A few basics make your personal workspace more useful.'),
        _field(_nameController, 'Your name', Icons.person_outline),
        _field(_phoneController, 'Phone number', Icons.phone_outlined, keyboardType: TextInputType.phone),
        _field(_addressController, 'Address', Icons.location_on_outlined),
        _field(_ageController, 'Age', Icons.cake_outlined, keyboardType: TextInputType.number),
      ],
    );
  }

  Widget _capabilitiesPage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('What can you do?', 'Select the capabilities you want SAGE to understand. You can change these later.'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _capabilityOptions.map((value) {
            final selected = _capabilities.contains(value);
            return FilterChip(
              selected: selected,
              label: Text(value),
              onSelected: (enabled) => setState(() {
                if (enabled) {
                  _capabilities.add(value);
                } else {
                  _capabilities.remove(value);
                }
              }),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _intentPage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('What should SAGE help with?', 'Tell SAGE what you want to accomplish. This becomes part of your setup context.'),
        TextField(
          controller: _intentController,
          minLines: 5,
          maxLines: 8,
          decoration: InputDecoration(
            hintText: 'Example: build my business, create content, learn new skills...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
          ),
        ),
      ],
    );
  }

  Widget _memoryPage(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _heading('Memory & privacy', 'Your information stays under your control. SAGE should learn only with your permission.'),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(.035),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.blueAccent.withOpacity(.20)),
          ),
          child: const Column(
            children: [
              _PrivacyRow(icon: Icons.lock_outline, title: 'You control memory', text: 'You can view, edit or delete saved memories.'),
              _PrivacyRow(icon: Icons.visibility_outlined, title: 'Learning is permission-based', text: 'SAGE does not silently turn private context into memory.'),
              _PrivacyRow(icon: Icons.public, title: 'World Intelligence is separate', text: 'Public-world knowledge is kept separate from your personal memory.'),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SwitchListTile.adaptive(
          value: _memoryConsent,
          onChanged: (value) => setState(() => _memoryConsent = value),
          title: const Text('Allow SAGE to remember useful setup preferences'),
          subtitle: const Text('You can change or delete memory later.'),
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({required this.icon, required this.title, required this.text});

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.cyanAccent, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 3),
                Text(text, style: const TextStyle(color: Colors.white60, fontSize: 12, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
