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
  const UsersPage({super.key});

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
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _restoreFormData();
    context.read<BranchCubit>().fetchBranches();
  }

  @override
  void deactivate() {
    _saveFormData();
    super.deactivate();
  }

  void _saveFormData() {
    final formData = {
      'userName': _userNameController.text,
      'branch': _selectedBranch,
      'authorization': _selectedAuthorization,
      'password': _passwordController.text,
      'allowLogin': _allowLogin,
    };
    context.read<UserFormCubit>().saveFormData(formData);
  }

  void _restoreFormData() {
    final formData = context.read<UserFormCubit>().state;
    if (formData.isNotEmpty) {
      _userNameController.text = formData['userName'] ?? '';
      _selectedBranch = formData['branch'] ?? '';
      _selectedAuthorization = formData['authorization'] ?? '';
      _passwordController.text = formData['password'] ?? '';
      _allowLogin = formData['allowLogin'] ?? false;
      setState(() {});
    }
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
    context.read<UserFormCubit>().clearFormData();
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
    final branches = context.read<BranchCubit>().state is BranchLoadedState
        ? (context.read<BranchCubit>().state as BranchLoadedState).branches
        : <Branch>[];

    setState(() {
      _selectedUser = user;
      _userIdController.text = user.id?.toString() ?? '';
      _userNameController.text = user.userName;
      _passwordController.text = user.password;
      _branchController.text = user.branchName;
      _authorizationController.text = user.authorization;
      _selectedBranch =
          branches.any((branch) => branch.branchName == user.branchName)
              ? user.branchName
              : '';
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
            _buildGridContent(),
            _buildFormFields(),
          ],
        ),
      ),
    );
  }

  Widget _buildGridContent() {
    return Flexible(
      flex: 3,
      child: Card(
        margin: EdgeInsets.all(16.0.r),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageUtils.buildSearchBar(
                onChanged: (value) => setState(() => _searchQuery = value)),
            Expanded(
              child: BlocBuilder<UserCubit, UserState>(
                // Rebuild on UserState changes
                builder: (context, state) {
                  if (state is UserLoadingState) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (state is UserLoadedState) {
                    return UsersList(
                      onUserSelected: _populateForm,
                      users: state.users,
                    );
                  } else if (state is UserErrorState) {
                    return Center(child: Text(state.errorMessage));
                  }
                  return const Center(child: Text('No data available'));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Flexible(
      flex: 2,
      child: Card(
        margin: const EdgeInsets.all(8.0),
        child: Padding(
          padding: EdgeInsets.all(16.r),
          child: Form(
            key: _formKey,
            child: Column(
              spacing: 16.h,
              children: [
                // User ID Field
                PageUtils.buildTextField(
                  controller: _userIdController,
                  labelText: 'User ID',
                  enabled: false,
                ),

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

                // Branch Dropdown
                _buildBranchDropdown(),

                // Authorization Dropdown
                _buildAuthorizationDropdown(),

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
                _buildAllowLoginCheckbox(),
                const Spacer(),
                PageUtils.buildActionButtons(
                  onAddPressed: _selectedUser == null ? _saveUser : null,
                  onUpdatePressed: _selectedUser != null ? _saveUser : null,
                  onDeletePressed: _selectedUser != null ? _deleteUser : null,
                  onCancelPressed: _resetForm,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return BlocConsumer<BranchCubit, BranchState>(
      listener: (context, state) {
        if (state is BranchLoadedState) {
          // Reset _selectedBranch if it no longer exists in the updated branches
          if (!state.branches
              .any((branch) => branch.branchName == _selectedBranch)) {
            setState(() {
              _selectedBranch = '';
            });
          }
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Branches loaded successfully!')),
          );
        } else if (state is BranchErrorState) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${state.errorMessage}')),
          );
        }
      },
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
class UserFormCubit extends Cubit<Map<String, dynamic>> {
  UserFormCubit() : super({});

  void saveFormData(Map<String, dynamic> formData) => emit(formData);
  void clearFormData() => emit({});
}
