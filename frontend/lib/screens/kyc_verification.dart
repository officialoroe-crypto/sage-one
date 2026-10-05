import 'package:flutter/material.dart';

class KycVerificationScreen extends StatefulWidget {
  const KycVerificationScreen({required this.onComplete, super.key});
  final ValueChanged<Map<String, dynamic>> onComplete;

  @override
  State<KycVerificationScreen> createState() => _KycVerificationScreenState();
}

class _KycVerificationScreenState extends State<KycVerificationScreen> {
  int _step = 0;
  static const _steps = <({String title, String subtitle, IconData icon})>[
    (title: 'Identity document', subtitle: 'Prepare a valid Nepal identity document for verification.', icon: Icons.badge_outlined),
    (title: 'Face verification', subtitle: 'Your face will be matched against the verified identity.', icon: Icons.face_retouching_natural),
    (title: 'Review & consent', subtitle: 'Review what SAGE will use for identity and account protection.', icon: Icons.verified_user_outlined),
  ];

  void _continue() {
    if (_step < _steps.length - 1) {
      setState(() => _step += 1);
      return;
    }
    widget.onComplete({'status': 'ready_for_verification', 'verification_method': 'document_and_face', 'country': 'NP'});
  }

  @override
  Widget build(BuildContext context) {
    final step = _steps[_step];
    final stepLabel = 'STEP ' + (_step + 1).toString() + ' OF ' + _steps.length.toString();
    final buttonLabel = _step == _steps.length - 1 ? 'Continue to verification' : 'Continue';
    return Scaffold(
      backgroundColor: const Color(0xFF020306),
      body: Stack(
        children: [
          const Positioned.fill(child: _KycBackdrop()),
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 28),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _KycMark(),
                      const SizedBox(height: 22),
                      const Text('IDENTITY VERIFICATION', textAlign: TextAlign.center, style: TextStyle(color: Colors.white, fontSize: 20, letterSpacing: 3.5, fontWeight: FontWeight.w400)),
                      const SizedBox(height: 8),
                      Text('Secure your SAGE ONE account before protected services are enabled.', textAlign: TextAlign.center, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white54, height: 1.45)),
                      const SizedBox(height: 28),
                      Row(children: List.generate(_steps.length, (index) => Expanded(child: Container(height: 3, margin: EdgeInsets.only(right: index == _steps.length - 1 ? 0 : 7), decoration: BoxDecoration(color: index <= _step ? const Color(0xFF17D8FF) : Colors.white.withOpacity(.08), borderRadius: BorderRadius.circular(99)))))),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(color: const Color(0xFF06101A).withOpacity(.82), borderRadius: BorderRadius.circular(26), border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.10))),
                        child: Column(
                          children: [
                            Container(width: 76, height: 76, decoration: BoxDecoration(shape: BoxShape.circle, color: const Color(0xFF17D8FF).withOpacity(.06), border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.24))), child: Icon(step.icon, color: const Color(0xFF8BEAFF), size: 34)),
                            const SizedBox(height: 22),
                            Text(stepLabel, style: const TextStyle(color: Color(0xFF17D8FF), fontSize: 11, letterSpacing: 2.2, fontWeight: FontWeight.w700)),
                            const SizedBox(height: 10),
                            Text(step.title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 10),
                            Text(step.subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white54, fontSize: 14, height: 1.5)),
                            const SizedBox(height: 26),
                            if (_step == 2) const _ConsentNotice(),
                            if (_step == 2) const SizedBox(height: 22),
                            SizedBox(width: double.infinity, height: 54, child: FilledButton(onPressed: _continue, style: FilledButton.styleFrom(backgroundColor: const Color(0xFF0C6179), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))), child: Text(buttonLabel))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      const Text('SAGE does not treat this screen as proof of identity. Verification is completed only after the connected verification service confirms the submitted information.', textAlign: TextAlign.center, style: TextStyle(color: Colors.white24, fontSize: 11, height: 1.45)),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsentNotice extends StatelessWidget {
  const _ConsentNotice();
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(color: const Color(0xFF17D8FF).withOpacity(.04), borderRadius: BorderRadius.circular(14), border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.10))),
    child: const Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Icon(Icons.lock_outline, color: Color(0xFF17D8FF), size: 18),
      SizedBox(width: 10),
      Expanded(child: Text('Identity information is used for account protection and regulated features. You remain in control of the verification step.', style: TextStyle(color: Colors.white54, fontSize: 12, height: 1.45))),
    ]),
  );
}

class _KycMark extends StatelessWidget {
  const _KycMark();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 72, height: 72,
      decoration: BoxDecoration(shape: BoxShape.circle, gradient: const RadialGradient(colors: [Color(0xFF173B61), Color(0xFF06101A), Color(0xFF020306)]), border: Border.all(color: const Color(0xFF17D8FF).withOpacity(.35)), boxShadow: [BoxShadow(color: const Color(0xFF17D8FF).withOpacity(.13), blurRadius: 28, spreadRadius: 4)]),
      child: const Center(child: Text('S', style: TextStyle(color: Color(0xFFBDF5FF), fontSize: 38, fontWeight: FontWeight.w200))),
    ),
  );
}

class _KycBackdrop extends StatelessWidget {
  const _KycBackdrop();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: RadialGradient(center: const Alignment(0, -.35), radius: 1.15, colors: [const Color(0xFF0A2340).withOpacity(.68), const Color(0xFF030812).withOpacity(.95), const Color(0xFF020306)], stops: const [0, .5, 1]),
    ),
  );
}
