import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../constants/app_colors.dart';
import 'games/xoxo_game.dart';
import 'games/sudoku_game.dart';
import '../main.dart';
import '../widgets/common/empty_state_widget.dart';
import '../widgets/drawer_menu_button.dart';

class MiniGamesScreen extends StatefulWidget {
  const MiniGamesScreen({super.key});

  @override
  State<MiniGamesScreen> createState() => _MiniGamesScreenState();
}

class _MiniGamesScreenState extends State<MiniGamesScreen> {
  @override
  Widget build(BuildContext context) {
    final games = [
      GameCard(
        title: 'Tic Tac Toe',
        icon: LucideIcons.grid,
        gradient: const [Color(0xFF667eea), Color(0xFF764ba2)],
        onTap: () => _navigateToGame(context, const XoxoGame()),
      ),
      GameCard(
        title: 'Sudoku',
        icon: LucideIcons.squareDot,
        gradient: const [Color(0xFFf093fb), Color(0xFFf5576c)],
        onTap: () => _navigateToGame(context, const SudokuGame()),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
          leading: DrawerMenuButton(
            iconColor: Theme.of(context).brightness == Brightness.dark
                ? Colors.white
                : AppColors.textPrimary,
          ),
        title: Text(
          'Mini Games',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: AppColors.purple,
              ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: games.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: EmptyStateWidget(
                    iconData: LucideIcons.gamepad2,
                    title: 'Games coming soon',
                    subtitle: 'Check back later for new games and challenges!',
                  ),
                ),
              )
            : Column(
                children: [
                  Expanded(
                    child: GridView.count(
                      crossAxisCount: 2,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      children: games,
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  void _navigateToGame(BuildContext context, Widget game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => game),
    );
  }
}

class GameCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Color> gradient;
  final VoidCallback onTap;

  const GameCard({
    required this.title,
    required this.icon,
    required this.gradient,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: gradient,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: gradient.first.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
