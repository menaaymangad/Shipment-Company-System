import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:window_manager/window_manager.dart';

class CustomWindowAppBar extends StatefulWidget implements PreferredSizeWidget {
  final Widget? leading;
  final Widget? title;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final double height;
  final bool showWindowControls;

  const CustomWindowAppBar({
    super.key,
    this.leading,
    this.title,
    this.actions,
    this.backgroundColor,
    this.height = 120,
    this.showWindowControls = true,
  });

  @override
  State<CustomWindowAppBar> createState() => _CustomWindowAppBarState();

  @override
  Size get preferredSize => Size.fromHeight(height);
}

class _CustomWindowAppBarState extends State<CustomWindowAppBar>
    with WindowListener {
  Offset _offset = Offset.zero;
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    _init();
  }

  void _init() async {
    await windowManager.setPreventClose(true);
    // Get initial window state
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});

    // Add window move handler
    windowManager.addListener(this);
  }

  @override
  void onWindowResize() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void onWindowMove() async {
    _isMaximized = await windowManager.isMaximized();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  void onWindowClose() async {
    bool isPreventClose = await windowManager.isPreventClose();
    if (isPreventClose) {
      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) {
          return AlertDialog(
            title: const Text('Are you sure you want to close this window?'),
            actions: [
              TextButton(
                child: const Text('No'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              TextButton(
                child: const Text('Yes'),
                onPressed: () async {
                  Navigator.of(context).pop();
                  await windowManager.destroy();
                },
              ),
            ],
          );
        },
      );
    }
  }

  Widget _buildWindowControl({
    required IconData icon,
    required VoidCallback onPressed,
    required Color iconColor,
    Color? hoverColor,
    double size = 20,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        hoverColor: hoverColor,
        child: SizedBox(
          width: 46.w,
          height: double.infinity,
          child: Icon(
            icon,
            size: size,
            color: iconColor,
          ),
        ),
      ),
    );
  }

  Widget _buildWindowControls() {
    return SizedBox(
      height: 80.h,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _buildWindowControl(
            // Using a more appropriate minimize icon
            icon: Icons.remove,
            onPressed: () async {
              try {
                await windowManager.minimize();
              } catch (e) {
                debugPrint('Error minimizing window: $e');
              }
            },
            iconColor: Colors.black,
            hoverColor: Colors.grey.shade300,
          ),
          _buildWindowControl(
            // Using better maximize/restore icons
            icon: _isMaximized ? Icons.filter_none : Icons.crop_din,
            onPressed: () async {
              try {
                if (_isMaximized) {
                  await windowManager.unmaximize();
                } else {
                  await windowManager.maximize();
                }
              } catch (e) {
                debugPrint('Error toggling maximize: $e');
              }
            },
            iconColor: Colors.black,
            hoverColor: Colors.grey.shade300,
          ),
          _buildWindowControl(
            icon: Icons.close,
            size: 24,
            onPressed: () async {
              try {
                await windowManager.close();
              } catch (e) {
                debugPrint('Error closing window: $e');
              }
            },
            iconColor: Colors.black,
            hoverColor: Colors.red.shade300,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.translucent,
      onPanStart: (details) => _offset = details.globalPosition,
      onPanUpdate: (details) async {
        final newOffset = details.globalPosition;
        final delta = newOffset - _offset;
        _offset = newOffset;

        if (_isMaximized) {
          // When dragging a maximized window, first unmaximize
          await windowManager.unmaximize();
          final position = await windowManager.getPosition();
          await windowManager.setPosition(position + delta);
        } else {
          final position = await windowManager.getPosition();
          await windowManager.setPosition(position + delta);
        }
      },
      onDoubleTap: () async {
        try {
          if (_isMaximized) {
            await windowManager.unmaximize();
          } else {
            await windowManager.maximize();
          }
        } catch (e) {
          debugPrint('Error toggling maximize: $e');
        }
      },
      child: AppBar(
        toolbarHeight: 120.h,
        backgroundColor: Colors.white,
        elevation: 4,
        shadowColor: Colors.black.withAlpha(40),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        leading: widget.leading,
        title: widget.title,
        actions: [
          ...?widget.actions,
          if (widget.showWindowControls) _buildWindowControls(),
        ],
      ),
    );
  }
}
