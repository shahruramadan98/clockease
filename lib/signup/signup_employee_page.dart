import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../home_page.dart';

class SignUpEmployeePage extends StatefulWidget {
  final String companyId;

  const SignUpEmployeePage({
    super.key,
    required this.companyId,
  });

  @override
  State<SignUpEmployeePage> createState() => _SignUpEmployeePageState();
}

class _SignUpEmployeePageState extends State<SignUpEmployeePage> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _employeeIdController = TextEditingController();
  final _fullNameController = TextEditingController();
  final _designationController = TextEditingController();

  bool _isLoading = false;

  Future<void> _submitAdminSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // 🔹 Create ADMIN Auth account
      UserCredential credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final uid = credential.user!.uid;

      // 🔹 Create admin employee profile
      await FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .collection('employees')
          .doc(uid)
          .set({
        'uid': uid,
        'email': _emailController.text.trim(),
        'fullName': _fullNameController.text.trim(),
        'employeeId': _employeeIdController.text.trim(),
        'designation': _designationController.text.trim(),
        'isAdmin': true,
        'companyId': widget.companyId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // 🔹 Go to Staff Home
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Signup failed: $e')));
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
                      'Admin Registration',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                    ),
                    Container(
                      height: 4,
                      width: 120,
                      color: const Color(0xFF4CBFDA),
                      margin: const EdgeInsets.only(top: 4),
                    ),
                    
                    const SizedBox(height: 40),

                    TextFormField(
                      controller: _emailController,
                      decoration: const InputDecoration(
                        hintText: 'Admin Email',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (v) => v!.isEmpty ? 'Enter email' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        hintText: 'Password',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.length < 6 ? 'Minimum 6 characters' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _employeeIdController,
                      decoration: const InputDecoration(
                        hintText: 'Employee ID',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Enter employee ID' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _fullNameController,
                      decoration: const InputDecoration(
                        hintText: 'Full Name',
                        border: UnderlineInputBorder(),
                      ),
                      validator: (v) =>
                          v!.isEmpty ? 'Enter full name' : null,
                    ),
                    const SizedBox(height: 20),

                    TextFormField(
                      controller: _designationController,
                      decoration: const InputDecoration(
                        hintText: 'Designation',
                        border: UnderlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _submitAdminSignup,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3470D9),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Sign Up',
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
