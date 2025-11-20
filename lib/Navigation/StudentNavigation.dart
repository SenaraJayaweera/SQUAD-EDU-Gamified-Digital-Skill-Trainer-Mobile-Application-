import 'package:flutter/material.dart';
import '../Homepage/Student/StudentHomePage.dart';
import '../Userprofile/StudentUserProfile/StudentProfile.dart';
import '../Modules/StudentSideModules/StudentModuleList.dart';
import '../GameTemplates/Student/StudentTemplateList.dart';

class StudentNavigationBar extends StatefulWidget {
  const StudentNavigationBar({super.key});

  @override
  State<StudentNavigationBar> createState() => _StudentNavigationBarState();
}

class _StudentNavigationBarState extends State<StudentNavigationBar> {
  int _selectedIndex = 0;

  // Each tab gets its own navigator key (so you can push pages inside tabs)
  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    // GlobalKey<NavigatorState>(),
  ];

  void _onTap(int index) {
    if (_selectedIndex == index) {
      // If user taps the same tab → pop to first route of that tab
      _navigatorKeys[index].currentState!.popUntil((r) => r.isFirst);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

  // Builds a navigator for each tab
  Widget _buildNavigator(GlobalKey<NavigatorState> key, Widget page) {
    return Navigator(
      key: key,
      onGenerateRoute: (settings) {
        return MaterialPageRoute(builder: (_) => page);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: [
          _buildNavigator(_navigatorKeys[0], const Studenthomepage()), // Home

          _buildNavigator(
            _navigatorKeys[1],
            const StudentModuleList(),
          ), // Module
          /* _buildNavigator(
            _navigatorKeys[2],
            const StudentTemplatesOld(),
          ), // Template list
*/
          _buildNavigator(
            _navigatorKeys[2],
            const StudentUserProfilePage(),
          ), // Profile
        ],
      ),

      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Modules',
          ),
          /*  NavigationDestination(
            icon: Icon(Icons.sports_esports_outlined),
            label: 'Graphs',
          ),*/
          NavigationDestination(
            icon: Icon(Icons.person_outlined),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
