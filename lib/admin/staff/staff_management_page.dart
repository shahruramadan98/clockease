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
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () => _showDeleteConfirmDialog(context, emp),
                              tooltip: 'Delete User',
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
    
    // Default schedule: 8:00 AM - 5:00 PM
    TimeOfDay workStartTime = const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay workEndTime = const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Add Staff'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _field(emailController, 'Email'),
                    _field(passwordController, 'Temporary Password',
                        obscure: true),
                    _field(empIdController, 'Employee ID'),
                    _field(nameController, 'Full Name'),
                    _field(designationController, 'Designation'),
                    const SizedBox(height: 8),
                    const Divider(),
                    const SizedBox(height: 8),
                    const Text(
                      'Work Schedule',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 12),
                    // Work Start Time
                    ListTile(
                      leading: const Icon(Icons.access_time, color: Color(0xFF3BAECC)),
                      title: const Text('Start Time'),
                      subtitle: Text(workStartTime.format(context)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: workStartTime,
                        );
                        if (time != null) {
                          setDialogState(() => workStartTime = time);
                        }
                      },
                    ),
                    // Work End Time
                    ListTile(
                      leading: const Icon(Icons.access_time_filled, color: Color(0xFF3BAECC)),
                      title: const Text('End Time'),
                      subtitle: Text(workEndTime.format(context)),
                      trailing: const Icon(Icons.edit),
                      onTap: () async {
                        final time = await showTimePicker(
                          context: context,
                          initialTime: workEndTime,
                        );
                        if (time != null) {
                          setDialogState(() => workEndTime = time);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
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

                      // Format schedule times as "HH:mm"
                      final workStart = '${workStartTime.hour.toString().padLeft(2, '0')}:${workStartTime.minute.toString().padLeft(2, '0')}';
                      final workEnd = '${workEndTime.hour.toString().padLeft(2, '0')}:${workEndTime.minute.toString().padLeft(2, '0')}';

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
                        'workStartTime': workStart,
                        'workEndTime': workEnd,
                        'createdAt':
                            FieldValue.serverTimestamp(),
                      });

                      Navigator.pop(dialogContext);
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                    }
                  },
                ),
              ],
            );
          },
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
    
    // Parse existing schedule or use defaults
    TimeOfDay workStartTime = _parseTimeOfDay(data['workStartTime']) ?? const TimeOfDay(hour: 8, minute: 0);
    TimeOfDay workEndTime = _parseTimeOfDay(data['workEndTime']) ?? const TimeOfDay(hour: 17, minute: 0);

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Edit Staff',
                style: TextStyle(
                  color: Color(0xFF3F51B5),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: SingleChildScrollView(
                child: SizedBox(
                  width: MediaQuery.of(context).size.width * 0.9,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Email Field
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: emailController,
                            decoration: const InputDecoration(
                              labelText: 'Email',
                              prefixIcon: Icon(Icons.email, color: Color(0xFF3BAECC)),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            keyboardType: TextInputType.emailAddress,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Employee ID Field
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: empIdController,
                            decoration: const InputDecoration(
                              labelText: 'Employee ID',
                              prefixIcon: Icon(Icons.badge, color: Color(0xFF3BAECC)),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Full Name Field
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: nameController,
                            decoration: const InputDecoration(
                              labelText: 'Full Name',
                              prefixIcon: Icon(Icons.person, color: Color(0xFF3BAECC)),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Designation Field
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: designationController,
                            decoration: const InputDecoration(
                              labelText: 'Designation',
                              prefixIcon: Icon(Icons.work, color: Color(0xFF3BAECC)),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            textCapitalization: TextCapitalization.words,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Phone Number Field
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: TextFormField(
                            controller: phoneController,
                            decoration: const InputDecoration(
                              labelText: 'Phone Number',
                              prefixIcon: Icon(Icons.phone, color: Color(0xFF3BAECC)),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            keyboardType: TextInputType.phone,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Gender Dropdown
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: DropdownButtonFormField<String>(
                            value: selectedGender,
                            decoration: const InputDecoration(
                              labelText: 'Gender',
                              prefixIcon: Icon(Icons.person_outline, color: Color(0xFF3BAECC)),
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                      ),
                      const SizedBox(height: 12),
                      
                      // Work Schedule Section
                      const Divider(thickness: 2),
                      const SizedBox(height: 12),
                      const Text(
                        'Work Schedule',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      const SizedBox(height: 12),
                      
                      // Work Start Time
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.access_time, color: Color(0xFF3BAECC)),
                          title: const Text('Start Time'),
                          subtitle: Text(workStartTime.format(context)),
                          trailing: const Icon(Icons.edit, color: Color(0xFF3470D9)),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: workStartTime,
                            );
                            if (time != null) {
                              setDialogState(() => workStartTime = time);
                            }
                          },
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      // Work End Time
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          leading: const Icon(Icons.access_time_filled, color: Color(0xFF3BAECC)),
                          title: const Text('End Time'),
                          subtitle: Text(workEndTime.format(context)),
                          trailing: const Icon(Icons.edit, color: Color(0xFF3470D9)),
                          onTap: () async {
                            final time = await showTimePicker(
                              context: context,
                              initialTime: workEndTime,
                            );
                            if (time != null) {
                              setDialogState(() => workEndTime = time);
                            }
                          },
                        ),
                      ),
                      
                      // Admin Status Toggle
                      Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SwitchListTile(
                          title: const Text(
                            'Admin Access',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          subtitle: const Text(
                            'Grant admin panel access',
                            style: TextStyle(fontSize: 13),
                          ),
                          value: isAdmin,
                          activeColor: const Color(0xFF3470D9),
                          onChanged: (value) {
                            setDialogState(() => isAdmin = value);
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isSaving ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3BAECC),
                    foregroundColor: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
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
                              'workStartTime': '${workStartTime.hour.toString().padLeft(2, '0')}:${workStartTime.minute.toString().padLeft(2, '0')}',
                              'workEndTime': '${workEndTime.hour.toString().padLeft(2, '0')}:${workEndTime.minute.toString().padLeft(2, '0')}',
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
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Icon(Icons.save, size: 18),
                            SizedBox(width: 8),
                            Text('Save Changes'),
                          ],
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================================
  // DELETE STAFF CONFIRMATION DIALOG
  // ================================
  void _showDeleteConfirmDialog(BuildContext context, DocumentSnapshot emp) {
    final data = emp.data() as Map<String, dynamic>;
    final String userName = data['fullName'] ?? 'this user';
    final String userEmail = data['email'] ?? '';
    final String userId = emp.id;

    showDialog(
      context: context,
      builder: (dialogContext) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text(
                'Delete User Account',
                style: TextStyle(color: Colors.red),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Are you sure you want to delete $userName?',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This will permanently delete:',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  Text('• User account ($userEmail)',
                      style: const TextStyle(fontSize: 13)),
                  const Text('• All attendance records',
                      style: TextStyle(fontSize: 13)),
                  const Text('• All leave applications',
                      style: TextStyle(fontSize: 13)),
                  const Text('• All associated data',
                      style: TextStyle(fontSize: 13)),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.error_outline,
                            color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'This action cannot be undone!',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                  ),
                  onPressed: isDeleting
                      ? null
                      : () async {
                          setDialogState(() => isDeleting = true);

                          try {
                            // Get current user to prevent self-deletion
                            final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                            
                            if (userId == currentUserId) {
                              if (context.mounted) {
                                Navigator.pop(dialogContext);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('You cannot delete your own account!'),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                              return;
                            }

                            // Delete user data from Firestore
                            // 1. Delete employee document
                            await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(companyId)
                                .collection('employees')
                                .doc(userId)
                                .delete();

                            // 2. Delete attendance records (if any)
                            final attendanceSnapshot = await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(companyId)
                                .collection('attendance')
                                .where('userId', isEqualTo: userId)
                                .get();

                            for (var doc in attendanceSnapshot.docs) {
                              await doc.reference.delete();
                            }

                            // 3. Delete leave applications (if any)
                            final leaveSnapshot = await FirebaseFirestore.instance
                                .collection('companies')
                                .doc(companyId)
                                .collection('leaves')
                                .where('userId', isEqualTo: userId)
                                .get();

                            for (var doc in leaveSnapshot.docs) {
                              await doc.reference.delete();
                            }

                            // Note: Firebase Authentication accounts cannot be deleted
                            // from the client side due to security rules. The user's
                            // Firebase Auth account will remain but won't have access
                            // to company data. Consider using Cloud Functions for
                            // complete deletion including Firebase Auth.

                            if (context.mounted) {
                              Navigator.pop(dialogContext);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('$userName has been deleted successfully'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          } catch (e) {
                            setDialogState(() => isDeleting = false);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Error deleting user: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                  child: isDeleting
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Delete Permanently',
                          style: TextStyle(color: Colors.white),
                        ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Helper method to parse TimeOfDay from Firestore format ("HH:mm")
  TimeOfDay? _parseTimeOfDay(String? timeString) {
    if (timeString == null || timeString.isEmpty) return null;
    
    try {
      final parts = timeString.split(':');
      if (parts.length != 2) return null;
      
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      
      if (hour < 0 || hour > 23 || minute < 0 || minute > 59) return null;
      
      return TimeOfDay(hour: hour, minute: minute);
    } catch (e) {
      return null;
    }
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
