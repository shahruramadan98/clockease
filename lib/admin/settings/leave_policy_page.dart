import 'package:flutter/material.dart';
import '../../models/leave_policy.dart';
import '../../services/company_settings_service.dart';

class LeavePolicyPage extends StatefulWidget {
  final String companyId;

  const LeavePolicyPage({
    super.key,
    required this.companyId,
  });

  @override
  State<LeavePolicyPage> createState() => _LeavePolicyPageState();
}

class _LeavePolicyPageState extends State<LeavePolicyPage> {
  final _service = CompanySettingsService();

  final _annualCtrl = TextEditingController();
  final _sickCtrl = TextEditingController();

  bool unpaidAllowed = false;
  bool halfDayAllowed = false;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  Future<void> _loadPolicy() async {
    final policy = await _service.getLeavePolicy(widget.companyId);

    if (policy != null) {
      _annualCtrl.text = policy.annualLeave.toString();
      _sickCtrl.text = policy.sickLeave.toString();
      unpaidAllowed = policy.unpaidAllowed;
      halfDayAllowed = policy.halfDayAllowed;
    }

    setState(() => loading = false);
  }

  Future<void> _save() async {
    final policy = LeavePolicy(
      annualLeave: int.parse(_annualCtrl.text),
      sickLeave: int.parse(_sickCtrl.text),
      unpaidAllowed: unpaidAllowed,
      halfDayAllowed: halfDayAllowed,
    );

    await _service.saveLeavePolicy(widget.companyId, policy);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Leave policy updated"),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF4CBFDA),
        title: const Text(
          'Company Leave Policy',
          style: TextStyle(
            color: Color.fromARGB(255, 254, 254, 254),
          ),
        ),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color.fromARGB(255, 255, 255, 255)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _numberField("Annual Leave (days)", _annualCtrl),
            const SizedBox(height: 12),
            _numberField("Sick Leave (days)", _sickCtrl),
            const SizedBox(height: 20),

            SwitchListTile(
              title: const Text("Allow Unpaid Leave"),
              value: unpaidAllowed,
              onChanged: (v) => setState(() => unpaidAllowed = v),
            ),

            SwitchListTile(
              title: const Text("Allow Half-Day Leave"),
              value: halfDayAllowed,
              onChanged: (v) => setState(() => halfDayAllowed = v),
            ),

            const Spacer(),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3BAECC),
                  foregroundColor: Colors.white, // text color
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
                child: const Text("Save Policy"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numberField(String label, TextEditingController ctrl) {
    return TextField(
      controller: ctrl,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
    );
  }
}
