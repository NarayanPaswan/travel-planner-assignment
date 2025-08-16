import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/expense.dart';

class ExpenseService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // Create new expense
  Future<Expense> createExpense({
    required String tripId,
    required String description,
    required double amount,
    String currency = 'USD',
    String? category,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) throw Exception('No user logged in');

      final response = await _supabase
          .from('expenses')
          .insert({
            'trip_id': tripId,
            'user_id': user.id,
            'description': description,
            'amount': amount,
            'currency': currency,
            'category': category,
          })
          .select()
          .single();
      
      return Expense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to create expense: $e');
    }
  }

  // Update expense
  Future<Expense> updateExpense({
    required String expenseId,
    String? description,
    double? amount,
    String? currency,
    String? category,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (description != null) updateData['description'] = description;
      if (amount != null) updateData['amount'] = amount;
      if (currency != null) updateData['currency'] = currency;
      if (category != null) updateData['category'] = category;

      final response = await _supabase
          .from('expenses')
          .update(updateData)
          .eq('id', expenseId)
          .select()
          .single();
      
      return Expense.fromJson(response);
    } catch (e) {
      throw Exception('Failed to update expense: $e');
    }
  }

  // Delete expense
  Future<void> deleteExpense(String expenseId) async {
    try {
      await _supabase
          .from('expenses')
          .delete()
          .eq('id', expenseId);
    } catch (e) {
      throw Exception('Failed to delete expense: $e');
    }
  }

  // Get expenses by trip ID
  Future<List<Expense>> getExpensesByTrip(String tripId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('trip_id', tripId)
          .order('created_at', ascending: false);
      
      return (response as List).map((json) => Expense.fromJson(json)).toList();
    } catch (e) {
      throw Exception('Failed to fetch expenses: $e');
    }
  }

  // Get expense by ID
  Future<Expense?> getExpenseById(String expenseId) async {
    try {
      final response = await _supabase
          .from('expenses')
          .select()
          .eq('id', expenseId)
          .single();
      
      return Expense.fromJson(response);
    } catch (e) {
      return null;
    }
  }

  // Get total expenses for a trip
  Future<double> getTotalExpenses(String tripId, {String? currency}) async {
    try {
      final expenses = await getExpensesByTrip(tripId);
      final targetCurrency = currency ?? 'USD';
      
      double total = 0.0;
      for (final expense in expenses) {
        if (expense.currency == targetCurrency) {
          total += expense.amount;
        }
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  // Get expenses by category for a trip
  Future<Map<String, double>> getExpensesByCategory(String tripId, {String? currency}) async {
    try {
      final expenses = await getExpensesByTrip(tripId);
      final targetCurrency = currency ?? 'USD';
      
      final categoryMap = <String, double>{};
      
      for (final expense in expenses) {
        if (expense.currency == targetCurrency) {
          final category = expense.category ?? 'Other';
          categoryMap[category] = (categoryMap[category] ?? 0.0) + expense.amount;
        }
      }
      
      return categoryMap;
    } catch (e) {
      return {};
    }
  }
}
