import 'package:flutter/material.dart';

import '../core/identity_client.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    required this.identity,
    required this.onComplete,
    this.initialProfile,
    super.key,
  });

  final IdentityClient identity;
  final VoidCallback onComplete;
  final Map<String, dynamic>? initialProfile;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _ageController = TextEditingController();
  final _intentController = TextEditingController();
  final _otpController = TextEditingController();

  int _step = 0;
  bool _memoryConsent = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  bool _saving = false;
  String? _challengeId;
  String? _error;
  String? _delivery;
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
  void initState() {
    super.initState();
    final profile = widget.initialProfile;
    if (profile != null) {
      _nameController.text = profile['name']?.toString() ?? '';
      _phoneController.text = profile['phone']?.toString() ?? '';
      _addressController.text = profile['address']?.toString() ?? '';
      final age = profile['age'];
      if (age != null) _ageController.text = age.toString();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _ageController.dispose();
    _intentController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Enter your phone number first.');
      return;
    }
    setState(() {
      _sendingOtp = true;
      _error = null;
    });
    try {
      final result = await widget.identity.sendPhoneOtp(phone);
      if (!mounted) return;
      setState(() {
        _challengeId = result['challenge_id'] as String?;
        _delivery = result['delivery'] as String?;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _verifyOtp() async {
    final challenge = _challengeId;
    final code = _otpController.text.trim();
    if (challenge == null) {
      setState(() => _error = 'Send a verification code first.');
      return;
    }
    if (code.length != 6) {
      setState(() => _error = 'Enter the 6-digit verification code.');
      return;
    }
    setState(() {
      _verifyingOtp = true;
      _error = null;
    });
    try {
      await widget.identity.verifyPhoneOtp(challenge, code);
      if (mounted) setState(() {
        _step = 1;
        _error = null;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _verifyingOtp = false);
    }
  }

  Future<void> _complete() async {
    final age = int.tryParse(_ageController.text.trim());
    if (age == null) {
      setState(() => _error = 'Enter a valid age.');
      return;
    }
    if (_nameController.text.trim().isEmpty ||
        _addressController.text.trim().isEmpty ||
        _intentController.text.trim().isEmpty) {
      setState(() => _error = 'Complete your name, address and help intent.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.identity.completeOnboarding(
        name: _nameController.text.trim(),
        phone: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        age: age,
        helpIntent: _intentController.text.trim(),
        capabilities: _capabilities.toList(),
        memoryConsent: _memoryConsent,
      );
      if (mounted) widget.onComplete();
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _next() {
    if (_step == 0) {
      if (_challengeId == null) {
        _sendOtp();
      } else {
        _verifyOtp();
      }
      return;
    }
    if (_step < 3) {
      setState(() {
        _step++;
        _error = null;
      });
    } else {
      _complete();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: _step == 0
            ? null
            : IconButton(
                onPressed: _saving ? null : () => setState(() => _step--),
                icon: const Icon(Icons.arrow_back),
              ),
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
                child: _page(),
              ),
            ),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 10),
                child: Text(
                  _error!,
                  style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 20),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: (_saving || _sendingOtp || _verifyingOtp)
                      ? null
                      : _next,
                  child: Text(_buttonLabel),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String get _buttonLabel {
    if (_step == 0) {
      if (_sendingOtp) return 'Sending code…';
      if (_verifyingOtp) return 'Verifying…';
      return _challengeId == null ? 'Send OTP' : 'Verify phone';
    }
    if (_saving) return 'Preparing your workspace…';
    return _step == 3 ? 'Enter SAGE ONE' : 'Continue';
  }

  Widget _page() {
    switch (_step) {
      case 0:
        return _phonePage();
      case 1:
        return _profilePage();
      case 2:
        return _capabilitiesPage();
      default:
        return _memoryPage();
    }
  }

  Widget _heading(String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Colors.cyanAccent, size: 34),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, height: 1.45),
          ),
          const SizedBox(height: 24),
        ],
      );

  Widget _field(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboardType,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      );

  Widget _phonePage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Verify your phone.',
            'SAGE uses your verified number to protect your account and complete onboarding.',
          ),
          _field(
            _phoneController,
            'Phone number',
            Icons.phone_outlined,
            keyboardType: TextInputType.phone,
          ),
          if (_challengeId != null) ...[
            _field(
              _otpController,
              '6-digit code',
              Icons.password_outlined,
              keyboardType: TextInputType.number,
            ),
            Text(
              _delivery == 'not_configured'
                  ? 'SMS delivery is not configured on this server yet.'
                  : 'Verification code sent to your number.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            TextButton(
              onPressed: _sendingOtp || _verifyingOtp ? null : _sendOtp,
              child: const Text('Send a new code'),
            ),
          ],
        ],
      );

  Widget _profilePage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Complete your profile.',
            'A few basics give SAGE the context it needs to become useful to you.',
          ),
          _field(_nameController, 'Your name', Icons.person_outline),
          _field(
            _addressController,
            'Address',
            Icons.location_on_outlined,
          ),
          _field(
            _ageController,
            'Age',
            Icons.cake_outlined,
            keyboardType: TextInputType.number,
          ),
        ],
      );

  Widget _capabilitiesPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'What should SAGE understand?',
            'Choose your capabilities and tell SAGE what you want to accomplish.',
          ),
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
          const SizedBox(height: 20),
          TextField(
            controller: _intentController,
            minLines: 5,
            maxLines: 8,
            decoration: InputDecoration(
              labelText: 'What should SAGE help with?',
              hintText: 'Build my business, create content, learn new skills…',
              alignLabelWithHint: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      );

  Widget _memoryPage() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _heading(
            'Memory & privacy',
            'Your information stays under your control. SAGE learns from private context only with your permission.',
          ),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(.035),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.blueAccent.withOpacity(.20),
              ),
            ),
            child: const Column(
              children: [
                _PrivacyRow(
                  icon: Icons.lock_outline,
                  title: 'You control memory',
                  text: 'You can view, edit or delete saved memories.',
                ),
                _PrivacyRow(
                  icon: Icons.visibility_outlined,
                  title: 'Learning is permission-based',
                  text: 'SAGE does not silently turn private context into memory.',
                ),
                _PrivacyRow(
                  icon: Icons.public,
                  title: 'World Intelligence is separate',
                  text: 'Public-world knowledge stays separate from personal memory.',
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          SwitchListTile.adaptive(
            value: _memoryConsent,
            onChanged: (value) => setState(() => _memoryConsent = value),
            title: const Text(
              'Allow SAGE to remember useful setup preferences',
            ),
            subtitle: const Text('You can change or delete memory later.'),
            contentPadding: EdgeInsets.zero,
          ),
        ],
      );
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({
    required this.icon,
    required this.title,
    required this.text,
  });

  final IconData icon;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
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
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    text,
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 12,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}
