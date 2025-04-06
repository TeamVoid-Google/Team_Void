import 'package:flutter/material.dart';
import '../components/profile_header.dart';
import '../components/profile_info_card.dart';
import '../components/profile_wallet_card.dart';
import '../components/profile_spending_card.dart';
import '../components/profile_activity_card.dart';
import '../components/profile_loans_card.dart';
import '../components/profile_goals_card.dart';
import '../components/profile_investments_card.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({Key? key}) : super(key: key);

  // Static route method to use with Navigator
  static Route route() {
    return MaterialPageRoute(
      builder: (_) => const ProfilePage(),
    );
  }

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              pinned: false,
              snap: false,
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () {
                  Navigator.of(context).pop();
                },
              ),
              title: const Text(
                'Profile',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
              centerTitle: false,
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings_outlined, color: Colors.black),
                  onPressed: () {
                    // Handle settings navigation
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined, color: Colors.black),
                  onPressed: () {
                    // Handle notifications
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: ProfileHeader(
                name: 'Ashwin Prajapati',
                occupation: 'Employed full time',
                location: 'Mumbai, Maharashtra',
                avatarUrl: 'https://i.pravatar.cc/150?img=12',
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Row(
                  children: [
                    Expanded(
                      child: ProfileInfoCard(
                        title: 'Date of Birth',
                        value: '19th April 2004',
                        icon: Icons.calendar_today,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProfileInfoCard(
                        title: 'Annual Income',
                        value: '₹10,00,000',
                        icon: Icons.wallet,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ProfileInfoCard(
                        title: 'Risk Tolerance',
                        value: 'Moderate',
                        icon: Icons.trending_up,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: _buildTabBar(),
              ),
            ),
            SliverFillRemaining(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildOverviewTab(),
                  _buildInvestmentsTab(),
                  _buildLoansTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      height: 45,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(25),
      ),
      padding: const EdgeInsets.all(4),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(25),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: Colors.black,
        dividerColor: Colors.transparent,
        indicatorSize: TabBarIndicatorSize.tab,
        labelStyle: const TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        unselectedLabelStyle: const TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
        tabs: const [
          Tab(text: 'Overview'),
          Tab(text: 'Investments'),
          Tab(text: 'Loans'),
        ],
      ),
    );
  }

  Widget _buildOverviewTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          ProfileWalletCard(
            formattedBalance: '₹17,29,892',
          ),
          SizedBox(height: 24),
          ProfileSpendingCard(
            spending: 208212,
            formattedSpending: '₹2,08,212',
          ),
          SizedBox(height: 24),
          ProfileActivityCard(),
          SizedBox(height: 24),
          ProfileGoalsCard(),
        ],
      ),
    );
  }

  Widget _buildInvestmentsTab() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileInvestmentsCard(),
        ],
      ),
    );
  }

  Widget _buildLoansTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ProfileLoansCard(
            carLoan: {
              'name': 'Car Loan',
              'duration': '5 years',
              'amount': '₹100,000/year',
              'progress': 2,
              'totalYears': 5,
            },
            homeLoan: {
              'name': 'Home Loan',
              'duration': '15 years',
              'amount': '₹700,000/year',
              'progress': 6,
              'totalYears': 15,
            },
          ),
        ],
      ),
    );
  }
}