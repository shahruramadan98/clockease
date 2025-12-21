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
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Chip(
                              label: Text(
                                emp['isAdmin'] ? 'Admin' : 'Staff',
                                style: const TextStyle(
                                    color: Colors.white),
                              ),
                              backgroundColor: emp['isAdmin']
                                  ? Colors.blue
                                  : const Color.fromARGB(255, 158, 158, 158),
                            ),
                            IconButton(
                              icon: const Icon(Icons.edit, color: Color(0xFF3470D9)),
                              onPressed: () => _showEditStaffDialog(context, emp),
                              tooltip: 'Edit Staff',
                            ),
                          ],
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

  // ================================
  // EDIT STAFF DIALOG
  // ================================
  void _showEditStaffDialog(BuildContext context, DocumentSnapshot emp) {
    final data = emp.data() as Map<String, dynamic>;
    
    final emailController = TextEditingController(text: data['email'] ?? '');
    final nameController = TextEditingController(text: data['fullName'] ?? '');
    final empIdController = TextEditingController(text: data['employeeId'] ?? '');
    final designationController = TextEditingController(text: data['designation'] ?? '');
    final phoneController = TextEditingController(text: data['phoneNumber'] ?? '');
    
    String? selectedGender = data['gender'];
    bool isAdmin = data['isAdmin'] ?? false;
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Staff'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(emailController, 'Email'),
                    _field(empIdController, 'Employee ID'),
                    _field(nameController, 'Full Name'),
                    _field(designationController, 'Designation'),
                    _field(phoneController, 'Phone Number'),
                    
                    // Gender Dropdown
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: DropdownButtonFormField<String>(
                        value: selectedGender,
                        decoration: const InputDecoration(
                          labelText: 'Gender',
                          border: OutlineInputBorder(),
                        ),
                        items: const [
                          DropdownMenuItem(value: null, child: Text('Not set')),
                          DropdownMenuItem(value: 'Male', child: Text('Male')),
                          DropdownMenuItem(value: 'Female', child: Text('Female')),
                          DropdownMenuItem(value: 'Other', child: Text('Other')),
                        ],
                        onChanged: (value) {
                          setDialogState(() => selectedGender = value);
                        },
                      ),
                    ),
                    
                    // Admin Status Toggle
                    SwitchListTile(
                      title: const Text('Admin Access'),
                      subtitle: const Text('Grant admin panel access'),
                      value: isAdmin,
                      activeColor: const Color(0xFF3470D9),
                      onChanged: (value) {
                        setDialogState(() => isAdmin = value);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: isSaving
                      ? null
                      : () async {
                          // Validation
                          if (emailController.text.trim().isEmpty ||
                              nameController.text.trim().isEmpty ||
                              empIdController.text.trim().isEmpty ||
                              designationController.text.trim().isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill in all required fields'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                            return;
                          }

                          setDialogState(() => isSaving = true);

                          try {
                            final updates = {
                              'email': emailController.text.trim(),
                              'fullName': nameController.text.trim(),
                              'employeeId': empIdController.text.trim(),
                              'designation': designationController.text.trim(),
                              'phoneNumber': phoneController.text.trim().isEmpty 
                                  ? null 
                                  : phoneController.text.trim(),
                              'gender': selectedGender,
                              'isAdmin': isAdmin,
                            };

                            await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(companyId)
                                .collection('employees')
                                .doc(emp.id)
                                .update(updates);

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Staff updated successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isSaving = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error updating staff: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Changes'),
                ),
              ],
            );
          },
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
