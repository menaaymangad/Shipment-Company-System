import 'package:app/cubits/brach_cubit/branch_cubit.dart';
import 'package:app/cubits/brach_cubit/branch_states.dart';
import 'package:app/cubits/user_cubit/user_cubit.dart';
import 'package:app/cubits/user_cubit/user_state.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/models/user_model.dart';
import 'package:app/pages/admin_pages/users/users_list.dart';
import 'package:app/widgets/page_utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class UsersPage extends StatefulWidget {
  const UsersPage({super.key,});

  @override
  State<UsersPage> createState() => _UsersPageState();
}

class _UsersPageState extends State<UsersPage> {
  // Constants
  static const List<String> _authorizations = ['Admin', 'User', 'Manager'];

  // Form Controllers
  final _formKey = GlobalKey<FormState>();
  final _userIdController = TextEditingController();
  final _userNameController = TextEditingController();
  final _passwordController = TextEditingController();

  // Dropdown Controllers
  final _branchController = TextEditingController();
  final _authorizationController = TextEditingController();

  // State Variables
  String _selectedBranch = '';
  String _selectedAuthorization = '';
  bool _allowLogin = false;
  User? _selectedUser;

  @override
  void initState() {
    super.initState();
    context.read<BranchCubit>().fetchBranches();
  }

  @override
  void dispose() {
    // Dispose controllers
    _userIdController.dispose();
    _userNameController.dispose();
    _passwordController.dispose();
    _branchController.dispose();
    _authorizationController.dispose();
    super.dispose();
  }

  void _resetForm() {
    setState(() {
      _userIdController.clear();
      _userNameController.clear();
      _passwordController.clear();
      _branchController.clear();
      _authorizationController.clear();
      _selectedUser = null;
      _selectedBranch = '';
      _selectedAuthorization = '';
      _allowLogin = true;
    });
  }

  void _populateForm(User user) {
    setState(() {
      _selectedUser = user;
      _userIdController.text = user.id?.toString() ?? '';
      _userNameController.text = user.userName;
      _passwordController.text = user.password;
      _branchController.text = user.branchName;
      _authorizationController.text = user.authorization;
      _selectedBranch = user.branchName;
      _selectedAuthorization = user.authorization;
      _allowLogin = user.allowLogin;
    });
  }

  void _saveUser() {
    if (!_formKey.currentState!.validate()) return;

    final user = User(
      id: _selectedUser?.id,
      userName: _userNameController.text.trim(),
      branchName: _selectedBranch,
      authorization: _selectedAuthorization,
      allowLogin: _allowLogin,
      password: _passwordController.text,
    );

    if (_selectedUser == null) {
      context.read<UserCubit>().addUser(user);
    } else {
      context.read<UserCubit>().updateUser(user);
    }

    _resetForm();
  }

  void _deleteUser() {
    if (_selectedUser != null) {
      context.read<UserCubit>().deleteUser(_selectedUser!.id!);
      _resetForm();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(16.0.r),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: PageUtils.buildCard(
                child: _buildGridContent(),
              ),
            ),
            SizedBox(width: 16.w),
            Expanded(
              flex: 2,
              child: PageUtils.buildCard(
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildFormFields(),
                        _buildAllowLoginCheckbox(),
                        SizedBox(height: 16.h),
                        PageUtils.buildActionButtons(
                          onAddPressed:
                              _selectedUser == null ? _saveUser : null,
                          onUpdatePressed:
                              _selectedUser != null ? _saveUser : null,
                          onDeletePressed:
                              _selectedUser != null ? _deleteUser : null,
                          onCancelPressed: _resetForm,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoadingState) {
          return const Center(child: CircularProgressIndicator());
        } else if (state is UserLoadedState) {
          return UsersList(
            onUserSelected: _populateForm,
            // users: state.users,
          );
        } else if (state is UserErrorState) {
          return Center(child: Text(state.errorMessage));
        }
        return const Center(child: Text('No data available'));
      },
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        // User ID Field
        PageUtils.buildTextField(
          controller: _userIdController,
          labelText: 'User ID',
          enabled: false,
        ),
        SizedBox(height: 16.h),

        // User Name Field
        PageUtils.buildTextField(
          controller: _userNameController,
          labelText: 'User Name *',
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'User Name is required';
            }
            return null;
          },
        ),
        SizedBox(height: 16.h),

        // Branch Dropdown
        _buildBranchDropdown(),
        SizedBox(height: 16.h),

        // Authorization Dropdown
        _buildAuthorizationDropdown(),
        SizedBox(height: 16.h),

        // Password Field
        PageUtils.buildTextField(
          controller: _passwordController,
          labelText: 'Password *',
          obscureText: true,
          maxLines: 1, // Ensure maxLines is 1 for obscured fields
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Password is required';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildBranchDropdown() {
    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, state) {
        final branches =
            state is BranchLoadedState ? state.branches : <Branch>[];
        return PageUtils.buildDropdownFormField(
          labelText: 'Branch *',
          items: branches.map((branch) => branch.branchName).toList(),
          value: _selectedBranch.isEmpty ? null : _selectedBranch,
          onChanged: (value) => setState(() => _selectedBranch = value ?? ''),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Branch is required';
            }
            return null;
          },
        );
      },
    );
  }

  Widget _buildAuthorizationDropdown() {
    return PageUtils.buildDropdownFormField(
      labelText: 'Authorization *',
      items: _authorizations,
      value: _selectedAuthorization.isEmpty ? null : _selectedAuthorization,
      onChanged: (value) =>
          setState(() => _selectedAuthorization = value ?? ''),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Authorization is required';
        }
        return null;
      },
    );
  }

  Widget _buildAllowLoginCheckbox() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Checkbox(
          value: _allowLogin,
          onChanged: (value) => setState(() => _allowLogin = value ?? false),
          shape: const CircleBorder(),
        ),
        const Text('Allow Login'),
      ],
    );
  }
}
