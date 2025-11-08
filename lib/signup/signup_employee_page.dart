import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page.dart';

class SignUpEmployeePage extends StatefulWidget {
  final String companyUid;
  final String companyEmail;

  const SignUpEmployeePage({
    super.key,
    required this.companyUid,
    required this.companyEmail,
  });

  @override
  State<SignUpEmployeePage> createState() => _SignUpEmployeePageState();
}

class _SignUpEmployeePageState extends State<SignUpEmployeePage> {
  final _formKey = GlobalKey<FormState>();
  final _employeeIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _designationController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitAdminInfo() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyUid)
          .collection('employees')
          .doc(widget.companyUid) // admin document
          .set({
        'employeeId': _employeeIdController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'designation': _designationController.text.trim(),
        'email': widget.companyEmail,
        'role': 'admin',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const HomePage()),
          (route) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to save admin info: $e')),
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
                      'Tell us a little bit about you',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Container(height: 4, width: 245, color: const Color(0xFF4CBFDA), margin: const EdgeInsets.only(top: 4)),
                    const SizedBox(height: 40),
                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(hintText: 'Employee ID', border: UnderlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter employee ID' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(hintText: 'Full Name', border: UnderlineInputBorder()),
                      validator: (v) => v!.isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _designationController,
                      decoration: const InputDecoration(hintText: 'Designation', border: UnderlineInputBorder()),
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
                        onPressed: _isLoading ? null : _submitAdminInfo,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text('Sign Up', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
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
