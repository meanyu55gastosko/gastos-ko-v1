import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

void main() => runApp(const GastosApp());

class GastosApp extends StatelessWidget {
  const GastosApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const HomePage());
  }
}

class GastosItem {
  String title;
  double amount;
  DateTime date;
  GastosItem({required this.title, required this.amount, required this.date});
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<GastosItem> allItems = [
    GastosItem(title: 'Padala kay Nanay', amount: 10000, date: DateTime.now()),
    GastosItem(
        title: 'Internet',
        amount: 1000,
        date: DateTime.now().subtract(Duration(days: 1))),
    GastosItem(
        title: 'Kuryente',
        amount: 5000,
        date: DateTime.now().subtract(Duration(days: 2))),
    GastosItem(
        title: 'Tubig',
        amount: 5000,
        date: DateTime.now().subtract(Duration(days: 5))),
    GastosItem(
        title: 'Kape',
        amount: 1000,
        date: DateTime.now().subtract(Duration(days: 10))),
    GastosItem(
        title: 'Jollibee',
        amount: 1000,
        date: DateTime.now().subtract(Duration(days: 20))),
  ];

  String selectedFilter = 'Lahat';
  DateTimeRange? customRange;

  final List<Color> myColors = [
    Colors.red,
    Colors.green,
    Colors.blue,
    Colors.orange,
    Colors.purple,
    Colors.yellow,
    Colors.cyan,
    Colors.pink,
    Colors.teal,
    Colors.lime
  ];

  List<GastosItem> get filteredItems {
    DateTime now = DateTime.now();
    DateTime start;
    DateTime end = DateTime(now.year, now.month, now.day, 23, 59, 59);

    if (selectedFilter == 'Ngayon') {
      start = DateTime(now.year, now.month, now.day);
    } else if (selectedFilter == 'Linggong Ito') {
      start = now.subtract(Duration(days: 7));
    } else if (selectedFilter == 'Buwang Ito') {
      start = DateTime(now.year, now.month, 1);
    } else if (selectedFilter == 'Custom' && customRange != null) {
      start = customRange!.start;
      end = DateTime(customRange!.end.year, customRange!.end.month,
          customRange!.end.day, 23, 59, 59);
    } else {
      return allItems; // Lahat
    }
    return allItems
        .where((it) =>
            it.date.isAfter(start.subtract(Duration(seconds: 1))) &&
            it.date.isBefore(end.add(Duration(seconds: 1))))
        .toList();
  }

  double get total => filteredItems.fold(0, (s, e) => s + e.amount);

  Map<String, double> get grouped {
    Map<String, double> m = {};
    for (var it in filteredItems) {
      m[it.title] = (m[it.title] ?? 0) + it.amount;
    }
    return m;
  }

  void addItem(String title, double amount, DateTime date) {
    setState(() => allItems.insert(
        0, GastosItem(title: title, amount: amount, date: date)));
  }

  void editItem(
      int originalIndex, String newTitle, double newAmount, DateTime newDate) {
    setState(() {
      allItems[originalIndex].title = newTitle;
      allItems[originalIndex].amount = newAmount;
      allItems[originalIndex].date = newDate;
    });
  }

  void deleteItem(int originalIndex) {
    setState(() => allItems.removeAt(originalIndex));
  }

  void showAddDialog() {
    final tCtrl = TextEditingController();
    final aCtrl = TextEditingController();
    DateTime chosenDate = DateTime.now();
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setD) {
          return AlertDialog(
            title: const Text('Dagdag Gastos'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: tCtrl,
                  decoration:
                      const InputDecoration(labelText: 'Ano? Ex: Jollibee')),
              TextField(
                  controller: aCtrl,
                  decoration: const InputDecoration(labelText: 'Magkano?'),
                  keyboardType: TextInputType.number),
              SizedBox(height: 10),
              Row(children: [
                Text(DateFormat('MMM dd, yyyy').format(chosenDate),
                    style: TextStyle(color: Colors.white70)),
                Spacer(),
                TextButton(
                    onPressed: () async {
                      DateTime? d = await showDatePicker(
                          context: context,
                          initialDate: chosenDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030));
                      if (d != null) setD(() => chosenDate = d);
                    },
                    child: Text('Piliin ang Petsa')),
              ]),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text('Ikansela')),
              ElevatedButton(
                  onPressed: () {
                    if (tCtrl.text.isNotEmpty && aCtrl.text.isNotEmpty) {
                      addItem(tCtrl.text, double.tryParse(aCtrl.text) ?? 0,
                          chosenDate);
                      Navigator.pop(ctx);
                    }
                  },
                  child: Text('I-Save')),
            ],
          );
        });
      },
    );
  }

  void showEditDialog(GastosItem item) {
    int originalIndex = allItems.indexOf(item);
    final tCtrl = TextEditingController(text: item.title);
    final aCtrl = TextEditingController(text: item.amount.toString());
    DateTime chosenDate = item.date;
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx, setD) {
          return AlertDialog(
            title: Text('Edit ${item.title}'),
            content: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                  controller: tCtrl,
                  decoration: InputDecoration(labelText: 'Pangalan')),
              TextField(
                  controller: aCtrl,
                  decoration: InputDecoration(labelText: 'Magkano'),
                  keyboardType: TextInputType.number),
              SizedBox(height: 10),
              Row(children: [
                Text(DateFormat('MMM dd, yyyy').format(chosenDate)),
                Spacer(),
                TextButton(
                    onPressed: () async {
                      DateTime? d = await showDatePicker(
                          context: context,
                          initialDate: chosenDate,
                          firstDate: DateTime(2020),
                          lastDate: DateTime(2030));
                      if (d != null) setD(() => chosenDate = d);
                    },
                    child: Text('Petsa')),
              ]),
            ]),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: Text('Cancel')),
              ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    editItem(originalIndex, tCtrl.text,
                        double.tryParse(aCtrl.text) ?? item.amount, chosenDate);
                    Navigator.pop(ctx);
                  },
                  child: Text('Update')),
            ],
          );
        });
      },
    );
  }

  Future<void> pickCustomRange() async {
    DateTimeRange? r = await showDateRangePicker(
        context: context,
        firstDate: DateTime(2020),
        lastDate: DateTime(2030),
        initialDateRange: customRange);
    if (r != null) {
      setState(() {
        customRange = r;
        selectedFilter = 'Custom';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    var entryList = grouped.entries.toList();
    double totalG = total == 0 ? 1 : total;
    final fmt = NumberFormat('#,##0.00', 'en_PH');

    return Scaffold(
      appBar: AppBar(
          title: const Text('GASTOS KO PRO v4'), backgroundColor: Colors.black),
      backgroundColor: const Color(0xFF121212),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // DATE RANGE SELECTOR
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (var f in ['Lahat', 'Ngayon', 'Linggong Ito', 'Buwang Ito'])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f),
                      selected: selectedFilter == f,
                      onSelected: (v) => setState(() => selectedFilter = f),
                      selectedColor: Colors.greenAccent,
                      labelStyle: TextStyle(
                          color: selectedFilter == f
                              ? Colors.black
                              : Colors.white70),
                    ),
                  ),
                ActionChip(
                    label: Text(customRange == null
                        ? 'Custom Range'
                        : '${DateFormat('MMM dd').format(customRange!.start)} - ${DateFormat('MMM dd').format(customRange!.end)}'),
                    onPressed: pickCustomRange,
                    backgroundColor: selectedFilter == 'Custom'
                        ? Colors.orange
                        : Color(0xFF1E1E1E)),
              ],
            ),
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.greenAccent.withOpacity(0.5))),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('TOTAL GASTOS - $selectedFilter',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              Text('₱${fmt.format(total)}',
                  style: const TextStyle(
                      fontSize: 32, fontWeight: FontWeight.bold)),
              Text('${filteredItems.length} transactions',
                  style: TextStyle(color: Colors.white38, fontSize: 11)),
            ]),
          ),
          SizedBox(height: 20),
          Text('Saan Napunta? (${selectedFilter})',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 10),
          if (filteredItems.isEmpty)
            Center(
                child: Padding(
                    padding: EdgeInsets.all(20),
                    child: Text('Walang gastos sa range na to boss!',
                        style: TextStyle(color: Colors.white54)))),
          if (filteredItems.isNotEmpty)
            SizedBox(
              height: 220,
              child: PieChart(PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(entryList.length, (i) {
                  double percent = entryList[i].value / totalG * 100;
                  return PieChartSectionData(
                      value: entryList[i].value,
                      title:
                          percent < 3 ? '' : '${percent.toStringAsFixed(0)}%',
                      color: myColors[i % myColors.length],
                      radius: 70,
                      titleStyle: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.white));
                }),
              )),
            ),
          SizedBox(height: 16),
          Column(
            children: List.generate(entryList.length, (i) {
              Color c = myColors[i % myColors.length];
              double percent = entryList[i].value / totalG * 100;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Container(
                      width: 14,
                      height: 14,
                      decoration:
                          BoxDecoration(color: c, shape: BoxShape.circle)),
                  SizedBox(width: 10),
                  Expanded(
                      child: Text(entryList[i].key,
                          style: TextStyle(color: Colors.white70))),
                  Text(
                      '${percent.toStringAsFixed(0)}% • ₱${fmt.format(entryList[i].value)}',
                      style:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ]),
              );
            }),
          ),
          Divider(height: 30),
          Text('Mga Transaksyon sa $selectedFilter - Pindutin para magpalit',
              style: TextStyle(fontSize: 11, color: Colors.white38)),
          SizedBox(height: 10),
          ...List.generate(filteredItems.length, (i) {
            var it = filteredItems[i];
            int colorIdx = entryList.indexWhere((e) => e.key == it.title);
            Color dot = colorIdx >= 0
                ? myColors[colorIdx % myColors.length]
                : Colors.grey;
            return GestureDetector(
              onTap: () => showEditDialog(it),
              onLongPress: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                          title: Text('Burahin?'),
                          content: Text('Burahin ${it.title}?'),
                          actions: [
                            TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text('Hindi')),
                            TextButton(
                                onPressed: () {
                                  deleteItem(allItems.indexOf(it));
                                  Navigator.pop(ctx);
                                },
                                child: Text('Oo',
                                    style: TextStyle(color: Colors.red)))
                          ])),
              child: Container(
                margin: EdgeInsets.only(bottom: 8),
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(children: [
                  Container(
                      width: 8,
                      height: 40,
                      decoration: BoxDecoration(
                          color: dot, borderRadius: BorderRadius.circular(4))),
                  SizedBox(width: 10),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                        Text(it.title,
                            style: TextStyle(fontWeight: FontWeight.bold)),
                        Text(DateFormat('MMM dd, yyyy').format(it.date),
                            style:
                                TextStyle(fontSize: 11, color: Colors.white54))
                      ])),
                  Text('₱${fmt.format(it.amount)}',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ]),
              ),
            );
          }),
          SizedBox(height: 80),
        ]),
      ),
      floatingActionButton: FloatingActionButton.extended(
          backgroundColor: Colors.greenAccent,
          onPressed: showAddDialog,
          icon: Icon(Icons.add, color: Colors.black),
          label: Text('DAGDAG',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
    );
  }
}
