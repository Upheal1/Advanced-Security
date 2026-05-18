import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PremiumSideMenu extends StatefulWidget {
  final bool isOpen;
  final VoidCallback onClose;
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userEmail;
  final String? avatarUrl;

  const PremiumSideMenu({
    super.key,
    required this.isOpen,
    required this.onClose,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userEmail,
    this.avatarUrl,
  });

  @override
  State<PremiumSideMenu> createState() => _PremiumSideMenuState();
}

class _PremiumSideMenuState extends State<PremiumSideMenu>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _slideAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<double>(begin: -1.0, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    if (widget.isOpen) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(PremiumSideMenu oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOpen && !oldWidget.isOpen) {
      _controller.forward();
    } else if (!widget.isOpen && oldWidget.isOpen) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isOpen && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Stack(
          children: [
            GestureDetector(
              onTap: widget.onClose,
              child: Container(
                color: Colors.black.withValues(alpha: _fadeAnimation.value * 0.5),
              ),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: MediaQuery.of(context).size.width * 0.75,
              child: Transform.translate(
                offset: Offset(
                  _slideAnimation.value * MediaQuery.of(context).size.width * 0.75,
                  0,
                ),
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: _buildMenuContent(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMenuContent() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topRight: Radius.circular(32),
        bottomRight: Radius.circular(32),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1A1A2E).withValues(alpha: 0.95),
                const Color(0xFF16213E).withValues(alpha: 0.9),
              ],
            ),
            border: Border(
              right: BorderSide(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1,
              ),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 24),
                Expanded(
                  child: _buildMenuItems(),
                ),
                _buildFooter(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
              ),
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 16,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: widget.avatarUrl != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.network(
                      widget.avatarUrl!,
                      fit: BoxFit.cover,
                    ),
                  )
                : const Icon(
                    LucideIcons.user,
                    color: Colors.white,
                    size: 28,
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  widget.userEmail,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideX(begin: -0.2);
  }

  Widget _buildMenuItems() {
    final menuItems = [
      _MenuItemData(
        icon: LucideIcons.home,
        label: 'Home',
        index: 0,
      ),
      _MenuItemData(
        icon: LucideIcons.bookOpen,
        label: 'Journal',
        index: 1,
      ),
      _MenuItemData(
        icon: LucideIcons.target,
        label: 'Focus',
        index: 2,
      ),
      _MenuItemData(
        icon: LucideIcons.barChart3,
        label: 'Progress',
        index: 3,
      ),
      _MenuItemData(
        icon: LucideIcons.user,
        label: 'Profile',
        index: 4,
      ),
      _MenuItemData(
        icon: LucideIcons.settings,
        label: 'Settings',
        index: 5,
      ),
      _MenuItemData(
        icon: LucideIcons.bell,
        label: 'Notifications',
        index: 6,
      ),
      _MenuItemData(
        icon: LucideIcons.helpCircle,
        label: 'Help & Support',
        index: 7,
      ),
    ];

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: menuItems.length,
      itemBuilder: (context, index) {
        final item = menuItems[index];
        final isSelected = widget.selectedIndex == item.index;

        return _MenuTile(
          icon: item.icon,
          label: item.label,
          isSelected: isSelected,
          onTap: () {
            HapticFeedback.selectionClick();
            widget.onItemSelected(item.index);
            widget.onClose();
          },
        ).animate().fadeIn(delay: (100 + index * 50).ms).slideX(begin: -0.2);
      },
    );
  }

  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF45D9A8).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                LucideIcons.sparkles,
                color: Color(0xFF45D9A8),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'UpHeal Premium',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Unlock all features',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              LucideIcons.chevronRight,
              color: Colors.white54,
              size: 20,
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2);
  }
}

class _MenuItemData {
  final IconData icon;
  final String label;
  final int index;

  const _MenuItemData({
    required this.icon,
    required this.label,
    required this.index,
  });
}

class _MenuTile extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<_MenuTile> createState() => _MenuTileState();
}

class _MenuTileState extends State<_MenuTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isHovered = true),
      onTapUp: (_) => setState(() => _isHovered = false),
      onTapCancel: () => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          gradient: widget.isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    const Color(0xFF6366F1).withValues(alpha: 0.15),
                  ],
                )
              : null,
          color: _isHovered ? Colors.white.withValues(alpha: 0.08) : null,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.isSelected
                ? const Color(0xFF8B5CF6).withValues(alpha: 0.5)
                : Colors.transparent,
            width: 1.5,
          ),
          boxShadow: widget.isSelected
              ? [
                  BoxShadow(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 0,
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                    : Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.icon,
                color: widget.isSelected
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.7),
                size: 20,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                widget.label,
                style: TextStyle(
                  color: widget.isSelected
                      ? Colors.white
                      : Colors.white.withValues(alpha: 0.8),
                  fontSize: 15,
                  fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (widget.isSelected)
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF8B5CF6),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.6),
                      blurRadius: 8,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PremiumMenuButton extends StatelessWidget {
  final VoidCallback onPressed;
  final double? marginLeft;
  final double? marginTop;

  const PremiumMenuButton({
    super.key,
    required this.onPressed,
    this.marginLeft,
    this.marginTop,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: marginLeft ?? 20,
      top: marginTop ?? MediaQuery.of(context).padding.top + 12,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.mediumImpact();
          onPressed();
        },
        child: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: const Icon(
            LucideIcons.menu,
            color: Colors.white,
            size: 22,
          ),
        ),
      ),
    );
  }
}