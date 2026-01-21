// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/theme_service.dart';

class EditProfileModal extends StatefulWidget {
  final Map<String, dynamic> user;
  final VoidCallback onClose;

  const EditProfileModal({
    super.key,
    required this.user,
    required this.onClose,
  });

  @override
  State<EditProfileModal> createState() => _EditProfileModalState();
}

class _EditProfileModalState extends State<EditProfileModal> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _emergencyController;

  bool _showPasswordFields = false;
  final TextEditingController _currentPassController = TextEditingController();
  final TextEditingController _newPassController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user['fullName']);
    _emailController = TextEditingController(text: widget.user['email']);
    _emergencyController = TextEditingController(
      text: widget.user['emergencyContact'],
    );
  }

  Future<void> _handleSave() async {
    await DatabaseService.instance.updateUser(
      widget.user['email'],
      _nameController.text,
      _emergencyController.text,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Profile Updated Successfully"),
          backgroundColor: Theme.of(context).primaryColor,
        ),
      );
      widget.onClose();
    }
  }

  Future<void> _deleteData() async {
    final db = await DatabaseService.instance.database;
    await db.delete('trips');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("All Trip Data Deleted"),
          backgroundColor: ThemeService.red,
        ),
      );
      widget.onClose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textColor = theme.textTheme.bodyMedium!.color;
    final subColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = theme.dividerColor;
    final green = theme.primaryColor;

    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        color: Colors.black54,
        alignment: Alignment.bottomCenter,
        child: GestureDetector(
          onTap: () {},
          child: Container(
            height: MediaQuery.of(context).size.height * 0.85,
            decoration: BoxDecoration(
              color: theme.scaffoldBackgroundColor, // ✅ Dynamic BG
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: green.withOpacity(0.5)),
                            ),
                            child: Icon(Icons.person, color: green, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "تعديل الملف الشخصي",
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Text(
                                "قم بتحديث معلوماتك",
                                style: TextStyle(color: subColor, fontSize: 12),
                              ),
                            ],
                          ),
                        ],
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: subColor),
                        onPressed: widget.onClose,
                      ),
                    ],
                  ),
                ),

                // Form Content
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      _buildInput(
                        "الاسم الكامل",
                        Icons.person,
                        _nameController,
                        theme,
                      ),
                      _buildInput(
                        "البريد الإلكتروني",
                        Icons.email,
                        _emailController,
                        theme,
                        readOnly: true,
                      ),
                      _buildInput(
                        "رقم الطوارئ",
                        Icons.phone,
                        _emergencyController,
                        theme,
                      ),

                      const SizedBox(height: 20),
                      Divider(color: borderColor),
                      const SizedBox(height: 10),

                      // Password Section
                      if (!_showPasswordFields)
                        _buildSettingsButton(
                          "تغيير كلمة المرور",
                          Icons.lock,
                          ThemeService.purple,
                          () => setState(() => _showPasswordFields = true),
                          theme,
                        )
                      else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "تغيير كلمة المرور",
                              style: TextStyle(
                                color: ThemeService.purple,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  setState(() => _showPasswordFields = false),
                              child: const Text(
                                "إلغاء",
                                style: TextStyle(color: Colors.grey),
                              ),
                            ),
                          ],
                        ),
                        _buildInput(
                          "كلمة المرور الحالية",
                          Icons.lock_outline,
                          _currentPassController,
                          theme,
                          isPass: true,
                        ),
                        _buildInput(
                          "كلمة المرور الجديدة",
                          Icons.lock,
                          _newPassController,
                          theme,
                          isPass: true,
                        ),
                      ],

                      const SizedBox(height: 20),
                      Divider(color: borderColor),
                      const SizedBox(height: 10),

                      // Delete Data
                      _buildSettingsButton(
                        "حذف جميع البيانات",
                        Icons.delete_forever,
                        ThemeService.red,
                        () => _confirmDelete(context),
                        theme,
                        subtitle: "سيتم حذف جميع رحلاتك وبياناتك",
                      ),

                      const SizedBox(height: 30),

                      // Save Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _handleSave,
                          icon: const Icon(Icons.save, color: Colors.black),
                          label: const Text(
                            "حفظ التغييرات",
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInput(
    String label,
    IconData icon,
    TextEditingController controller,
    ThemeData theme, {
    bool isPass = false,
    bool readOnly = false,
  }) {
    final subColor = theme.brightness == Brightness.dark
        ? Colors.grey[400]
        : Colors.grey[600];
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: subColor),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: subColor, fontSize: 12)),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            obscureText: isPass,
            readOnly: readOnly,
            style: TextStyle(
              color: theme.textTheme.bodyMedium!.color,
            ), // ✅ Dynamic Text
            decoration: InputDecoration(
              filled: true,
              fillColor: theme.cardColor, // ✅ Dynamic Input BG
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.primaryColor),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onTap,
    ThemeData theme, {
    String? subtitle,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(color: color, fontWeight: FontWeight.bold),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.grey, fontSize: 10),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    final theme = Theme.of(context);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: theme.cardColor,
        title: Text(
          "حذف البيانات؟",
          style: TextStyle(color: theme.textTheme.bodyMedium!.color),
        ),
        content: const Text(
          "هل أنت متأكد من حذف جميع سجلات الرحلات؟ لا يمكن التراجع عن هذا الإجراء.",
          style: TextStyle(color: Colors.grey),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("إلغاء", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteData();
            },
            child: const Text("حذف", style: TextStyle(color: ThemeService.red)),
          ),
        ],
      ),
    );
  }
}
