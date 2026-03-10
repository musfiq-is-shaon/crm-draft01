import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/theme_provider.dart';
import '../dashboard/dashboard_page.dart';
import '../sales/sales_list_page.dart';
import '../contacts/contacts_list_page.dart';
import '../tasks/tasks_list_page.dart';
import '../../../core/theme/app_theme_colors.dart';
import 'more_page.dart';

final selectedTabProvider = StateProvider<int>((ref) => 0);

class ShellPage extends ConsumerWidget {
  const ShellPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedTab = ref.watch(selectedTabProvider);
    final themeMode = ref.watch(themeProvider);
    final isDarkMode = themeMode == ThemeMode.dark;

    final pages = [
      const DashboardPage(),
      const SalesListPage(),
      const ContactsListPage(),
      const TasksListPage(),
      const MorePage(),
    ];

    final surfaceColor = AppThemeColors.surfaceColor(context);
    final textTertiary = AppThemeColors.textTertiaryColor(context);
    final primaryColor = const Color(0xFF2563EB);

    return Scaffold(
      body: IndexedStack(index: selectedTab, children: pages),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surfaceColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(
                  context,
                  ref,
                  index: 0,
                  icon: Icons.dashboard_outlined,
                  activeIcon: Icons.dashboard,
                  label: 'Dashboard',
                  selectedTab: selectedTab,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textTertiary: textTertiary,
                ),
                _buildNavItem(
                  context,
                  ref,
                  index: 1,
                  icon: Icons.trending_up_outlined,
                  activeIcon: Icons.trending_up,
                  label: 'Deals',
                  selectedTab: selectedTab,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textTertiary: textTertiary,
                ),
                _buildNavItem(
                  context,
                  ref,
                  index: 2,
                  icon: Icons.people_outline,
                  activeIcon: Icons.people,
                  label: 'Contacts',
                  selectedTab: selectedTab,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textTertiary: textTertiary,
                ),
                _buildNavItem(
                  context,
                  ref,
                  index: 3,
                  icon: Icons.checklist_outlined,
                  activeIcon: Icons.checklist,
                  label: 'Tasks',
                  selectedTab: selectedTab,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textTertiary: textTertiary,
                ),
                _buildNavItem(
                  context,
                  ref,
                  index: 4,
                  icon: Icons.menu_outlined,
                  activeIcon: Icons.menu,
                  label: 'More',
                  selectedTab: selectedTab,
                  isDarkMode: isDarkMode,
                  primaryColor: primaryColor,
                  textTertiary: textTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    WidgetRef ref, {
    required int index,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int selectedTab,
    required bool isDarkMode,
    required Color primaryColor,
    required Color textTertiary,
  }) {
    final isSelected = selectedTab == index;
    return InkWell(
      onTap: () => ref.read(selectedTabProvider.notifier).state = index,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? primaryColor : textTertiary,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? primaryColor : textTertiary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
