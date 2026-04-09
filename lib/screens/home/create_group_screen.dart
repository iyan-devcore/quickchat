import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/user_model.dart';
import '../../providers/user_provider.dart';
import '../../providers/chat_provider.dart';
import '../../utils/app_colors.dart';
import '../../widgets/custom_text_field.dart';
import '../../widgets/primary_button.dart';

class CreateGroupScreen extends StatefulWidget {
  const CreateGroupScreen({super.key});

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<User> _selectedUsers = {};
  List<User> _allUsers = [];
  bool _isLoading = true;
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final data = await userProvider.apiService.getUsers();
      if (mounted) {
        setState(() {
          _allUsers = data.map((json) => User.fromJson(json)).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _toggleUserSelection(User user) {
    setState(() {
      if (_selectedUsers.contains(user)) {
        _selectedUsers.remove(user);
      } else {
        _selectedUsers.add(user);
      }
    });
  }

  Future<void> _handleCreateGroup() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a group name')),
      );
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one member')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      
      final List<User> members = [
        userProvider.currentUser!,
        ..._selectedUsers.toList(),
      ];

      await chatProvider.createGroup(
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        members: members,
      );

      if (mounted) {
        Navigator.of(context).pop(); // Back to NewChatScreen
        Navigator.of(context).pop(); // Back to HomeScreen
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create group: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Group'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isCreating ? null : _handleCreateGroup,
              child: Text(
                'CREATE',
                style: TextStyle(
                  color: _isCreating ? Colors.grey : Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary.withOpacity(0.1),
                            child: const Icon(Icons.camera_alt, color: AppColors.primary, size: 30),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: CustomTextField(
                              controller: _nameController,
                              hintText: 'Group name',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      CustomTextField(
                        controller: _descriptionController,
                        hintText: 'Group description (optional)',
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text(
                        'Select Members',
                        style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textGrey),
                      ),
                      const Spacer(),
                      Text(
                        '${_selectedUsers.length} selected',
                        style: const TextStyle(color: AppColors.primary),
                      ),
                    ],
                  ),
                ),
                if (_selectedUsers.isNotEmpty)
                  SizedBox(
                    height: 80,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: _selectedUsers.length,
                      itemBuilder: (context, index) {
                        final user = _selectedUsers.elementAt(index);
                        return Padding(
                          padding: const EdgeInsets.only(right: 12),
                          child: Stack(
                            children: [
                              Column(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: NetworkImage(user.avatarUrl),
                                    radius: 25,
                                  ),
                                  const SizedBox(height: 4),
                                  SizedBox(
                                    width: 50,
                                    child: Text(
                                      user.name,
                                      style: const TextStyle(fontSize: 10),
                                      overflow: TextOverflow.ellipsis,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: InkWell(
                                  onTap: () => _toggleUserSelection(user),
                                  child: Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.grey,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.close, size: 14, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _allUsers.length,
                    itemBuilder: (context, index) {
                      final user = _allUsers[index];
                      final isSelected = _selectedUsers.contains(user);

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundImage: NetworkImage(user.avatarUrl),
                        ),
                        title: Text(user.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(user.about),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle, color: AppColors.primary)
                            : const Icon(Icons.circle_outlined, color: Colors.grey),
                        onTap: () => _toggleUserSelection(user),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
