import 'package:flutter/material.dart';
import 'package:image_separator/services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;
  
  Future<void> _signOut() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      await _authService.signOut();
      await _authService.setLoggedIn(false);
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error signing out: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final MockUser? user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.blue.shade100,
                    child: user?.photoURL != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: Image.network(
                              user!.photoURL!,
                              width: 100,
                              height: 100,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Icon(
                            Icons.person,
                            size: 60,
                            color: Colors.blue.shade700,
                          ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    user?.displayName ?? 'User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    user?.email ?? 'No email',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),
                  const SizedBox(height: 40),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.image),
                    title: const Text('My Images'),
                    subtitle: const Text('View all your processed images'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to user's images
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This feature is coming soon')),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    subtitle: const Text('App preferences and configurations'),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () {
                      // Navigate to settings
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('This feature is coming soon')),
                      );
                    },
                  ),
                  const Divider(),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.logout),
                      label: const Text('Sign Out'),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: Colors.white,
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: _isLoading ? null : _signOut,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
    );
  }
} 