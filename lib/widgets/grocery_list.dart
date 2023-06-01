import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:shopping_list/widgets/new_item.dart';
import 'package:http/http.dart' as http;

import '../data/categories.dart';
import '../models/grocery_item.dart';

class GroceryList extends StatefulWidget {
  const GroceryList({super.key});

  @override
  State<GroceryList> createState() => _GroceryListState();
}

class _GroceryListState extends State<GroceryList> {
  List<GroceryItem> groceryItems = [];
  var isLoading = true;

  @override
  void initState() {
    super.initState();
    loadItems();
  }

  void loadItems() async {
    final url = Uri.https(
        'flutter-prep-ba5dd-default-rtdb.firebaseio.com', 'shopping-list.json');
    final response = await http.get(url);
    if (response.body == "null") {
      setState(() {
        isLoading = false;
      });
      return;
    }
    final Map<String, dynamic> listData = json.decode(response.body);
    final List<GroceryItem> loadedItemList = [];
    for (final item in listData.entries) {
      final category = categories.entries
          .firstWhere(
              (catItem) => catItem.value.title == item.value['category'])
          .value;
      loadedItemList.add(GroceryItem(
          id: item.key,
          name: item.value['name'],
          quantity: item.value['quantity'],
          category: category));
    }
    setState(() {
      groceryItems = loadedItemList;
      isLoading = false;
    });
  }

  void addItem() async {
    final newItem = await Navigator.push<GroceryItem>(
        context, MaterialPageRoute(builder: (context) => const NewItem()));
    loadItems();
    if (newItem == null) {
      return;
    }
    setState(() {
      groceryItems.add(newItem);
    });
  }

  void removeItem(GroceryItem item) {
    final url = Uri.https('flutter-prep-ba5dd-default-rtdb.firebaseio.com',
        'shopping-list/${item.id}.json');
    http.delete(url);
    setState(() {
      groceryItems.remove(item);
    });
  }

  @override
  Widget build(BuildContext context) {
    Widget content = const Center(
      child: Text("No Items Added Yet..."),
    );

    if (isLoading) {
      content = const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (groceryItems.isNotEmpty) {
      content = ListView.builder(
        itemCount: groceryItems.length,
        itemBuilder: (ctx, index) => Dismissible(
          onDismissed: (direction) {
            removeItem(groceryItems[index]);
          },
          key: ValueKey(groceryItems[index].id),
          child: ListTile(
            title: Text(groceryItems[index].name),
            leading: Container(
              width: 24,
              height: 24,
              color: groceryItems[index].category.color,
            ),
            trailing: Text(
              groceryItems[index].quantity.toString(),
            ),
          ),
        ),
      );
    }
    return Scaffold(
        appBar: AppBar(
          title: const Text('Your Groceries'),
          actions: [
            IconButton(
              onPressed: addItem,
              icon: const Icon(Icons.add),
            )
          ],
        ),
        body: content);
  }
}
