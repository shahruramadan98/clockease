import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'signup_employee_page.dart';

class SignUpCompanyPage extends StatefulWidget {
  const SignUpCompanyPage({super.key});

  @override
  State<SignUpCompanyPage> createState() => _SignUpCompanyPageState();
}

class _SignUpCompanyPageState extends State<SignUpCompanyPage> {
  final _formKey = GlobalKey<FormState>();
  final _companyNameController = TextEditingController();
  final _companyEmailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _registerCompany() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Create company in Firebase Auth
      UserCredential userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
        email: _companyEmailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      String companyUid = userCredential.user!.uid;

      // 2. Save company info in Firestore
      await FirebaseFirestore.instance.collection('companies').doc(companyUid).set({
        'companyName': _companyNameController.text.trim(),
        'companyEmail': _companyEmailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 3. Navigate to admin info page
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SignUpEmployeePage(
              companyUid: companyUid,
              companyEmail: _companyEmailController.text.trim(),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? 'Registration failed')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: TrianglePainter(color: const Color(0xFF4CBFDA), isTopLeft: true),
            ),
          ),
          Positioned(
            bottom: 0,
            right: 0,
            child: CustomPaint(
              size: const Size(200, 200),
              painter: TrianglePainter(color: const Color(0xFF4CBFDA), isTopLeft: false),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    Image.asset('assets/images/logo.png', height: 80),
                    const SizedBox(height: 8),
                    const Text(
                      'Sign Up',
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                    ),
                    Container(height: 4, width: 100, color: const Color(0xFF4CBFDA), margin: const EdgeInsets.only(top: 4)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _companyNameController,
                      decoration: const InputDecoration(hintText: 'Company Name', border: UnderlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter company name' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _companyEmailController,
                      decoration: const InputDecoration(hintText: 'Company Email', border: UnderlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter company email' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Password', border: UnderlineInputBorder()),
                      validator: (v) => v!.length < 6 ? 'Password must be at least 6 characters' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _confirmPasswordController,
                      obscureText: true,
                      decoration: const InputDecoration(hintText: 'Confirm Password', border: UnderlineInputBorder()),
                    ),
                    const SizedBox(height: 30),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3470D9),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: _isLoading ? null : _registerCompany,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Next', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ),
                    ),
                    const SizedBox(height: 40),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Already have an account? Login', style: TextStyle(color: Color(0xFF3F51B5))),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrianglePainter extends CustomPainter {
  final Color color;
  final bool isTopLeft;
  TrianglePainter({required this.color, this.isTopLeft = true});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final path = Path();
    if (isTopLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(0, size.height);
      path.lineTo(size.width, 0);
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
