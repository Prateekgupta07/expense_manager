import 'dart:io';

import 'package:currency_picker/currency_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'db/database_helper.dart';

class RecordExpensePage extends StatefulWidget {
  @override
  _RecordExpensePageState createState() => _RecordExpensePageState();
}

class _RecordExpensePageState extends State<RecordExpensePage> {
  final _amountController = TextEditingController();
  final _categoryController = TextEditingController();
  String _selectedPaymentMethod = 'Cash';
  String? _selectedCurrency;
  late InterstitialAd _interstitialAd;
  bool _isInterstitialAdReady = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedCurrency();
    _loadInterstitialAd();

  }

  @override
  void dispose() {
    _amountController.dispose();
    _categoryController.dispose();
    super.dispose();
  }
  void _loadInterstitialAd() {
    InterstitialAd.load(
      adUnitId: Platform.isAndroid?'ca-app-pub-4952514290719439/9108447957':'ca-app-pub-4952514290719439/6449698864',
      request: AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (InterstitialAd ad) {
          _interstitialAd = ad;
          _isInterstitialAdReady = true;
        },
        onAdFailedToLoad: (LoadAdError error) {
          print('Failed to load an interstitial ad: ${error.message}');
          _isInterstitialAdReady = false;
        },
      ),
    );
  }

  void _showInterstitialAd() {
    if (_isInterstitialAdReady) {
      _interstitialAd.show();
      _interstitialAd.fullScreenContentCallback = FullScreenContentCallback(
        onAdDismissedFullScreenContent: (InterstitialAd ad) {
          ad.dispose();
          _loadInterstitialAd();
        },
        onAdFailedToShowFullScreenContent: (InterstitialAd ad, AdError error) {
          ad.dispose();
          print('Failed to show an interstitial ad: ${error.message}');
          _loadInterstitialAd();
        },
      );
    }
  }

  Future<void> _loadSelectedCurrency() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      _selectedCurrency = prefs.getString('selected_currency') ?? '\$';
    });
  }

  Future<void> _saveSelectedCurrency(String currency) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('selected_currency', currency);
  }

  Future<void> _saveExpense() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null) {
      // Show error if amount is not a valid number
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }
    await DatabaseHelper().insertExpense(
        amount, _categoryController.text, _selectedPaymentMethod);
    _showInterstitialAd();

    Navigator.pop(context, true); // Return to previous page and refresh data
  }

  void _showCurrencyPicker() {
    showCurrencyPicker(
      context: context,
      showFlag: true,
      showCurrencyName: true,
      showCurrencyCode: true,
      onSelect: (Currency currency) {
        setState(() {
          _selectedCurrency = currency.symbol;
          _saveSelectedCurrency(currency.symbol);
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: Text('Record Expense')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(flex: 1,
                  child: InkWell(
                    onTap: _showCurrencyPicker,
                    child: Row(
                      children: [
                        Icon(Icons.arrow_drop_down_outlined),
                        Text(_selectedCurrency ?? "\$")
                      ],
                    ),
                  ),
                ),
                Expanded(flex: 4,
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(labelText: 'Amount'),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _categoryController,
              keyboardType: TextInputType.text,
              decoration: InputDecoration(labelText: 'Category'),
            ),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items: ['Cash', 'Card', 'Online']
                  .map((method) => DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedPaymentMethod = value!;
                });
              },
              decoration: InputDecoration(labelText: 'Payment Method'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveExpense,
              child: Text('Save Expense'),
            ),
          ],
        ),
      ),
    );
  }
}
