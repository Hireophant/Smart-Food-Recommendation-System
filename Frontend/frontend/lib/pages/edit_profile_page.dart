import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../core/supabase_handler.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  late TextEditingController _nameController;
  late TextEditingController _nicknameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;
  late TextEditingController _occupationController;

  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() {
    final user = SupabaseHandler().currentUser;
    final meta = user?.userMetadata ?? {};

    // Fallback to mock data if no user is logged in or data is missing
    final mockUser = UserProfileModel.getMockCurrentUser();

    _nameController = TextEditingController(
      text: meta['full_name'] ?? mockUser.name,
    );
    _nicknameController = TextEditingController(
      text: meta['nickname'] ?? 'Foodie',
    );
    _emailController = TextEditingController(
      text: user?.email ?? mockUser.email,
    );
    _phoneController = TextEditingController(
      text: meta['phone'] ?? '+84 901234567',
    );
    _addressController = TextEditingController(
      text: meta['address'] ?? 'TP. Hồ Chí Minh',
    );
    _occupationController = TextEditingController(
      text: meta['occupation'] ?? 'Sinh viên',
    );

    _avatarUrl = meta['avatar_url'] ?? mockUser.avatarUrl;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _occupationController.dispose();
    super.dispose();
  }

  void _onSave() {
    if (_formKey.currentState!.validate()) {
      // In a real app, update Supabase/Backend here
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Đã lưu thay đổi hồ sơ!'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDarkMode ? Colors.white : Colors.black87;
    final inputFillColor = isDarkMode
        ? const Color(0xFF2C2C2C)
        : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: Container(
          margin: const EdgeInsets.only(left: 16),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isDarkMode ? Colors.white10 : Colors.grey[100],
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: textColor),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        centerTitle: true,
        title: Text(
          'Chỉnh sửa hồ sơ',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    // --- Avatar Section ---
                    Center(
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 4),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 50,
                              backgroundImage: _avatarUrl != null
                                  ? NetworkImage(_avatarUrl!)
                                  : null,
                              child: _avatarUrl == null
                                  ? const Icon(Icons.person, size: 50)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF246BFD,
                                ), // Blue consistent with design
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                              ),
                              child: const Icon(
                                Icons.add,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // --- Fields ---
                    _buildTextField(
                      label: "Họ và tên",
                      controller: _nameController,
                      icon: Icons.edit,
                      isDarkMode: isDarkMode,
                      inputFillColor: inputFillColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Biệt danh",
                      controller: _nicknameController,
                      icon: Icons.edit,
                      isDarkMode: isDarkMode,
                      inputFillColor: inputFillColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Email",
                      controller: _emailController,
                      icon: Icons.email_outlined,
                      keyboardType: TextInputType.emailAddress,
                      isDarkMode: isDarkMode,
                      inputFillColor: inputFillColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Số điện thoại",
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      isDarkMode: isDarkMode,
                      inputFillColor: inputFillColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Địa chỉ",
                      controller: _addressController,
                      icon: Icons.location_on_outlined,
                      isDarkMode: isDarkMode,
                      inputFillColor: inputFillColor,
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      label: "Nghề nghiệp",
                      controller: _occupationController,
                      icon: Icons.work_outline,
                      isDarkMode: isDarkMode,
                      inputFillColor: inputFillColor,
                    ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),

          // --- Bottom Buttons ---
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isDarkMode
                          ? const Color(0xFF3C3C3C)
                          : const Color(0xFFF5F5F5),
                      foregroundColor: textColor,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Hủy',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _onSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(
                        0xFF34C759,
                      ), // Green consistent with design
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shadowColor: const Color(
                        0xFF34C759,
                      ).withValues(alpha: 0.4),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Lưu',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    required bool isDarkMode,
    required Color inputFillColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          style: TextStyle(
            color: isDarkMode ? Colors.grey[200] : Colors.black87,
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            hintText: label,
            filled: true,
            fillColor: inputFillColor,
            suffixIcon: Icon(icon, color: Colors.grey[400], size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(
                color: const Color(0xFF34C759),
                width: 1.5,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 16,
            ),
          ),
        ),
      ],
    );
  }
}
