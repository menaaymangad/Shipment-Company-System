import 'dart:async';
import 'dart:collection';

import 'package:app/cubits/login_cubit/login_cubit_cubit.dart';
import 'package:app/cubits/login_cubit/login_cubit_state.dart';
import 'package:app/cubits/user_cubit/user_cubit.dart';
import 'package:app/cubits/user_cubit/user_state.dart';
import 'package:app/cubits/brach_cubit/branch_cubit.dart';
import 'package:app/cubits/brach_cubit/branch_states.dart';
import 'package:app/helper/shared_prefs_service.dart';
import 'package:app/models/branches_model.dart';
import 'package:app/pages/main_pages/main_page.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:window_manager/window_manager.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  static String id = 'loginPage';

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with WindowListener {
  final FocusNode _passwordFocusNode = FocusNode();
  String? selectedBranch;
  String? selectedUserName;
  bool isPasswordVisible = false;
  final _passwordController = TextEditingController();
  StreamSubscription<AuthState>? _authSubscription;
  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    context.read<BranchCubit>().fetchBranches();
    context.read<UserCubit>().fetchUsers();
    _loadLastUserData();
  }

  Future<void> _loadLastUserData() async {
    final lastLoginInfo = await SharedPrefsService.getLastLoginInfo();

    if (lastLoginInfo['branch'] != null && lastLoginInfo['username'] != null) {
      setState(() {
        selectedBranch = lastLoginInfo['branch'];
        selectedUserName = lastLoginInfo['username'];
      });
    }
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    // Cancel the stream subscription when the widget is disposed
    _authSubscription?.cancel();
    _passwordFocusNode.dispose();
    // Dispose the TextEditingController
    _passwordController.dispose();

    super.dispose();
  }

  @override
  void onWindowFocus() {
    // Make sure to call once.
    setState(() {});
    // do something
  }

  void _handleLogin() {
    if (selectedBranch == null || selectedUserName == null) {
      _showErrorSnackBar('Please select both branch and user');
      return;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorSnackBar('Please enter password');
      return;
    }
    SharedPrefsService.saveLastLoginInfo(selectedBranch!, selectedUserName!);

    bool isLoading = true;

    // Show loading dialog while authenticating
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        // Use dialogContext instead of context
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );

    // Listen for authentication state
    _authSubscription?.cancel(); // Cancel any existing subscription
    _authSubscription = context.read<AuthCubit>().stream.listen(
      (state) async {
        // Only proceed if we're still loading and the widget is mounted
        if (!isLoading || !mounted) return;

        try {
          // Safely dismiss the loading dialog if it exists
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          isLoading = false;

          if (state is AuthSuccess) {
            // Save the last logged-in user's data (except password)
            if (selectedUserName != 'admin') {
              final prefs = await SharedPreferences.getInstance();

              await prefs.setString('last_branch', selectedBranch!);
              await prefs.setString('last_username', selectedUserName!);
            }
            // Navigate on success
            Navigator.pushReplacementNamed(context, MainLayout.id);
          } else if (state is AuthFailure) {
            // Show error dialog and reset the page
            _showAuthErrorDialog(state.message);
            _resetPage();
          }
        } catch (e) {
          debugPrint('Error handling auth state: $e');
          // Ensure we still show the error even if dialog dismissal fails
          _showAuthErrorDialog('Authentication error occurred');
          _resetPage();
        }
      },
      onError: (error) {
        debugPrint('Auth stream error: $error');
        if (mounted && isLoading) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          isLoading = false;
          _showAuthErrorDialog('Authentication error occurred');
          _resetPage();
        }
      },
    );

    // Trigger the login
    context.read<AuthCubit>().login(
          selectedBranch!,
          selectedUserName!,
          _passwordController.text,
        );
  }

// Update error dialog to be more robust
  void _showAuthErrorDialog(String message) {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext dialogContext) {
        // Use dialogContext
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          title: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red[700]),
              const SizedBox(width: 10),
              const Text(
                'Authentication Error',
                style: TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Text(
            message,
            style: const TextStyle(fontSize: 16),
          ),
          actions: [
            TextButton(
              child: const Text(
                'OK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onPressed: () {
                if (Navigator.canPop(dialogContext)) {
                  Navigator.pop(dialogContext);
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _resetPage() async {
    try {
      // Clear the password field
      _passwordController.clear();

      // Reset selected branch and user
      setState(() {
        selectedBranch = null;
        selectedUserName = null;
        isPasswordVisible = false; // Reset password visibility
      });

      // Reset the AuthCubit state - await this operation
      await context.read<AuthCubit>().resetState();

      // Reset any error messages or UI states
      if (mounted) {
        // Check if widget is still mounted
        ScaffoldMessenger.of(context).clearSnackBars();
      }

      // Reset focus
      if (mounted) {
        // Check if widget is still mounted
        FocusScope.of(context).unfocus();
      }

      // Cancel any existing subscriptions
      await _authSubscription?.cancel();

      // Optionally refresh the UI state if needed
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      debugPrint('Error during page reset: $e');
      // Handle any errors during reset
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error resetting page: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade800,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: EdgeInsets.symmetric(horizontal: 40.w, vertical: 20.h),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Get the window size
    final Size windowSize = MediaQuery.of(context).size;

    // Determine if we should use compact layout
    final bool isCompact = windowSize.width < 1200;

    return Scaffold(
      body: Row(
        children: [
          // Left Panel - Collapsible based on window size
          if (!isCompact || windowSize.width > 800)
            SizedBox(
              width:
                  isCompact ? windowSize.width * 0.3 : windowSize.width * 0.35,
              child: _buildLeftPanel(),
            ),

          // Right Panel - Adaptive width
          Expanded(
            child: SingleChildScrollView(
              child: _buildRightPanel(isCompact),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLeftPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E88E5),
            Color(0xFF1565C0),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Logo with adaptive sizing
          SvgPicture.asset(
            'assets/icons/EUKnet-Logo.svg',
            width: MediaQuery.of(context).size.width * 0.2,
            colorFilter: const ColorFilter.mode(
              Colors.white,
              BlendMode.srcIn,
            ),
          ),
          const SizedBox(height: 40),
          // Welcome text container with glass effect
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(
              horizontal: 25,
              vertical: 15,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Colors.white.withAlpha(50),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(15),
                  blurRadius: 15,
                ),
              ],
            ),
            child: const Text(
              'Welcome To Our Wonderful World',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRightPanel(bool isCompact) {
    final screenWidth = MediaQuery.of(context).size.width;
    final formWidth = isCompact ? screenWidth * 0.6 : 450.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isCompact ? 20 : 40,
        vertical: 40,
      ),
      child: Center(
        child: Container(
          width: formWidth,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(10),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildFormHeader(),
              const SizedBox(height: 30),
              _buildFormFields(),
              const SizedBox(height: 30),
              _buildButtons(),
              _buildAdminLink(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormHeader() {
    return const Text(
      'Login',
      style: TextStyle(
        fontSize: 28,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1565C0),
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildFormFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildInputLabel('Branch'),
        const SizedBox(height: 8),
        _buildBranchDropdown(),
        const SizedBox(height: 20),
        _buildInputLabel('User'),
        const SizedBox(height: 8),
        _buildUserDropdown(),
        const SizedBox(height: 20),
        _buildInputLabel('Password'),
        const SizedBox(height: 8),
        _buildPasswordField(),
      ],
    );
  }

  Widget _buildInputLabel(String label) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.grey[700],
      ),
    );
  }

  Widget _buildBranchDropdown() {
    return BlocBuilder<BranchCubit, BranchState>(
      builder: (context, state) {
        if (state is BranchLoadedState) {
          // Check if selectedBranch exists in current branch list
          final isValidSelection =
              state.branches.any((b) => b.branchName == selectedBranch);
          if (!isValidSelection) {
            // Reset selection if invalid
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => selectedBranch = null);
              }
            });
          }

          return DropdownButtonFormField<String>(
            value: isValidSelection ? selectedBranch : null,
            items: _buildBranchItems(state.branches),
            onChanged: (value) {
              setState(() {
                selectedBranch = value;
                selectedUserName = null;
              });
            },
            decoration:
                _buildDropdownDecoration('Select Branch', Icons.location_city),
          );
        } else if (state is BranchErrorState) {
          return Text(state.errorMessage,
              style: const TextStyle(color: Colors.red));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  List<DropdownMenuItem<String>> _buildBranchItems(List<Branch> branches) {
    // Create a LinkedHashSet to ensure uniqueness
    final branchSet = LinkedHashSet<Branch>(
      equals: (a, b) => a.branchName == b.branchName,
      hashCode: (b) => b.branchName.hashCode,
    );

    // Add branches to the set (modifies the set in-place)
    branchSet.addAll(branches);

    // Convert the set back to a list of DropdownMenuItem
    return branchSet
        .map((branch) => DropdownMenuItem<String>(
              value: branch.branchName,
              child: Text(branch.branchName),
            ))
        .toList();
  }

  InputDecoration _buildDropdownDecoration(String label, IconData icon) {
    return InputDecoration(
      prefixIcon: Icon(icon, color: const Color(0xff236BC9)),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff236BC9)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xff236BC9)),
      ),
      labelText: label,
      labelStyle: TextStyle(color: Colors.grey.shade600),
      filled: true,
      fillColor: Colors.grey.shade50,
    );
  }

  Widget _buildUserDropdown() {
    return BlocBuilder<UserCubit, UserState>(
      builder: (context, state) {
        if (state is UserLoadedState) {
          final users = state.users
              .where((user) =>
                  user.branchName == selectedBranch && user.allowLogin)
              .toList();

          // Check if selected user exists in current user list
          final isValidSelection =
              users.any((u) => u.userName == selectedUserName);
          if (!isValidSelection) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => selectedUserName = null);
              }
            });
          }

          return DropdownButtonFormField<String>(
            value: isValidSelection ? selectedUserName : null,
            items: users
                .map((user) => DropdownMenuItem<String>(
                      value: user.userName,
                      child: Text('${user.userName} (${user.authorization})'),
                    ))
                .toList(),
            onChanged: (value) => setState(() => selectedUserName = value),
            decoration: _buildDropdownDecoration('Select User', Icons.person),
          );
        } else if (state is UserErrorState) {
          return Text(state.errorMessage,
              style: const TextStyle(color: Colors.red));
        }
        return const Center(child: CircularProgressIndicator());
      },
    );
  }

  Widget _buildPasswordField() {
    return TextFormField(
      controller: _passwordController,
      obscureText: !isPasswordVisible,
      focusNode: _passwordFocusNode,
      decoration: InputDecoration(
        prefixIcon: const Icon(Icons.lock, color: Color(0xff236BC9)),
        suffixIcon: IconButton(
          icon: Icon(
            isPasswordVisible ? Icons.visibility : Icons.visibility_off,
            color: const Color(0xff236BC9),
          ),
          onPressed: () {
            setState(() {
              isPasswordVisible = !isPasswordVisible;
            });
          },
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff236BC9)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xff236BC9)),
        ),
        labelText: 'Password',
        labelStyle: TextStyle(color: Colors.grey.shade600),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
      onFieldSubmitted: (value) {
        _handleLogin(); // Trigger login on Enter key press
      },
    );
  }

  Widget _buildButtons() {
    return KeyboardListener(
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event.logicalKey == LogicalKeyboardKey.enter) {
          _handleLogin();
        }
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Primary Login Button with hover effect
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: BlocListener<AuthCubit, AuthState>(
                listener: (context, state) {
                  if (state is AuthSuccess) {
                    Navigator.pushReplacementNamed(context, MainLayout.id);
                  } else if (state is AuthFailure) {
                    _showAuthErrorDialog(state.message);
                  }
                },
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1565C0),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ).copyWith(
                    overlayColor: WidgetStateProperty.resolveWith<Color?>(
                      (Set<WidgetState> states) {
                        if (states.contains(WidgetState.hovered)) {
                          return const Color(0xFF1976D2);
                        }
                        return null;
                      },
                    ),
                  ),
                  child: const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          // Secondary Cancel Button with hover effect
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              child: OutlinedButton(
                onPressed: () {
                  _passwordController.clear();
                  setState(() {
                    selectedBranch = null;
                    selectedUserName = null;
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.hovered)) {
                        return Colors.grey.shade100;
                      }
                      return null;
                    },
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdminLink() {
    return Padding(
      padding: const EdgeInsets.only(top: 20),
      child: Center(
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: TextButton(
            onPressed: () => _showAdminLoginDialog(context),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
            ).copyWith(
              overlayColor: WidgetStateProperty.resolveWith<Color?>(
                (Set<WidgetState> states) {
                  if (states.contains(WidgetState.hovered)) {
                    return Colors.blue.shade50;
                  }
                  return null;
                },
              ),
            ),
            child: const Text(
              'Admin Login',
              style: TextStyle(
                color: Color(0xFF1565C0),
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showAdminLoginDialog(BuildContext context) {
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isPasswordVisible = false;

    // FocusNode for the password field
    final FocusNode passwordFocusNode = FocusNode();

    // Form key for validation
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: const Text(
                "Admin Login",
                style: TextStyle(
                  color: Color(0xff236BC9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              content: Container(
                width: 400.w,
                padding: EdgeInsets.all(20.w),
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: usernameController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.person,
                              color: Color(0xff236BC9)),
                          labelText: "Username",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xff236BC9)),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Username is required';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          // Move focus to the password field when Enter is pressed
                          FocusScope.of(context)
                              .requestFocus(passwordFocusNode);
                        },
                      ),
                      SizedBox(height: 20.h),
                      TextFormField(
                        controller: passwordController,
                        obscureText: !isPasswordVisible,
                        focusNode: passwordFocusNode,
                        decoration: InputDecoration(
                          prefixIcon:
                              const Icon(Icons.lock, color: Color(0xff236BC9)),
                          labelText: "Password",
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide:
                                const BorderSide(color: Color(0xff236BC9)),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isPasswordVisible
                                  ? Icons.visibility
                                  : Icons.visibility_off,
                              color: const Color(0xff236BC9),
                            ),
                            onPressed: () {
                              setState(() {
                                isPasswordVisible = !isPasswordVisible;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Password is required';
                          }
                          return null;
                        },
                        onFieldSubmitted: (value) {
                          // Trigger login when Enter is pressed in the password field
                          if (formKey.currentState!.validate()) {
                            _handleAdminLogin(context, usernameController.text,
                                passwordController.text);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                // Cancel Button
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // Close the dialog
                  },
                  child: const Text(
                    "Cancel",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                // Login Button
                ElevatedButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      _handleAdminLogin(context, usernameController.text,
                          passwordController.text);
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff236BC9),
                  ),
                  child: const Text("Login"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleAdminLogin(
      BuildContext context, String username, String password) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return WillPopScope(
          onWillPop: () async => false, // Prevent back button dismissal
          child: const Center(
            child: CircularProgressIndicator(),
          ),
        );
      },
    );

    // Flag to track loading state
    bool isLoading = true;

    // Cancel any existing subscription
    _authSubscription?.cancel();

    // Listen for authentication state
    _authSubscription = context.read<AuthCubit>().stream.listen(
      (state) {
        // Only proceed if we're still loading and the widget is mounted
        if (!isLoading || !mounted) return;

        // Dismiss the loading dialog
        if (Navigator.canPop(context)) {
          Navigator.pop(context);
        }
        isLoading = false;

        if (state is AuthSuccess) {
          // Navigate to main page on success
          Navigator.pushReplacementNamed(context, MainLayout.id);
        } else if (state is AuthFailure) {
          // Show error dialog on failure
          _showAuthErrorDialog(state.message);
        }
      },
      onError: (error) {
        debugPrint('Auth stream error: $error');
        if (mounted && isLoading) {
          if (Navigator.canPop(context)) {
            Navigator.pop(context);
          }
          isLoading = false;
          _showAuthErrorDialog('Authentication error occurred');
        }
      },
    );

    // Trigger the admin login
    context.read<AuthCubit>().adminLogin(username, password);
  }
}
