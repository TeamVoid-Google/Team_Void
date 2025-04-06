import 'package:flutter/material.dart';

// Model classes for profile data
class ProfileData {
  String name;
  String occupation;
  String location;
  String avatarUrl;
  String dateOfBirth;
  String annualIncome;
  String riskTolerance;
  String walletBalance;
  List<SpendingCategory> spendingCategories;
  List<FinancialGoal> financialGoals;
  List<RecentActivity> recentActivities;
  Map<String, dynamic> carLoan;
  Map<String, dynamic> homeLoan;
  Map<String, dynamic> investmentPortfolio;
  List<Investment> investments;

  ProfileData({
    required this.name,
    required this.occupation,
    required this.location,
    required this.avatarUrl,
    required this.dateOfBirth,
    required this.annualIncome,
    required this.riskTolerance,
    required this.walletBalance,
    required this.spendingCategories,
    required this.financialGoals,
    required this.recentActivities,
    required this.carLoan,
    required this.homeLoan,
    required this.investmentPortfolio,
    required this.investments,
  });

  // Create a copy with updated fields
  ProfileData copyWith({
    String? name,
    String? occupation,
    String? location,
    String? avatarUrl,
    String? dateOfBirth,
    String? annualIncome,
    String? riskTolerance,
    String? walletBalance,
    List<SpendingCategory>? spendingCategories,
    List<FinancialGoal>? financialGoals,
    List<RecentActivity>? recentActivities,
    Map<String, dynamic>? carLoan,
    Map<String, dynamic>? homeLoan,
    Map<String, dynamic>? investmentPortfolio,
    List<Investment>? investments,
  }) {
    return ProfileData(
      name: name ?? this.name,
      occupation: occupation ?? this.occupation,
      location: location ?? this.location,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      annualIncome: annualIncome ?? this.annualIncome,
      riskTolerance: riskTolerance ?? this.riskTolerance,
      walletBalance: walletBalance ?? this.walletBalance,
      spendingCategories: spendingCategories ?? this.spendingCategories,
      financialGoals: financialGoals ?? this.financialGoals,
      recentActivities: recentActivities ?? this.recentActivities,
      carLoan: carLoan ?? this.carLoan,
      homeLoan: homeLoan ?? this.homeLoan,
      investmentPortfolio: investmentPortfolio ?? this.investmentPortfolio,
      investments: investments ?? this.investments,
    );
  }

  // Initial mock data
  factory ProfileData.initial() {
    return ProfileData(
      name: 'Ashwin Prajapati',
      occupation: 'Employed full time',
      location: 'Mumbai, Maharashtra',
      avatarUrl: 'https://i.pravatar.cc/150?img=12',
      dateOfBirth: '19th April 2004',
      annualIncome: '₹10,00,000',
      riskTolerance: 'Moderate',
      walletBalance: '₹17,29,892',
      spendingCategories: [
        SpendingCategory(name: 'Healthcare', amount: '₹84,000', color: Colors.blue),
        SpendingCategory(name: 'Food', amount: '₹52,700', color: Colors.orange),
        SpendingCategory(name: 'Utilities', amount: '₹37,000', color: Colors.purple),
        SpendingCategory(name: 'Supplies', amount: '₹17,100', color: Colors.teal),
      ],
      financialGoals: [
        FinancialGoal(name: 'Emergency Fund', target: 500000.0, current: 350000.0, color: Colors.blue),
        FinancialGoal(name: 'Vacation', target: 200000.0, current: 120000.0, color: Colors.orange),
        FinancialGoal(name: 'New Laptop', target: 100000.0, current: 75000.0, color: Colors.purple),
      ],
      recentActivities: [
        RecentActivity(
          title: 'Dribbble',
          amount: '-₹9,100',
          subtitle: 'Design Tools, 10:45 AM',
          iconColor: Colors.pink,
          icon: Icons.design_services,
        ),
        RecentActivity(
          title: 'Wilson Mango',
          amount: '-₹2,400',
          subtitle: 'Money Transfer, Yesterday',
          iconColor: Colors.purple,
          icon: Icons.person,
        ),
        RecentActivity(
          title: 'Abram Botosh',
          amount: '+₹4,500',
          subtitle: 'Payment Received, 07/24',
          iconColor: Colors.green,
          icon: Icons.account_circle,
        ),
      ],
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
      investmentPortfolio: {
        'total': '₹5,72,211',
        'growth': '+12.4% this month',
        'allocation': [
          {'name': 'Stocks', 'percentage': '45%', 'color': Colors.blue},
          {'name': 'Mutual Funds', 'percentage': '30%', 'color': Colors.green},
          {'name': 'Gold', 'percentage': '15%', 'color': Colors.amber},
          {'name': 'Crypto', 'percentage': '10%', 'color': Colors.red},
        ],
      },
      investments: [
        Investment(
          name: 'HDFC Bank',
          ticker: 'HDFCBANK',
          price: '₹1,682.50',
          change: '+3.45%',
          isPositive: true,
        ),
        Investment(
          name: 'Reliance Industries',
          ticker: 'RELIANCE',
          price: '₹2,750.75',
          change: '-1.24%',
          isPositive: false,
        ),
        Investment(
          name: 'Tata Consultancy',
          ticker: 'TCS',
          price: '₹3,550.20',
          change: '+2.15%',
          isPositive: true,
        ),
        Investment(
          name: 'SBI Bluechip Fund',
          ticker: 'Mutual Fund',
          price: '₹45.85',
          change: '+0.75%',
          isPositive: true,
        ),
      ],
    );
  }
}

// Model for spending categories
class SpendingCategory {
  final String name;
  final String amount;
  final Color color;

  SpendingCategory({
    required this.name,
    required this.amount,
    required this.color,
  });

  SpendingCategory copyWith({
    String? name,
    String? amount,
    Color? color,
  }) {
    return SpendingCategory(
      name: name ?? this.name,
      amount: amount ?? this.amount,
      color: color ?? this.color,
    );
  }
}

// Model for financial goals
class FinancialGoal {
  final String name;
  final double target;
  final double current;
  final Color color;

  FinancialGoal({
    required this.name,
    required this.target,
    required this.current,
    required this.color,
  });

  FinancialGoal copyWith({
    String? name,
    double? target,
    double? current,
    Color? color,
  }) {
    return FinancialGoal(
      name: name ?? this.name,
      target: target ?? this.target,
      current: current ?? this.current,
      color: color ?? this.color,
    );
  }
}

// Model for recent activities
class RecentActivity {
  final String title;
  final String amount;
  final String subtitle;
  final Color iconColor;
  final IconData icon;

  RecentActivity({
    required this.title,
    required this.amount,
    required this.subtitle,
    required this.iconColor,
    required this.icon,
  });

  RecentActivity copyWith({
    String? title,
    String? amount,
    String? subtitle,
    Color? iconColor,
    IconData? icon,
  }) {
    return RecentActivity(
      title: title ?? this.title,
      amount: amount ?? this.amount,
      subtitle: subtitle ?? this.subtitle,
      iconColor: iconColor ?? this.iconColor,
      icon: icon ?? this.icon,
    );
  }
}

// Model for investments
class Investment {
  final String name;
  final String ticker;
  final String price;
  final String change;
  final bool isPositive;

  Investment({
    required this.name,
    required this.ticker,
    required this.price,
    required this.change,
    required this.isPositive,
  });

  Investment copyWith({
    String? name,
    String? ticker,
    String? price,
    String? change,
    bool? isPositive,
  }) {
    return Investment(
      name: name ?? this.name,
      ticker: ticker ?? this.ticker,
      price: price ?? this.price,
      change: change ?? this.change,
      isPositive: isPositive ?? this.isPositive,
    );
  }
}

// Provider to manage profile data
class ProfileProvider extends ChangeNotifier {
  ProfileData _profileData = ProfileData.initial();

  // Getter for profile data
  ProfileData get profileData => _profileData;

  // Update basic profile info
  void updateBasicInfo({
    String? name,
    String? occupation,
    String? location,
    String? avatarUrl,
  }) {
    _profileData = _profileData.copyWith(
      name: name,
      occupation: occupation,
      location: location,
      avatarUrl: avatarUrl,
    );
    notifyListeners();
  }

  // Update financial details
  void updateFinancialInfo({
    String? dateOfBirth,
    String? annualIncome,
    String? riskTolerance,
  }) {
    _profileData = _profileData.copyWith(
      dateOfBirth: dateOfBirth,
      annualIncome: annualIncome,
      riskTolerance: riskTolerance,
    );
    notifyListeners();
  }

  // Update wallet balance
  void updateWalletBalance(String balance) {
    _profileData = _profileData.copyWith(walletBalance: balance);
    notifyListeners();
  }

  // Add spending category
  void addSpendingCategory(SpendingCategory category) {
    final updatedCategories = List<SpendingCategory>.from(_profileData.spendingCategories)
      ..add(category);
    _profileData = _profileData.copyWith(spendingCategories: updatedCategories);
    notifyListeners();
  }

  // Update spending category
  void updateSpendingCategory(int index, SpendingCategory updatedCategory) {
    final updatedCategories = List<SpendingCategory>.from(_profileData.spendingCategories);
    updatedCategories[index] = updatedCategory;
    _profileData = _profileData.copyWith(spendingCategories: updatedCategories);
    notifyListeners();
  }

  // Delete spending category
  void deleteSpendingCategory(int index) {
    final updatedCategories = List<SpendingCategory>.from(_profileData.spendingCategories);
    updatedCategories.removeAt(index);
    _profileData = _profileData.copyWith(spendingCategories: updatedCategories);
    notifyListeners();
  }

  // Add financial goal
  void addFinancialGoal(FinancialGoal goal) {
    final updatedGoals = List<FinancialGoal>.from(_profileData.financialGoals)..add(goal);
    _profileData = _profileData.copyWith(financialGoals: updatedGoals);
    notifyListeners();
  }

  // Update financial goal
  void updateFinancialGoal(int index, FinancialGoal updatedGoal) {
    final updatedGoals = List<FinancialGoal>.from(_profileData.financialGoals);
    updatedGoals[index] = updatedGoal;
    _profileData = _profileData.copyWith(financialGoals: updatedGoals);
    notifyListeners();
  }

  // Delete financial goal
  void deleteFinancialGoal(int index) {
    final updatedGoals = List<FinancialGoal>.from(_profileData.financialGoals);
    updatedGoals.removeAt(index);
    _profileData = _profileData.copyWith(financialGoals: updatedGoals);
    notifyListeners();
  }

  // Update loan information
  void updateCarLoan(Map<String, dynamic> loanData) {
    _profileData = _profileData.copyWith(carLoan: loanData);
    notifyListeners();
  }

  void updateHomeLoan(Map<String, dynamic> loanData) {
    _profileData = _profileData.copyWith(homeLoan: loanData);
    notifyListeners();
  }

  // Add new loan
  void addNewLoan(String loanType, Map<String, dynamic> loanData) {
    if (loanType == 'car') {
      _profileData = _profileData.copyWith(carLoan: loanData);
    } else if (loanType == 'home') {
      _profileData = _profileData.copyWith(homeLoan: loanData);
    }
    notifyListeners();
  }

  // Add investment
  void addInvestment(Investment investment) {
    final updatedInvestments = List<Investment>.from(_profileData.investments)..add(investment);
    _profileData = _profileData.copyWith(investments: updatedInvestments);
    notifyListeners();
  }

  // Update investment
  void updateInvestment(int index, Investment updatedInvestment) {
    final updatedInvestments = List<Investment>.from(_profileData.investments);
    updatedInvestments[index] = updatedInvestment;
    _profileData = _profileData.copyWith(investments: updatedInvestments);
    notifyListeners();
  }

  // Delete investment
  void deleteInvestment(int index) {
    final updatedInvestments = List<Investment>.from(_profileData.investments);
    updatedInvestments.removeAt(index);
    _profileData = _profileData.copyWith(investments: updatedInvestments);
    notifyListeners();
  }

  // Update investment portfolio
  void updateInvestmentPortfolio(Map<String, dynamic> portfolioData) {
    _profileData = _profileData.copyWith(investmentPortfolio: portfolioData);
    notifyListeners();
  }
}