import 'dart:convert';
import 'package:currencyapp/login.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'help-feedback.dart';
import 'privacy_policy.dart';
import 'main.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool rateAlerts = true;
  bool offlineMode = false;
  bool isAlertOn = false;

  @override
  void initState() {
    super.initState();
    _loadOtherSettings();
  }
  

  Future<void> _loadOtherSettings() async {
    
    final prefs = await SharedPreferences.getInstance();
    int count = prefs.getInt('notificationCount') ?? 0;
    await prefs.setInt('notificationCount', count + 1);
    
    
    setState(() {
      rateAlerts = prefs.getBool('rate_alerts') ?? true;
      offlineMode = prefs.getBool('offline_mode') ?? false;
    });
  }
  

  Future<void> _toggleOtherSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
    _loadOtherSettings();
  }

  //  PHOTO UPLOAD LOGIC
  Future<void> _pickAndUploadImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
    );

    if (image == null) return;

    try {
     
      String cloudName = "dpsgzdaiq";
      String uploadPreset = "profile_pic";

      var uri = Uri.parse(
        "https://api.cloudinary.com/v1_1/$cloudName/image/upload",
      );
      var request = http.MultipartRequest("POST", uri);

      var bytes = await image.readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: image.name),
      );
      request.fields['upload_preset'] = uploadPreset;


      var response = await request.send();
      var responseData = await response.stream.toBytes();
      var jsonResponse = jsonDecode(utf8.decode(responseData));

      if (response.statusCode == 200) {
        String downloadUrl = jsonResponse['secure_url'];

       
        await user.updatePhotoURL(downloadUrl);

       
        await FirebaseFirestore.instance
            .collection('users_data')
            .doc(user.uid)
            .set({
              'profile_pic': downloadUrl,
              'updated_at': FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));

        await user.reload();
        setState(() {});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile picture updated!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Upload Error: $e")));
      }
    }
  }


  void _showEditDetailsDialog() {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) return;

    final nameController = TextEditingController(text: user.displayName ?? "");
    final emailController = TextEditingController(text: user.email ?? "");

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Edit Details"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
              readOnly: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                if (nameController.text.trim() != user.displayName) {
                  await user.updateDisplayName(nameController.text.trim());
                }

                await user.reload();

                if (!mounted) return;

                setState(() {});
                Navigator.pop(context);

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Profile updated!")),
                );
              } catch (e) {
                if (!mounted) return;

                ScaffoldMessenger.of(
                  context,
                ).showSnackBar(SnackBar(content: Text("Error: $e")));
              }
            },
            child: const Text("Update"),
          ),
        ],
      ),
    );
  }


  void _showPasswordDialog() {
    final User? user = FirebaseAuth.instance.currentUser;
    final oldPassController = TextEditingController();
    final newPassController = TextEditingController();
    bool obscureNewPass = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text("Change Password"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: oldPassController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Current Password",
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: newPassController,
                  obscureText: obscureNewPass,
                  decoration: InputDecoration(
                    labelText: "New Password",
                    suffixIcon: IconButton(
                      icon: Icon(
                        obscureNewPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                      ),
                      onPressed: () {
                        setDialogState(() {
                          obscureNewPass = !obscureNewPass;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Cancel"),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    AuthCredential credential = EmailAuthProvider.credential(
                      email: user!.email!,
                      password: oldPassController.text,
                    );
                    await user.reauthenticateWithCredential(credential);
                    await user.updatePassword(newPassController.text);
                    if (!mounted) return;
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Password updated successfully!"),
                      ),
                    );
                  } catch (e) {
                    if (mounted)
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text("Error: $e")));
                  }
                },
                child: const Text("Change"),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Center(
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 55,
                    backgroundColor: Colors.blue,
                    backgroundImage: (currentUser?.photoURL != null)
                        ? NetworkImage(currentUser!.photoURL!)
                        : null,
                    child: (currentUser?.photoURL == null)
                        ? const Icon(
                            Icons.person,
                            size: 55,
                            color: Colors.white,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: Colors.white,
                      radius: 18,
                      child: IconButton(
                        icon: const Icon(
                          Icons.camera_alt,
                          size: 16,
                          color: Colors.indigo,
                        ),
                        onPressed: _pickAndUploadImage,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Text(
              currentUser?.displayName ?? "User Name",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              currentUser?.email ?? "email@example.com",
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _showEditDetailsDialog,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigo,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              child: const Text("Edit Personal Details"),
            ),
            TextButton(
              onPressed: _showPasswordDialog,
              child: const Text(
                "Change Password",
                style: TextStyle(color: Colors.indigo),
              ),
            ),
            const SizedBox(height: 30),
            _buildSectionHeader("App Settings"),
            _buildSettingsContainer([
              _buildToggleTile(
                Icons.dark_mode,
                "Dark Mode",
                isDarkMode,
                (v) => MainApp.of(context).changeTheme(v),
              ),
              _buildToggleTile(
                Icons.wifi_off,
                "Offline Mode",
                offlineMode,
                (v) => _toggleOtherSetting('offline_mode', v),
              ),
              _buildToggleTile(
                Icons.notifications_active,
                "Rate Alerts",
                rateAlerts,
                (v) => _toggleOtherSetting('rate_alerts', v),
                
              ),
            ], isDarkMode),
            const SizedBox(height: 25),
            _buildSectionHeader("Support & Privacy"),
            _buildSettingsContainer([
              _buildActionTile(Icons.help_center, "Help & Feedback", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const HelpFeedbackPage(),
                  ),
                );
              }, isDarkMode),
              _buildActionTile(Icons.privacy_tip, "Privacy Policy", () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const PrivacyPolicyPage(),
                  ),
                );
              }, isDarkMode),
              _buildActionTile(
                Icons.logout,
                "Logout",
                () async {
                  await FirebaseAuth.instance.signOut();

                  if (!mounted) return;

                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => Login()),
                    (route) => false,
                  );
                },
                color: Colors.red,
                isDarkMode,
              ),
            ], isDarkMode),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 10, bottom: 8),
        child: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Colors.blueGrey,
          ),
        ),
      ),
    );
  }

  Widget _buildSettingsContainer(List<Widget> children, bool isDarkMode) {
    return Container(
      decoration: BoxDecoration(
        color: isDarkMode ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    bool value,
    Function(bool) onChanged,
  ) {
    return ListTile(
      leading: Icon(icon, color: Colors.blue),
      title: Text(
        title,
        style: TextStyle(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white
              : Colors.black,
        ),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: Colors.blue,
      ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    VoidCallback onTap,
    bool isDarkMode, {
    Color color = Colors.blue,
  }) {
    return ListTile(
      leading: Icon(icon, color: color),
      title: Text(
        title,
        style: TextStyle(
          color: color == Colors.red
              ? Colors.red
              : (isDarkMode ? Colors.white : Colors.black),
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }
}
