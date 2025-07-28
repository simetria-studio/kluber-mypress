import 'package:flutter/material.dart';
import 'package:mypress/views/home_screen.dart';
import '../views/perfil_screen.dart';
import '../views/cadastro_visita_screen.dart';
import '../views/configuracoes_screen.dart';
import '../views/visitas_pendentes_screen.dart';

class CustomBottomNav extends StatefulWidget {
  final int currentIndex;
  final Function(int) onTap;
  final VoidCallback onAddVisitPressed;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.onAddVisitPressed,
  });

  @override
  State<CustomBottomNav> createState() => _CustomBottomNavState();
}

class _CustomBottomNavState extends State<CustomBottomNav>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildNavItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          splashColor: const Color(0xFFFABA00).withOpacity(0.2),
          highlightColor: const Color(0xFFFABA00).withOpacity(0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOutCubic,
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: isActive 
                        ? const Color(0xFFFABA00) 
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: const Color(0xFFFABA00).withOpacity(0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    isActive ? activeIcon : icon,
                    color: isActive ? Colors.black : Colors.grey[400],
                    size: 20,
                  ),
                ),
                const SizedBox(height: 3),
                Flexible(
                  child: AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      color: isActive 
                          ? const Color(0xFFFABA00) 
                          : Colors.grey[500],
                      fontSize: 9,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    child: Text(
                      label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border(
          top: BorderSide(
            color: const Color(0xFFFABA00).withOpacity(0.15),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 15,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Menu items
          Positioned.fill(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    _buildNavItem(
                      icon: Icons.home_outlined,
                      activeIcon: Icons.home,
                      label: 'Home',
                      isActive: widget.currentIndex == 0,
                      onTap: () {
                        widget.onTap(0);
                        Navigator.pushReplacement(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, _) => const HomeScreen(),
                            transitionDuration: const Duration(milliseconds: 300),
                            transitionsBuilder: (context, animation, _, child) => 
                                FadeTransition(opacity: animation, child: child),
                          ),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.schedule_outlined,
                      activeIcon: Icons.schedule,
                      label: 'Pendentes',
                      isActive: widget.currentIndex == 1,
                      onTap: () {
                        widget.onTap(1);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, _) => const VisitasPendentesScreen(),
                            transitionDuration: const Duration(milliseconds: 300),
                            transitionsBuilder: (context, animation, _, child) => 
                                FadeTransition(opacity: animation, child: child),
                          ),
                        );
                      },
                    ),
                    // Espaço para o FAB
                    const Expanded(child: SizedBox()),
                    _buildNavItem(
                      icon: Icons.settings_outlined,
                      activeIcon: Icons.settings,
                      label: 'Versão',
                      isActive: widget.currentIndex == 2,
                      onTap: () {
                        widget.onTap(2);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, _) => const ConfiguracoesScreen(),
                            transitionDuration: const Duration(milliseconds: 300),
                            transitionsBuilder: (context, animation, _, child) => 
                                FadeTransition(opacity: animation, child: child),
                          ),
                        );
                      },
                    ),
                    _buildNavItem(
                      icon: Icons.person_outline,
                      activeIcon: Icons.person,
                      label: 'Perfil',
                      isActive: widget.currentIndex == 3,
                      onTap: () {
                        widget.onTap(3);
                        Navigator.push(
                          context,
                          PageRouteBuilder(
                            pageBuilder: (context, animation, _) => const PerfilScreen(),
                            transitionDuration: const Duration(milliseconds: 300),
                            transitionsBuilder: (context, animation, _, child) => 
                                FadeTransition(opacity: animation, child: child),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // FAB Central
          Positioned(
            top: -25,
            left: 0,
            right: 0,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) => _animationController.forward(),
                onTapUp: (_) => _animationController.reverse(),
                onTapCancel: () => _animationController.reverse(),
                onTap: widget.onAddVisitPressed,
                child: AnimatedBuilder(
                  animation: _scaleAnimation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFFFFCD3C),
                              Color(0xFFFABA00),
                              Color(0xFFE6A200),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(32),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFFABA00).withOpacity(0.4),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.add_rounded,
                          color: Colors.black,
                          size: 32,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
