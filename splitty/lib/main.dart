import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:splitty/models/friend.dart';
import 'package:splitty/models/transaction.dart';
import 'package:splitty/screens/transaction_history_screen.dart';
import 'package:splitty/screens/friends_management_screen.dart';
import 'package:splitty/screens/debt_relationship_screen.dart';
import 'screens/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  
  // Register Hive adapters
  Hive.registerAdapter(FriendAdapter());
  Hive.registerAdapter(TransactionAdapter());
  Hive.registerAdapter(TransactionTypeAdapter());
  
  // Open Hive boxes
  await Hive.openBox<Friend>('friends');
  await Hive.openBox<Transaction>('transactions');
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Splitty - Debt Tracker',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    const DashboardScreen(),
    const FriendsManagementScreen(),
    const TransactionHistoryScreen(),
    const DebtRelationshipScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: const Text('Splitty'),
      ),
      drawer: Drawer(
        child: ValueListenableBuilder(
          valueListenable: Hive.box<Friend>('friends').listenable(),
          builder: (context, friendsBox, _) {
            final friends = friendsBox.values.toList();
            double totalOwedToYou = 0;
            double totalYouOwe = 0;
            int settledDebts = 0;
            
            for (final friend in friends) {
              if (friend.totalDebt > 0) {
                totalOwedToYou += friend.totalDebt;
              } else if (friend.totalDebt < 0) {
                totalYouOwe += friend.totalDebt.abs();
              } else {
                settledDebts++;
              }
            }

            return ListView(
              padding: EdgeInsets.zero,
              children: [
                DrawerHeader(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Splitty',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                        ),
                      ),
                      Text(
                        'Debt Tracker',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                ListTile(
                  selected: _selectedIndex == 0,
                  leading: const Icon(Icons.dashboard),
                  title: const Text('Dashboard'),
                  onTap: () {
                    setState(() => _selectedIndex = 0);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                if (totalOwedToYou > 0)
                  ListTile(
                    leading: const Icon(Icons.arrow_upward, color: Colors.green),
                    title: const Text('They Owe You'),
                    subtitle: Text('₱${totalOwedToYou.toStringAsFixed(2)}'),
                    textColor: Colors.green,
                  ),
                if (totalYouOwe > 0)
                  ListTile(
                    leading: const Icon(Icons.arrow_downward, color: Colors.red),
                    title: const Text('You Owe Them'),
                    subtitle: Text('₱${totalYouOwe.toStringAsFixed(2)}'),
                    textColor: Colors.red,
                  ),
                if (settledDebts > 0)
                  ListTile(
                    leading: const Icon(Icons.check_circle, color: Colors.grey),
                    title: const Text('Settled Debts'),
                    subtitle: Text('$settledDebts ${settledDebts == 1 ? 'friend' : 'friends'}'),
                  ),
                const Divider(),
                ListTile(
                  selected: _selectedIndex == 3,
                  leading: const Icon(Icons.account_balance),
                  title: const Text('Debt Relationships'),
                  onTap: () {
                    setState(() => _selectedIndex = 3);
                    Navigator.pop(context);
                  },
                ),
                const Divider(),
                ListTile(
                  selected: _selectedIndex == 1,
                  leading: const Icon(Icons.people),
                  title: const Text('Friends'),
                  onTap: () {
                    setState(() => _selectedIndex = 1);
                    Navigator.pop(context);
                  },
                ),
                ListTile(
                  selected: _selectedIndex == 2,
                  leading: const Icon(Icons.history),
                  title: const Text('History'),
                  onTap: () {
                    setState(() => _selectedIndex = 2);
                    Navigator.pop(context);
                  },
                ),
              ],
            );
          },
        ),
      ),
      body: _screens[_selectedIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex < 3 ? _selectedIndex : 0,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Friends',
          ),
          NavigationDestination(
            icon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
    );
  }
}
