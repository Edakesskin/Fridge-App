import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fridge_colors.dart';
import 'food_database.dart';

void main() {
  runApp(const FridgeApp());
}

/// APP CLOCK

class AppClock {
  static int offsetDays = 0;

  static DateTime now() => DateTime.now().add(Duration(days: offsetDays));

  static void addDays(int days) => offsetDays += days;

  static void reset() => offsetDays = 0;
}


/// APP ROOT

class FridgeApp extends StatelessWidget {
  const FridgeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: "Fridge App",
      theme: ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: const HomePage(),
    );
  }
}


/// MODEL FOR A FRIDGE ITEM

class FridgeItem {
  final String name;
  final int quantity;
  final DateTime expirationDate;
  final String unit;
  final IconData icon;
  final DateTime addedDate;

  FridgeItem({
    required this.name,
    required this.quantity,
    required this.expirationDate,
    required this.icon,
    this.unit = 'pcs',
    DateTime? addedDate,
  }) : addedDate = addedDate ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'expirationDate': expirationDate.toIso8601String(),
        'unit': unit,
        'iconCodePoint': icon.codePoint,
        'iconFontFamily': icon.fontFamily,
        'addedDate': addedDate.toIso8601String(),
      };

  factory FridgeItem.fromJson(Map<String, dynamic> json) => FridgeItem(
        name: json['name'] as String,
        quantity: json['quantity'] as int,
        expirationDate: DateTime.parse(json['expirationDate'] as String),
        unit: json['unit'] as String? ?? 'pcs',
        icon: IconData(
          json['iconCodePoint'] as int,
          fontFamily: json['iconFontFamily'] as String?,
        ),
        addedDate: json['addedDate'] != null
            ? DateTime.parse(json['addedDate'] as String)
            : DateTime.now(),
      );
}


/// SHARED UI HELPERS


/// Strips the time-of-day so all day math happens on clean midnight 
/// dates. Made to fix the one-day-off bug.
DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

/// Pink border color based on remaining shelf life (Stage 1 → Stage 5).
Color expirationBorderColor(FridgeItem item) {
  final now = dateOnly(AppClock.now());
  final exp = dateOnly(item.expirationDate);
  final remainingDays = exp.difference(now).inDays;

  if (remainingDays < 0) return Colors.black;

  final totalDays = exp.difference(dateOnly(item.addedDate)).inDays;
  final safeTotal = totalDays <= 0 ? 1 : totalDays;
  final ratio = (remainingDays / safeTotal).clamp(0.0, 1.0);

  if (ratio > 0.75) return AppColors.mypink.withValues(alpha: 0.10);
  if (ratio > 0.50) return AppColors.mypink.withValues(alpha: 0.30);
  if (ratio > 0.25) return AppColors.mypink.withValues(alpha: 0.60);
  return AppColors.mypink;
}

/// Full display labels for the unit dropdown on page 2.
const Map<String, String> unitDisplayLabels = {
  'kg': 'Kilograms (kg)',
  'g': 'Grams (g)',
  'L': 'Liters (L)',
  'ml': 'Milliliters (ml)',
  'pcs': 'Pieces (pcs)',
};

/// The days remaining count with the number bolded.
Widget buildDaysRemainingText(FridgeItem item) {
  final now = dateOnly(AppClock.now());
  final exp = dateOnly(item.expirationDate);
  final diff = exp.difference(now).inDays;

  const base = TextStyle(color: Colors.black, fontSize: 24);
  const bold = TextStyle(
    color: Colors.black,
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  if (diff < 0) {
    final overdue = -diff;
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          const TextSpan(text: "Expired "),
          TextSpan(text: "$overdue", style: bold),
          TextSpan(text: overdue == 1 ? " day ago" : " days ago"),
        ],
      ),
    );
  }

  if (diff == 0) {
    return const Text(
      "Expires today",
      style: TextStyle(color: Colors.black, fontSize: 24),
    );
  }

  return Text.rich(
    TextSpan(
      style: base,
      children: [
        const TextSpan(text: "Good for "),
        TextSpan(text: "$diff", style: bold),
        TextSpan(text: diff == 1 ? " more day" : " more days"),
      ],
    ),
  );
}

/// Standard button styles used across both pages.
ButtonStyle primaryButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.mygreen,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.blueGrey, width: 1),
      ),
    );

ButtonStyle editButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.blueGrey, width: 1),
      ),
    );

ButtonStyle deleteButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.myblue,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: Colors.blueGrey, width: 1),
      ),
    );

ButtonStyle saveButtonStyle() => ElevatedButton.styleFrom(
      backgroundColor: AppColors.myblue,
      foregroundColor: Colors.white,
    );


/// ITEM AVATAR
/// Food icon when the name matches the database, if not, the default logo (Icons.image).

Widget buildItemAvatar(FridgeItem item) {
  final match = foodDatabase.where(
    (food) => food.name.toLowerCase() == item.name.toLowerCase(),
  );

  final IconData icon = match.isNotEmpty ? match.first.icon : Icons.image;

  return CircleAvatar(
    radius: 40,
    backgroundColor: Colors.black,
    child: Icon(icon, size: 40, color: Colors.white),
  );
}

/// Category of an item, derived by matching its name against the food database. Unknown names > "Other".
String categoryForItem(FridgeItem item) {
  final match = foodDatabase.where(
    (food) => food.name.toLowerCase() == item.name.toLowerCase(),
  );

  return match.isNotEmpty ? match.first.category : "Other";
}


/// RESPONSIVE HELPER

class ResponsiveWidth extends StatelessWidget {
  final Widget child;
  const ResponsiveWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600),
        child: child,
      ),
    );
  }
}


/// PAGE 1 Design

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<FridgeItem> fridgeItems = [];

  final TextEditingController searchController = TextEditingController();
  String searchQuery = "";

  String sortOption = "newestAdded";
  String selectedCategory = "All";
  FridgeItem? expandedItem;

  static const String _storageKey = 'fridge_items';

  @override
  void initState() {
    super.initState();
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? raw = prefs.getString(_storageKey);
      if (raw == null || raw.isEmpty) return;

      final List decoded = jsonDecode(raw) as List;
      final items = decoded
          .map((e) => FridgeItem.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();

      if (!mounted) return;
      setState(() {
        fridgeItems = items;
      });
    } catch (_) {
      // Corrupted data: start with an empty fridge
    }
  }

  Future<void> _saveItems() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        _storageKey,
        jsonEncode(fridgeItems.map((e) => e.toJson()).toList()),
      );
    } catch (_) {}
  }

  String get sortLabel => sortOption == "newestAdded"
      ? "Newest Addition First"
      : "Closest Expiry Date First";

  List<FridgeItem> getSortedItems() {
    List<FridgeItem> source = fridgeItems;

    if (selectedCategory != "All") {
      source = source
          .where((item) => categoryForItem(item) == selectedCategory)
          .toList();
    }

    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      source = source
          .where((item) => item.name.toLowerCase().contains(query))
          .toList();
    }

    final sorted = List<FridgeItem>.from(source);
    if (sortOption == "newestAdded") {
      sorted.sort((a, b) => b.addedDate.compareTo(a.addedDate));
    } else if (sortOption == "closestExpiry") {
      sorted.sort((a, b) => a.expirationDate.compareTo(b.expirationDate));
    }

    return sorted;
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFFE5E5EA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: searchController,
        onChanged: (value) => setState(() => searchQuery = value),
        decoration: InputDecoration(
          hintText: "Search",
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Colors.grey),
                  onPressed: () {
                    searchController.clear();
                    setState(() => searchQuery = "");
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildCategoryChips() {
    final categories = <String>["All", ...foodCategories];

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final cat in categories)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    cat,
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  selected: selectedCategory == cat,
                  onSelected: (_) {
                    setState(() {
                      selectedCategory = cat;
                    });
                  },
                  backgroundColor: Colors.white,
                  selectedColor: AppColors.mypink,
                  side: const BorderSide(color: Colors.black),
                  labelPadding: const EdgeInsets.symmetric(horizontal: 8),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSortButton() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: PopupMenuButton<String>(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        color: Colors.white,
        onSelected: (value) {
          setState(() {
            sortOption = value;
          });
        },
        itemBuilder: (context) => [
          PopupMenuItem(
            value: "newestAdded",
            child: Row(
              children: [
                Icon(
                  Icons.new_releases,
                  color: sortOption == "newestAdded"
                      ? AppColors.mypink
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text("Newest Addition First"),
              ],
            ),
          ),
          PopupMenuItem(
            value: "closestExpiry",
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: sortOption == "closestExpiry"
                      ? AppColors.mypink
                      : Colors.grey,
                ),
                const SizedBox(width: 8),
                const Text("Closest Expiry Date First"),
              ],
            ),
          ),
        ],
        /// NEW: fixed at 48px — the same height as the search box
        child: Container(
          height: 48,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: Colors.blueGrey),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              const Icon(Icons.sort, color: Colors.black),
              const SizedBox(width: 10),
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    "Sorting: $sortLabel",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                ),
              ),
              const Icon(Icons.arrow_drop_down, color: Colors.black),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEditDialog(FridgeItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final dateCtrl = TextEditingController(
      text:
          "${item.expirationDate.day}/${item.expirationDate.month}/${item.expirationDate.year}",
    );
    DateTime expDate = item.expirationDate;
    String unit = item.unit;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Edit item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Item",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: unit,
                            underline: const SizedBox(),
                            items: ['kg', 'g', 'L', 'ml', 'pcs']
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setDialogState(() => unit = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: expDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        expDate = picked;
                        dateCtrl.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      },
                      decoration: const InputDecoration(
                        labelText: "Expiration Date",
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyCtrl.text.trim());
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty || qty == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in name and quantity"),
                        ),
                      );
                      return;
                    }

                    final match = foodDatabase.where(
                      (food) => food.name.toLowerCase() == name.toLowerCase(),
                    );
                    final newIcon =
                        match.isNotEmpty ? match.first.icon : item.icon;

                    final updated = FridgeItem(
                      name: name,
                      quantity: qty,
                      expirationDate: expDate,
                      unit: unit,
                      icon: newIcon,
                      addedDate: item.addedDate,
                    );

                    Navigator.pop(dialogContext);
                    setState(() {
                      final idx = fridgeItems.indexOf(item);
                      if (idx != -1) fridgeItems[idx] = updated;
                      expandedItem = null;
                    });
                    _saveItems();
                  },
                  style: saveButtonStyle(),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(FridgeItem item) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete item?"),
          content: Text(
            'Are you sure you want to remove "${item.name}" from your fridge?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: deleteButtonStyle(),
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    final originalIndex = fridgeItems.indexOf(item);

    setState(() {
      fridgeItems.remove(item);
      expandedItem = null;
    });
    _saveItems();

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('Deleted "${item.name}"'),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              if (!mounted) return;
              setState(() {
                fridgeItems.insert(originalIndex, item);
              });
              _saveItems();
            },
          ),
        ),
      );
  }

  Future<void> _showTimeTravelDialog() async {
    await showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Time travel (testing)"),
          content: const Text(
            "Move the app's clock forward to test how items age. "
            "This does not change any saved data.",
          ),
          actions: [
            TextButton(
              onPressed: () {
                AppClock.reset();
                Navigator.pop(dialogContext);
              },
              child: const Text("Reset"),
            ),
            TextButton(
              onPressed: () {
                AppClock.addDays(90);
                Navigator.pop(dialogContext);
              },
              child: const Text("+90 days"),
            ),
            TextButton(
              onPressed: () {
                AppClock.addDays(30);
                Navigator.pop(dialogContext);
              },
              child: const Text("+30 days"),
            ),
            TextButton(
              onPressed: () {
                AppClock.addDays(7);
                Navigator.pop(dialogContext);
              },
              child: const Text("+7 days"),
            ),
            TextButton(
              onPressed: () {
                AppClock.addDays(1);
                Navigator.pop(dialogContext);
              },
              child: const Text("+1 day"),
            ),
          ],
        );
      },
    );

    if (mounted) setState(() {});
  }

  /// The FAB wrapped in a Stack with a transparent "dead zone" strip over the bottom ~20px. Taps there
  /// are absorbed and never reach the button.
  Widget _buildFabWithDeadZone() {
    return SizedBox(
      width: 120,
      height: 120,
      child: Stack(
        children: [
          Positioned.fill(
            child: FloatingActionButton(
              backgroundColor: Colors.black,
              shape: const CircleBorder(),
              elevation: 8,
              onPressed: () async {
                final List<FridgeItem>? newItems = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ShoppingPage(),
                  ),
                );

                if (newItems != null) {
                  setState(() {
                    fridgeItems.insertAll(0, newItems);
                  });
                  _saveItems();
                }
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Text(
                    "Add",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "Items",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      height: 0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Icon(
                    Icons.shopping_basket,
                    color: Colors.white,
                    size: 50,
                  ),
                ],
              ),
            ),
          ),

          /// Transparent strip over the bottom edge that swallows taps (~0.5 cm untouchable)
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 20,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {},
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visibleItems = getSortedItems();

    Widget listContent;
    if (fridgeItems.isEmpty) {
      listContent = const Center(
        child: Text(
          "No items yet.\nGo shopping!",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 30),
        ),
      );
    } else if (visibleItems.isEmpty) {
      if (searchQuery.isNotEmpty) {
        listContent = Center(
          child: Text(
            'No results for "$searchQuery"',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 24),
          ),
        );
      } else {
        listContent = const Center(
          child: Text(
            "No items in this category",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24),
          ),
        );
      }
    } else {
      listContent = ResponsiveWidth(
        child: ListView.builder(
          itemCount: visibleItems.length,
          itemBuilder: (context, index) {
            final item = visibleItems[index];
            final isExpanded = expandedItem == item;

            /// Structure: the GestureDetector covers the whole
            /// card interior (behavior: opaque), so a second tap
            /// anywhere on the card retracts the buttons. The
            /// pink border ring itself stays tap-dead.
            return AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: isExpanded ? const Color(0xFFEFEFEF) : Colors.white,
                  border: Border.all(
                    color: expirationBorderColor(item),
                    width: 8,
                  ),
                  borderRadius: BorderRadius.circular(40),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(212, 0, 0, 0),
                      blurRadius: 6,
                      offset: Offset(0, 3),
                    ),
                  ],
                ),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      expandedItem = isExpanded ? null : item;
                    });
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            buildItemAvatar(item),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                children: [
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        style: const TextStyle(
                                          color: Colors.black,
                                          fontSize: 24,
                                        ),
                                        children: [
                                          TextSpan(
                                            text: '${item.quantity} ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '${item.unit} ',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          const TextSpan(
                                            text: 'of ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.normal,
                                            ),
                                          ),
                                          TextSpan(
                                            text: item.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      border: Border.all(),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: buildDaysRemainingText(item),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        if (isExpanded) ...[
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _showEditDialog(item),
                                  style: editButtonStyle(),
                                  child: const Text(
                                    "Edit",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => _confirmDelete(item),
                                  style: deleteButtonStyle(),
                                  child: const Text(
                                    "Delete",
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.white,
        title: GestureDetector(
          onLongPress: _showTimeTravelDialog,
          child: const Text(
            "Fridge",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          ResponsiveWidth(child: _buildSearchBar()),
          ResponsiveWidth(child: _buildSortButton()),
          ResponsiveWidth(child: _buildCategoryChips()),
          if (AppClock.offsetDays != 0)
            Container(
              width: double.infinity,
              color: Colors.amber,
              padding: const EdgeInsets.all(8),
              child: Text(
                "Time travel active: $AppClock.offsetDays day(s) in the future",
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
          Expanded(child: listContent),
        ],
      ),

      /// FAB with the bottom dead zone
      floatingActionButtonLocation:
          FloatingActionButtonLocation.centerDocked,
      floatingActionButton: _buildFabWithDeadZone(),
      bottomNavigationBar: Container(
        height: 60,
        color: Colors.white,
      ),
    );
  }
}


/// PAGE 2 Add Shopping

class ShoppingPage extends StatefulWidget {
  const ShoppingPage({super.key});

  @override
  State<ShoppingPage> createState() => _ShoppingPageState();
}

class _ShoppingPageState extends State<ShoppingPage> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController quantityController = TextEditingController();
  final TextEditingController expirationController = TextEditingController();

  /// The framework-provided controller of the autocomplete field.
  TextEditingController? _fieldController;

  /// Guards against attaching the sync listener twice.
  bool _fieldListenerAttached = false;

  DateTime? selectedDate;
  String selectedUnit = 'kg';
  final List<String> units = ['kg', 'g', 'L', 'ml', 'pcs'];
  List<FridgeItem> shoppingItems = [];
  FridgeItem? expandedTempItem;
  int? recommendedDays;
  FocusNode? _autocompleteFocusNode;

  bool _nameWarning = false;
  bool _quantityWarning = false;
  bool _dateWarning = false;

  String _formatDate(DateTime d) => "${d.day}/${d.month}/${d.year}";

  bool _validateForm() {
    final nameOk = nameController.text.trim().isNotEmpty;
    final qtyText = quantityController.text.trim();
    final qtyOk = qtyText.isNotEmpty && int.tryParse(qtyText) != null;
    final dateOk = selectedDate != null;

    setState(() {
      _nameWarning = !nameOk;
      _quantityWarning = !qtyOk;
      _dateWarning = !dateOk;
    });

    return nameOk && qtyOk && dateOk;
  }

  Widget _warningText(String message) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        message,
        style: const TextStyle(
          color: AppColors.myblue,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  String get _quantityWarningMessage => quantityController.text.trim().isEmpty
      ? "Please fill in the amount"
      : "Please enter a valid number";

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: AppClock.now(),
      firstDate: AppClock.now(),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        selectedDate = picked;
        expirationController.text = _formatDate(picked);
        _dateWarning = false;
      });
    }
  }

  bool _addItem() {
    if (!_validateForm()) return false;

    final qty = int.tryParse(quantityController.text.trim());
    if (qty == null) return false;

    final match = foodDatabase.where(
      (food) => food.name.toLowerCase() == nameController.text.toLowerCase(),
    );

    final IconData icon = match.isNotEmpty ? match.first.icon : Icons.image;

    final item = FridgeItem(
      name: nameController.text,
      quantity: qty,
      expirationDate: selectedDate!,
      unit: selectedUnit,
      icon: icon,
      addedDate: dateOnly(AppClock.now()),
    );

    setState(() {
      shoppingItems.insert(0, item);

      /// Clear the visible name field (the autocomplete's
      /// own controller), not just our mirror of it
      _fieldController?.clear();
      nameController.clear();
      quantityController.clear();
      expirationController.clear();
      selectedDate = null;
      selectedUnit = 'kg';
      recommendedDays = null;
      _nameWarning = false;
      _quantityWarning = false;
      _dateWarning = false;

      /// Drop the keyboard and suggestions so the next entry
      /// starts completely fresh.
      _autocompleteFocusNode?.unfocus();
    });
    return true;
  }

  void _finishShopping() {
    final bool hasFormData = nameController.text.trim().isNotEmpty ||
        quantityController.text.trim().isNotEmpty ||
        selectedDate != null;

    if (hasFormData) {
      final bool added = _addItem();
      if (!added) return;
    }

    Navigator.pop(context, shoppingItems);
  }

  void _applyRecommendation(FoodData food) {
    setState(() {
      recommendedDays = food.typicalShelfLifeDays;
      selectedUnit = food.typicalUnit;
      selectedDate = dateOnly(AppClock.now())
          .add(Duration(days: food.typicalShelfLifeDays));
      expirationController.text = _formatDate(selectedDate!);
      _dateWarning = false;
    });
  }

  Widget _buildRecommendationBadge() {
    final text = recommendedDays == 1
        ? "Recommendation: 1 Day"
        : "Recommendation: $recommendedDays Days";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.mygreen,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _buildQuickDayChips() {
    const presets = [1, 3, 7, 14, 30];

    final now = dateOnly(AppClock.now());
    final activeDays = selectedDate?.difference(now).inDays;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final days in presets)
          ChoiceChip(
            label: Text(
              days == 1 ? "1 Day" : "$days Days",
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
              ),
            ),
            selected: activeDays == days,
            onSelected: (_) => _pickQuickDays(days),
            backgroundColor: Colors.white,
            selectedColor: AppColors.mygreen,
            side: const BorderSide(color: Colors.blueGrey),
            labelPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
      ],
    );
  }

  void _pickQuickDays(int days) {
    setState(() {
      selectedDate = dateOnly(AppClock.now()).add(Duration(days: days));
      expirationController.text = _formatDate(selectedDate!);
      _dateWarning = false;
    });
  }

  /// Inline preview logo next to the Item field.
  /// 56px circle (radius 28) — same height as the field,
  /// so its center aligns with the field's vertical middle.
  Widget _buildPreviewAvatar() {
    final text = nameController.text.trim();

    if (text.isEmpty) {
      return _defaultPreviewAvatar();
    }

    final match = foodDatabase.where(
      (food) => food.name.toLowerCase() == text.toLowerCase(),
    );

    if (match.isEmpty) {
      return _defaultPreviewAvatar();
    }

    return CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white,
      child: Icon(match.first.icon, size: 28, color: Colors.black),
    );
  }

  Widget _defaultPreviewAvatar() {
    return const CircleAvatar(
      radius: 28,
      backgroundColor: Colors.white,
      child: Icon(Icons.image, size: 28, color: Colors.black),
    );
  }

  /// A section header, left-aligned label (optionally
  /// with a badge). Keeps the card visually unified.
  Widget _sectionLabel(String text, {Widget? trailing}) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            text,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing,
          ],
        ],
      ),
    );
  }

  Future<void> _showEditDialog(FridgeItem item) async {
    final nameCtrl = TextEditingController(text: item.name);
    final qtyCtrl = TextEditingController(text: item.quantity.toString());
    final dateCtrl = TextEditingController(
      text:
          "${item.expirationDate.day}/${item.expirationDate.month}/${item.expirationDate.year}",
    );
    DateTime expDate = item.expirationDate;
    String unit = item.unit;

    await showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            return AlertDialog(
              title: const Text("Edit item"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: "Item",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: qtyCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: "Quantity",
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: DropdownButton<String>(
                            value: unit,
                            underline: const SizedBox(),
                            items: ['kg', 'g', 'L', 'ml', 'pcs']
                                .map((u) => DropdownMenuItem(
                                      value: u,
                                      child: Text(u),
                                    ))
                                .toList(),
                            onChanged: (value) =>
                                setDialogState(() => unit = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: dateCtrl,
                      readOnly: true,
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: expDate,
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (picked == null) return;
                        expDate = picked;
                        dateCtrl.text =
                            "${picked.day}/${picked.month}/${picked.year}";
                      },
                      decoration: const InputDecoration(
                        labelText: "Expiration Date",
                        suffixIcon: Icon(Icons.calendar_today),
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text("Cancel"),
                ),
                ElevatedButton(
                  onPressed: () {
                    final qty = int.tryParse(qtyCtrl.text.trim());
                    final name = nameCtrl.text.trim();
                    if (name.isEmpty || qty == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Please fill in name and quantity"),
                        ),
                      );
                      return;
                    }

                    final match = foodDatabase.where(
                      (food) => food.name.toLowerCase() == name.toLowerCase(),
                    );
                    final newIcon =
                        match.isNotEmpty ? match.first.icon : item.icon;

                    final updated = FridgeItem(
                      name: name,
                      quantity: qty,
                      expirationDate: expDate,
                      unit: unit,
                      icon: newIcon,
                      addedDate: item.addedDate,
                    );

                    Navigator.pop(dialogContext);
                    setState(() {
                      final idx = shoppingItems.indexOf(item);
                      if (idx != -1) shoppingItems[idx] = updated;
                      expandedTempItem = null;
                    });
                  },
                  style: saveButtonStyle(),
                  child: const Text(
                    "Save",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _confirmDelete(FridgeItem item) async {
    final bool? shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text("Delete item?"),
          content: Text(
            'Are you sure you want to remove "${item.name}" from your list?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              style: deleteButtonStyle(),
              child: const Text(
                "Delete",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) return;
    if (!mounted) return;

    final originalIndex = shoppingItems.indexOf(item);

    setState(() {
      shoppingItems.remove(item);
      expandedTempItem = null;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 4),
          content: Text('Deleted "${item.name}"'),
          action: SnackBarAction(
            label: "Undo",
            onPressed: () {
              if (!mounted) return;
              setState(() {
                shoppingItems.insert(originalIndex, item);
              });
            },
          ),
        ),
      );
  }

  Future<void> _confirmExit() async {
    if (shoppingItems.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final bool? shouldSave = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Save shopping list?"),
          content: const Text(
            "You have items in your shopping list.\n"
            "Would you like to add them to your fridge before leaving?",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Discard"),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );

    if (!mounted) return;

    if (shouldSave == true) {
      Navigator.pop(context, shoppingItems);
    } else if (shouldSave == false) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (!didPop) {
          await _confirmExit();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,

        /// Title fixed to "Add Shopping"
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text(
            "Add Shopping",
            style: TextStyle(
              color: Colors.black,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: _confirmExit,
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: ResponsiveWidth(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    /// ==========================================
                    /// INPUT CARD
                    /// ==========================================
                    Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Colors.grey, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// Field + inline logo row.
                            /// The logo circle sits on the field's right;
                            /// crossAxisAlignment.center keeps the circle's
                            /// center on the field's vertical middle.
                            _sectionLabel("Item:"),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                /// The entry box (narrower now)
                                Expanded(
                                  child: Autocomplete<FoodData>(
                                    optionsBuilder: (TextEditingValue
                                        textEditingValue) {
                                      final query = textEditingValue.text
                                          .trim()
                                          .toLowerCase();

                                      final List<FoodData> matches =
                                          query.isEmpty
                                              ? List<FoodData>.from(
                                                  foodDatabase)
                                              : foodDatabase
                                                  .where((food) => food.name
                                                      .toLowerCase()
                                                      .contains(query))
                                                  .toList();

                                      matches.sort((a, b) =>
                                          a.name.compareTo(b.name));
                                      return matches;
                                    },
                                    displayStringForOption:
                                        (FoodData food) => food.name,
                                    onSelected: (FoodData food) {
                                      _fieldController?.text = food.name;
                                      _applyRecommendation(food);
                                      _autocompleteFocusNode?.unfocus();
                                    },
                                    fieldViewBuilder: (context, controller,
                                        focusNode, onEditingComplete) {
                                      _autocompleteFocusNode = focusNode;
                                      _fieldController = controller;

                                      if (!_fieldListenerAttached) {
                                        _fieldListenerAttached = true;
                                        controller.addListener(() {
                                          nameController.text =
                                              controller.text;
                                          if (_nameWarning &&
                                              nameController.text
                                                  .trim()
                                                  .isNotEmpty) {
                                            _nameWarning = false;
                                          }
                                          if (mounted) setState(() {});
                                        });
                                      }

                                      return SizedBox(
                                        height: 56,
                                        child: TextField(
                                          controller: controller,
                                          focusNode: focusNode,
                                          expands: true,
                                          maxLines: null,
                                          minLines: null,
                                          textAlignVertical:
                                              TextAlignVertical.center,
                                          onEditingComplete: onEditingComplete,
                                          decoration: InputDecoration(
                                            hintText: "What did you buy?",
                                            border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              borderSide: BorderSide(
                                                color: _nameWarning
                                                    ? AppColors.myblue
                                                    : Colors.black45,
                                                width: _nameWarning ? 2 : 1,
                                              ),
                                            ),
                                            contentPadding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 16,
                                              vertical: 12,
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                    optionsViewBuilder:
                                        (context, onSelected, options) {
                                      final double overlayWidth =
                                          (MediaQuery.of(context).size.width -
                                                  74)
                                              .clamp(240.0, 558.0)
                                              .toDouble();

                                      return Align(
                                        alignment: Alignment.topLeft,
                                        child: Material(
                                          elevation: 4,
                                          child: SizedBox(
                                            width: overlayWidth,
                                            child: ListView.builder(
                                              shrinkWrap: true,
                                              itemCount: options.length,
                                              itemBuilder:
                                                  (context, index) {
                                                final food = options
                                                    .elementAt(index);
                                                return ListTile(
                                                  leading: Icon(food.icon),
                                                  title: Text(food.name),
                                                  onTap: () =>
                                                      onSelected(food),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),

                                /// The logo circle on the field's right
                                const SizedBox(width: 12),
                                _buildPreviewAvatar(),
                              ],
                            ),

                            if (_nameWarning)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _warningText(
                                    "Please fill in the item name"),
                              ),

                            const SizedBox(height: 12),

                            /// Quantity + Unit
                            _sectionLabel("Quantity:"),
                            const SizedBox(height: 6),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                /// Quantity field — same 56px height
                                Expanded(
                                  flex: 2,
                                  child: SizedBox(
                                    height: 56,
                                    child: TextField(
                                      controller: quantityController,
                                      keyboardType: TextInputType.number,
                                      expands: true,
                                      maxLines: null,
                                      minLines: null,
                                      textAlignVertical:
                                          TextAlignVertical.center,
                                      onChanged: (_) {
                                        if (_quantityWarning) {
                                          setState(() {
                                            _quantityWarning = false;
                                          });
                                        }
                                      },
                                      decoration: InputDecoration(
                                        hintText: "How much?",
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: _quantityWarning
                                                ? AppColors.myblue
                                                : Colors.blueGrey,
                                            width:
                                                _quantityWarning ? 2 : 1,
                                          ),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: BorderSide(
                                            color: _quantityWarning
                                                ? AppColors.myblue
                                                : Colors.blueGrey,
                                            width:
                                                _quantityWarning ? 2 : 1,
                                          ),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(8),
                                          borderSide: const BorderSide(
                                            color: Colors.black,
                                            width: 2,
                                          ),
                                        ),
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 16,
                                          vertical: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),

                                /// Unit dropdown — wider, with full labels
                                Expanded(
                                  flex: 3,
                                  child: Container(
                                    height: 56,
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                        color: _quantityWarning
                                            ? AppColors.myblue
                                            : Colors.blueGrey,
                                        width: _quantityWarning ? 2 : 1,
                                      ),
                                      borderRadius:
                                          BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedUnit,
                                        isExpanded: true,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          color: Colors.black,
                                        ),
                                        items: units.map((u) {
                                          return DropdownMenuItem(
                                            value: u,
                                            child: Text(
                                              unitDisplayLabels[u] ?? u,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                color: Colors.black,
                                              ),
                                            ),
                                          );
                                        }).toList(),
                                        onChanged: (String? newValue) {
                                          setState(() {
                                            selectedUnit = newValue!;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            if (_quantityWarning)
                              Align(
                                alignment: Alignment.centerLeft,
                                child:
                                    _warningText(_quantityWarningMessage),
                              ),

                            const SizedBox(height: 12),

                            /// Expiration Date — label + badge,
                            /// left-leaning
                            _sectionLabel(
                              "Expiration Date:",
                              trailing: recommendedDays != null
                                  ? _buildRecommendationBadge()
                                  : null,
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              height: 56,
                              child: TextField(
                                controller: expirationController,
                                readOnly: true,
                                expands: true,
                                maxLines: null,
                                minLines: null,
                                textAlignVertical: TextAlignVertical.center,
                                onTap: _selectDate,
                                decoration: InputDecoration(
                                  hintText: "Good until?",
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _dateWarning
                                          ? AppColors.myblue
                                          : Colors.blueGrey,
                                      width: _dateWarning ? 2 : 1,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: BorderSide(
                                      color: _dateWarning
                                          ? AppColors.myblue
                                          : Colors.blueGrey,
                                      width: _dateWarning ? 2 : 1,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    borderSide: const BorderSide(
                                      color: Colors.black,
                                      width: 2,
                                    ),
                                  ),
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  suffixIcon: const Icon(
                                    Icons.calendar_today,
                                  ),
                                ),
                              ),
                            ),

                            if (_dateWarning)
                              Align(
                                alignment: Alignment.centerLeft,
                                child: _warningText(
                                    "Please choose an expiration date"),
                              ),

                            const SizedBox(height: 12),

                            /// Quick Add chips
                            _sectionLabel("Quick Add:"),
                            const SizedBox(height: 6),
                            _buildQuickDayChips(),

                            const SizedBox(height: 16),

                            /// Add Item Button (Green)
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () {
                                  _addItem();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.mygreen,
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: const BorderSide(
                                        color: Colors.blueGrey, width: 1),
                                  ),
                                ),
                                child: const Text(
                                  "Add Item to My List",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),

                            /// Buffer below the green button so it
                            /// doesn't sit flush against the card's bottom (accidential touch protection)
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    if (shoppingItems.isNotEmpty)
                      ...shoppingItems.map((item) {
                        final isExpanded = expandedTempItem == item;

                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              expandedTempItem =
                                  isExpanded ? null : item;
                            });
                          },
                          child: AnimatedSize(
                            duration: const Duration(milliseconds: 250),
                            curve: Curves.easeInOut,
                            alignment: Alignment.topCenter,
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isExpanded
                                    ? const Color(0xFFEFEFEF)
                                    : Colors.white,
                                border: Border.all(
                                  color: Colors.black,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(40),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 6,
                                    offset: Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      buildItemAvatar(item),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          children: [
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child: RichText(
                                                text: TextSpan(
                                                  style: const TextStyle(
                                                    color: Colors.black,
                                                    fontSize: 24,
                                                  ),
                                                  children: [
                                                    TextSpan(
                                                      text:
                                                          '${item.quantity} ',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: '${item.unit} ',
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    const TextSpan(
                                                      text: 'of ',
                                                      style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.normal,
                                                      ),
                                                    ),
                                                    TextSpan(
                                                      text: item.name,
                                                      style: const TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Container(
                                              width: double.infinity,
                                              padding:
                                                  const EdgeInsets.all(10),
                                              decoration: BoxDecoration(
                                                border: Border.all(),
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                              child:
                                                  buildDaysRemainingText(item),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),

                                  if (isExpanded) ...[
                                    const SizedBox(height: 12),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _showEditDialog(item),
                                            style: editButtonStyle(),
                                            child: const Text(
                                              "Edit",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.black,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: ElevatedButton(
                                            onPressed: () =>
                                                _confirmDelete(item),
                                            style: deleteButtonStyle(),
                                            child: const Text(
                                              "Delete",
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ],
                              ),
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),

            
            /// FINISH SHOPPING BUTTON (Black, at bottom)
            /// Raised ~20px off the screen bottom
            
            ResponsiveWidth(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 36),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _finishShopping,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Add Items to My Fridge!",
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}