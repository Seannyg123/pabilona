import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../models/transaction.dart';
import '../models/friend.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortBy = 'date'; // 'date', 'amount', 'name'
  bool _sortAscending = false;
  Set<String> _selectedTransactions = {};
  bool _isSelectionMode = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  List<Transaction> _sortTransactions(List<Transaction> transactions) {
    final friendsBox = Hive.box<Friend>('friends');
    
    switch (_sortBy) {
      case 'date':
        transactions.sort((a, b) => _sortAscending 
          ? a.date.compareTo(b.date)
          : b.date.compareTo(a.date));
        break;
      case 'amount':
        transactions.sort((a, b) => _sortAscending 
          ? a.amount.compareTo(b.amount)
          : b.amount.compareTo(a.amount));
        break;
      case 'name':
        transactions.sort((a, b) {
          final friendA = friendsBox.get(a.friendId);
          final friendB = friendsBox.get(b.friendId);
          return _sortAscending 
            ? (friendA?.name ?? '').compareTo(friendB?.name ?? '')
            : (friendB?.name ?? '').compareTo(friendA?.name ?? '');
        });
        break;
    }
    return transactions;
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    if (_searchQuery.isEmpty) return transactions;
    
    final friendsBox = Hive.box<Friend>('friends');
    final query = _searchQuery.toLowerCase();
    
    return transactions.where((transaction) {
      final friend = friendsBox.get(transaction.friendId);
      return (friend?.name.toLowerCase().contains(query) ?? false) ||
             (transaction.description?.toLowerCase().contains(query) ?? false) ||
             transaction.amount.toString().contains(query) ||
             DateFormat('yyyy-MM-dd').format(transaction.date).contains(query);
    }).toList();
  }

  void _toggleSelection(String transactionId) {
    setState(() {
      if (_selectedTransactions.contains(transactionId)) {
        _selectedTransactions.remove(transactionId);
      } else {
        _selectedTransactions.add(transactionId);
      }
      
      if (_selectedTransactions.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _archiveSelected() {
    final transactionsBox = Hive.box<Transaction>('transactions');
    for (final id in _selectedTransactions) {
      final transaction = transactionsBox.values.firstWhere((t) => t.id == id);
      transaction.archive();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_selectedTransactions.length} transactions archived'),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final id in _selectedTransactions) {
              final transaction = transactionsBox.values.firstWhere((t) => t.id == id);
              transaction.unarchive();
            }
          },
        ),
      ),
    );
    
    setState(() {
      _selectedTransactions.clear();
      _isSelectionMode = false;
    });
  }

  void _deleteSelected() {
    final transactionsBox = Hive.box<Transaction>('transactions');
    final selectedTransactions = _selectedTransactions.toList();
    final deletedTransactions = <Transaction>[];
    
    // Store transactions before deletion for potential undo
    for (final id in selectedTransactions) {
      final transaction = transactionsBox.values.firstWhere((t) => t.id == id);
      deletedTransactions.add(transaction);
      transaction.delete();
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${selectedTransactions.length} transactions deleted permanently'),
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () {
            for (final transaction in deletedTransactions) {
              transactionsBox.put(transaction.id, transaction);
            }
          },
        ),
      ),
    );
    
    setState(() {
      _selectedTransactions.clear();
      _isSelectionMode = false;
    });
  }

  void _selectAll(List<Transaction> transactions) {
    setState(() {
      _selectedTransactions.addAll(transactions.map((t) => t.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedTransactions.clear();
      _isSelectionMode = false;
    });
  }

  void _invertSelection(List<Transaction> transactions) {
    setState(() {
      final allIds = transactions.map((t) => t.id).toSet();
      final newSelection = allIds.difference(_selectedTransactions);
      _selectedTransactions = newSelection;
      
      if (_selectedTransactions.isEmpty) {
        _isSelectionMode = false;
      }
    });
  }

  void _showSelectionDialog(List<Transaction> transactions) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Selection Options'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.select_all),
              title: const Text('Select All'),
              onTap: () {
                Navigator.pop(context);
                _selectAll(transactions);
              },
            ),
            ListTile(
              leading: const Icon(Icons.deselect),
              title: const Text('Deselect All'),
              onTap: () {
                Navigator.pop(context);
                _deselectAll();
              },
            ),
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Invert Selection'),
              onTap: () {
                Navigator.pop(context);
                _invertSelection(transactions);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(int count) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.warning, color: Colors.red),
            const SizedBox(width: 8),
            const Text('Confirm Deletion'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'You are about to permanently delete:',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '• $count transaction${count > 1 ? 's' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const Text(
              'This action cannot be undone after 5 seconds. '
              'Are you sure you want to proceed?',
              style: TextStyle(color: Colors.red),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.cancel),
            label: const Text('Cancel'),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.of(context).pop();
              _deleteSelected();
            },
            icon: const Icon(Icons.delete_forever),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            label: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: !_isSelectionMode 
          ? const Text('Transaction History')
          : Text('Selected: ${_selectedTransactions.length}'),
        actions: [
          if (_tabController.index == 0 && !_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () => setState(() => _isSelectionMode = true),
              tooltip: 'Select Transactions',
            ),
          if (_isSelectionMode) ...[
            IconButton(
              icon: const Icon(Icons.more_vert),
              onPressed: () {
                final box = Hive.box<Transaction>('transactions');
                final transactions = box.values
                    .where((t) => t.isArchived == (_tabController.index == 1))
                    .toList();
                _showSelectionDialog(transactions);
              },
              tooltip: 'Selection Options',
            ),
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _deselectAll,
              tooltip: 'Cancel Selection',
            ),
            if (_tabController.index == 0) ...[
              IconButton(
                icon: const Icon(Icons.archive),
                onPressed: _selectedTransactions.isEmpty ? null : _archiveSelected,
                tooltip: 'Archive Selected',
              ),
            ],
            if (_tabController.index == 1) ...[
              IconButton(
                icon: const Icon(Icons.unarchive),
                onPressed: _selectedTransactions.isEmpty ? null : () {
                  for (final id in _selectedTransactions) {
                    final transaction = Hive.box<Transaction>('transactions')
                        .values
                        .firstWhere((t) => t.id == id);
                    transaction.unarchive();
                  }
                  setState(() {
                    _selectedTransactions.clear();
                    _isSelectionMode = false;
                  });
                },
                tooltip: 'Restore Selected',
              ),
              IconButton(
                icon: const Icon(Icons.delete_forever),
                onPressed: _selectedTransactions.isEmpty 
                    ? null 
                    : () => _showDeleteConfirmation(_selectedTransactions.length),
                tooltip: 'Delete Selected Permanently',
              ),
            ],
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'Archived'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Search transactions...',
                      prefixIcon: Icon(Icons.search),
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.sort),
                  onSelected: (value) {
                    setState(() {
                      if (_sortBy == value) {
                        _sortAscending = !_sortAscending;
                      } else {
                        _sortBy = value;
                        _sortAscending = true;
                      }
                    });
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'date',
                      child: Text('Sort by Date'),
                    ),
                    const PopupMenuItem(
                      value: 'amount',
                      child: Text('Sort by Amount'),
                    ),
                    const PopupMenuItem(
                      value: 'name',
                      child: Text('Sort by Name'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTransactionList(false),
                _buildTransactionList(true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionList(bool archived) {
    return ValueListenableBuilder(
      valueListenable: Hive.box<Transaction>('transactions').listenable(),
      builder: (context, box, _) {
        var transactions = box.values
            .where((t) => t.isArchived == archived)
            .toList();
        
        transactions = _sortTransactions(transactions);
        transactions = _filterTransactions(transactions);

        if (transactions.isEmpty) {
          return Center(
            child: Text(
              archived 
                ? 'No archived transactions'
                : 'No transactions found',
            ),
          );
        }

        return ListView.builder(
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final transaction = transactions[index];
            final friend = Hive.box<Friend>('friends').get(transaction.friendId);
            final isDebt = transaction.type == TransactionType.debt;
            
            Widget listItem = Card(
              margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: ListTile(
                leading: _isSelectionMode
                    ? Checkbox(
                        value: _selectedTransactions.contains(transaction.id),
                        onChanged: (bool? value) => _toggleSelection(transaction.id),
                      )
                    : CircleAvatar(
                        backgroundColor: isDebt ? Colors.red : Colors.green,
                        child: Icon(
                          isDebt ? Icons.arrow_downward : Icons.arrow_upward,
                          color: Colors.white,
                        ),
                      ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        friend?.name ?? 'Deleted Friend',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDebt ? Colors.red.shade50 : Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        isDebt ? 
                          transaction.youOweThemMode ? 'You Borrowed' : 'They Borrowed' 
                          : transaction.youOweThemMode ? 'You Paid' : 'They Paid',
                        style: TextStyle(
                          color: isDebt ? Colors.red : Colors.green,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(_getTransactionDescription(transaction, friend)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${isDebt ? '+' : '-'}₱${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isDebt ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      DateFormat('MMM d, y').format(transaction.date),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );

            if (!_isSelectionMode) {
              listItem = Dismissible(
                key: Key(transaction.id),
                background: Container(
                  color: archived ? Colors.blue : Colors.orange,
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20.0),
                  child: Icon(
                    archived ? Icons.unarchive : Icons.archive,
                    color: Colors.white,
                  ),
                ),
                direction: DismissDirection.endToStart,
                onDismissed: (direction) {
                  if (archived) {
                    transaction.unarchive();
                  } else {
                    transaction.archive();
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(archived 
                        ? 'Transaction restored'
                        : 'Transaction archived'),
                      action: SnackBarAction(
                        label: 'Undo',
                        onPressed: () {
                          if (archived) {
                            transaction.archive();
                          } else {
                            transaction.unarchive();
                          }
                        },
                      ),
                    ),
                  );
                },
                child: listItem,
              );
            }

            return InkWell(
              onLongPress: () {
                setState(() {
                  _isSelectionMode = true;
                  _toggleSelection(transaction.id);
                });
              },
              onTap: _isSelectionMode
                  ? () => _toggleSelection(transaction.id)
                  : null,
              child: listItem,
            );
          },
        );
      },
    );
  }

  String _getTransactionDescription(Transaction transaction, Friend? friend) {
    final name = friend?.name ?? 'This person';
    final formattedAmount = '₱${transaction.amount.toStringAsFixed(2)}';
    final timeStr = DateFormat('h:mm a').format(transaction.date);
    final isDebt = transaction.type == TransactionType.debt;
    final youOweThemMode = transaction.youOweThemMode;

    // If there's a custom description, combine it with the transaction details
    if (transaction.description?.isNotEmpty ?? false) {
      String relationshipStr = isDebt
          ? (youOweThemMode ? "You borrowed from $name" : "$name borrowed from you")
          : (youOweThemMode ? "You paid $name" : "$name paid you");
      
      return '${transaction.description!}\n'
             '$relationshipStr $formattedAmount at $timeStr';
    }

    // Default descriptions with more context
    if (isDebt) {
      if (youOweThemMode) {
        return 'You borrowed $formattedAmount from $name\n'
               'Debt recorded at $timeStr';
      } else {
        return '$name borrowed $formattedAmount from you\n'
               'Debt recorded at $timeStr';
      }
    } else {
      if (youOweThemMode) {
        return 'You paid $formattedAmount to $name\n'
               'Payment recorded at $timeStr';
      } else {
        return '$name paid you $formattedAmount\n'
               'Payment recorded at $timeStr';
      }
    }
  }
} 