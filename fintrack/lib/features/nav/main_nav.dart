import 'package:flutter/material.dart';
import 'package:fintrack/features/category/screen/category_list_page.dart';
import 'package:fintrack/features/report/screens/report_page.dart';
import 'package:fintrack/features/transaction/screen/add_edit_transaction_page.dart';
import 'package:fintrack/features/transaction/screen/transaction_list_page.dart';
import 'package:fintrack/core/config/color.dart';
import 'package:fintrack/features/dashboard/screen/dashboard_page.dart';
import 'package:fintrack/features/wallet/screen/wallet_page.dart';

class MainNav extends StatefulWidget {
  const MainNav({super.key});

  @override
  State<MainNav> createState() => _MainNavState();
}

class _MainNavState extends State<MainNav> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const WalletPage(),
    const CategoryListPage(),
    const ReportPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    const double iconSize = 28.0;
    const Color selectedColor = ColorsApp.primary;
    final Color unselectedColor = Colors.grey.shade400;

    return Scaffold(
      body: _pages[_selectedIndex],

      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (context) {
              return Container(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).viewInsets.bottom,
                ),
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                  child: AddEditTransactionPage(
                    onTransactionChanged: () {
                      if (_selectedIndex == 1 &&
                          _pages[_selectedIndex] is WalletPage) {
                        print(
                          'DEBUG: Memanggil refresh di WalletPage setelah Add Transaction',
                        );
                      }
                      if (_selectedIndex == 2 &&
                          _pages[_selectedIndex] is TransactionListPage) {
                        print(
                          'DEBUG: Memanggil refresh di TransactionListPage setelah Add Transaction',
                        );
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
        backgroundColor: ColorsApp.primary,
        shape: const CircleBorder(),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8.0,
        color: Colors.white,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.home,
                  color: _selectedIndex == 0 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
                onPressed: () => _onItemTapped(0),
              ),
            ),

            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.account_balance_wallet,
                  color: _selectedIndex == 1 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
                onPressed: () => _onItemTapped(1),
              ),
            ),

            Expanded(child: SizedBox(width: iconSize)),
            //index2
            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.category,
                  color: _selectedIndex == 2 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
                onPressed: () => _onItemTapped(2),
              ),
            ),

            Expanded(
              child: IconButton(
                icon: Icon(
                  Icons.bar_chart,
                  color: _selectedIndex == 3 ? selectedColor : unselectedColor,
                  size: iconSize,
                ),
                onPressed: () => _onItemTapped(3),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
