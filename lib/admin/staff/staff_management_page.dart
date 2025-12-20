import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StaffManagementPage extends StatelessWidget {
  final String companyId;

  const StaffManagementPage({
    super.key,
    required this.companyId,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ==========================
          // PAGE TITLE
          // ==========================
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Staff Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF3F51B5)
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Create and manage staff accounts',
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),

          // ==========================
          // CONTENT
          // ==========================
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('companies')
                  .doc(companyId)
                  .collection('employees')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                final staff = snapshot.data!.docs;

                if (staff.isEmpty) {
                  return const Center(
                    child: Text(
                      'No staff added yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding:
                      const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: staff.length,
                  itemBuilder: (context, index) {
                    final emp = staff[index];

                    return Card(
                      margin:
                          const EdgeInsets.only(bottom: 10),
                      child: ListTile(
                        title: Text(emp['fullName']),
                        subtitle: Text(emp['designation']),
                        trailing: Chip(
                          label: Text(
                            emp['isAdmin'] ? 'Admin' : 'Staff',
                            style: const TextStyle(
                                color: Colors.white),
                          ),
                          backgroundColor: emp['isAdmin']
                              ? Colors.blue
                              : const Color.fromARGB(255, 158, 158, 158),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ==========================
          // ADD STAFF BUTTON
          // ==========================
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.person_add, color: Color.fromARGB(255, 255, 255, 255),),
                label: const Text(
                  'Add Staff',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                  ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BAECC),
                  padding:
                      const EdgeInsets.symmetric(vertical: 14),
                ),
                onPressed: () =>
                    _showAddStaffDialog(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================================
  // ADD STAFF DIALOG
  // ================================
  void _showAddStaffDialog(BuildContext context) {
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    final nameController = TextEditingController();
    final empIdController = TextEditingController();
    final designationController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Add Staff'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _field(emailController, 'Email'),
                _field(passwordController, 'Temporary Password',
                    obscure: true),
                _field(empIdController, 'Employee ID'),
                _field(nameController, 'Full Name'),
                _field(designationController, 'Designation'),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              child: const Text('Create'),
              onPressed: () async {
                try {
                  final credential = await FirebaseAuth
                      .instance
                      .createUserWithEmailAndPassword(
                    email: emailController.text.trim(),
                    password:
                        passwordController.text.trim(),
                  );

                  final uid = credential.user!.uid;

                  await FirebaseFirestore.instance
                      .collection('companies')
                      .doc(companyId)
                      .collection('employees')
                      .doc(uid)
                      .set({
                    'uid': uid,
                    'email': emailController.text.trim(),
                    'employeeId':
                        empIdController.text.trim(),
                    'fullName': nameController.text.trim(),
                    'designation':
                        designationController.text.trim(),
                    'isAdmin': false,
                    'companyId': companyId,
                    'createdAt':
                        FieldValue.serverTimestamp(),
                  });

                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(
                    SnackBar(
                        content:
                            Text('Error: $e')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Widget _field(TextEditingController c, String label,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: obscure,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }
}
