import 'package:flutter/material.dart';
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
  bool _isLoading = false;

  @override
  void dispose() {
    _companyNameController.dispose();
    _companyEmailController.dispose();
    super.dispose();
  }

  Future<void> _registerCompany() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 🔹 Create company (Firestore only)
      final companyRef =
          FirebaseFirestore.instance.collection('companies').doc();

      await companyRef.set({
        'companyName': _companyNameController.text.trim(),
        'companyEmail': _companyEmailController.text.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Go to Admin Signup
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SignUpEmployeePage(
              companyId: companyRef.id,
            ),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
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
          // TOP LEFT TRIANGLE
          Positioned(
            top: 0,
            left: 0,
            child: ClipPath(
              clipper: _TriangleClipper(true),
              child: Container(
                height: 200,
                width: 200,
                color: const Color(0xFF4CBFDA),
              ),
            ),
          ),
  

          // BOTTOM RIGHT TRIANGLE
          Positioned(
            bottom: 0,
            right: 0,
            child: ClipPath(
              clipper: _TriangleClipper(false),
              child: Container(
                height: 200,
                width: 200,
                color: const Color(0xFF4CBFDA),
              ),
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
                  const SizedBox(height: 10),
                  const Text(
                    'Company Registration',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                  ),
                  Container(
                    height: 4,
                    width: 120,
                    color: const Color(0xFF4CBFDA),
                    margin: const EdgeInsets.only(top: 4),
                  ),

                  const SizedBox(height: 40),

                  TextFormField(
                    controller: _companyNameController,
                    decoration: const InputDecoration(
                      hintText: 'Company Name',
                      border: UnderlineInputBorder(),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Enter company name' : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _companyEmailController,
                    decoration: const InputDecoration(
                      hintText: 'Company Email',
                      border: UnderlineInputBorder(),
                    ),
                    validator: (v) =>
                        v!.isEmpty ? 'Enter company email' : null,
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _registerCompany,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3470D9),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              'Next',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
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

class _TriangleClipper extends CustomClipper<Path> {
  final bool isTopLeft;
  _TriangleClipper(this.isTopLeft);

  @override
  Path getClip(Size size) {
    final path = Path();
    if (isTopLeft) {
      path.moveTo(0, 0);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    } else {
      path.moveTo(size.width, size.height);
      path.lineTo(size.width, 0);
      path.lineTo(0, size.height);
    }
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}
