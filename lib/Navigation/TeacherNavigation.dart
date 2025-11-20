import 'package:flutter/material.dart';
import '../Homepage/Teacher/TeacherHomepage.dart';
import '../Userprofile/TeacherUserProfile/TeacherProfile.dart';
import '../GameTemplates/Teacher/TeacherTemplateList.dart';
import '../Modules/TeacherSideModules/TeacherModuleList.dart';

class TeacherNavigationBar extends StatefulWidget {
  const TeacherNavigationBar({super.key});

  @override
  State<TeacherNavigationBar> createState() => _TeacherNavigationBarState();
}

class _TeacherNavigationBarState extends State<TeacherNavigationBar> {
  int _selectedIndex = 0;

  // Each tab gets its own navigator
  final _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTap(int index) {
    if (_selectedIndex == index) {
      // If same tab tapped again, pop back to first page
      _navigatorKeys[index].currentState!.popUntil((route) => route.isFirst);
    } else {
      setState(() => _selectedIndex = index);
    }
  }

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
          //   _buildNavigator(_navigatorKeys[0], const TeacherHomePage()), // Home
          _buildNavigator(
            _navigatorKeys[0],
            const TeacherModulesPage(),
          ), // Journal
          /*    _buildNavigator(
            _navigatorKeys[2],
            const TeacherTemplates(),
          ), // Graphs*/
          _buildNavigator(
            _navigatorKeys[1],
            const TeacherUserProfilePage(),
          ), // Profile
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          //  NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
          NavigationDestination(
            icon: Icon(Icons.school_outlined),
            label: 'Modules',
          ),
          /* NavigationDestination(
            icon: Icon(Icons.games_outlined),
            label: 'Games',
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
