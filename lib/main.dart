import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('gastosBox');
  await Hive.openBox('settingsBox');
  runApp(GastosKoApp());
}

class GastosKoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Gastos Ko',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Color(0xFF121212),
        primaryColor: Color(0xFF22C55E),
        cardColor: Color(0xFF1E1E1E),
      ),
      home: DashboardPage(),
    );
  }
}

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late Box box;
  late Box settingsBox;
  List<Map> transaksyon = [];
  double budgetLimit = 12000;

  @override
  void initState() {
    super.initState();
    box = Hive.box('gastosBox');
    settingsBox = Hive.box('settingsBox');
    budgetLimit = (settingsBox.get('budgetLimit', defaultValue: 12000.0) as num)
        .toDouble();
    var data = box.get('list', defaultValue: []);
    transaksyon = List<Map>.from(data);
  }

  void loadData() {
    var data = box.get('list', defaultValue: []);
    setState(() {
      transaksyon = List<Map>.from(data);
    });
  }

  double get totalKita => transaksyon
      .where((t) => t['tipo'] == 'kita')
      .fold(0.0, (s, t) => s + (t['halaga'] as num).toDouble());
  double get totalGastos => transaksyon
      .where((t) => t['tipo'] == 'gastos')
      .fold(0.0, (s, t) => s + (t['halaga'] as num).toDouble());
  double get balance => totalKita - totalGastos;
  double get percentGastos =>
      budgetLimit == 0 ? 0 : (totalGastos / budgetLimit) * 100;
  String formatPeso(double v) =>
      NumberFormat.currency(locale: 'en_PH', symbol: '₱').format(v);

  void showAddDialog() {
    TextEditingController nameCtrl = TextEditingController();
    TextEditingController amountCtrl = TextEditingController();
    String tipo = 'gastos';
    showDialog(
        context: context,
        builder: (ctx) {
          return StatefulBuilder(builder: (ctx, setDialog) {
            return AlertDialog(
              backgroundColor: Color(0xFF1E1E1E),
              title: Text('Magdagdag',
                  style: TextStyle(color: Colors.white, fontSize: 16)),
              content: Column(mainAxisSize: MainAxisSize.min, children: [
                TextField(
                    controller: nameCtrl,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: 'Saan? Ex: Kape',
                        labelStyle: TextStyle(color: Colors.grey))),
                TextField(
                    controller: amountCtrl,
                    keyboardType: TextInputType.number,
                    style: TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                        labelText: 'Magkano? Ex: 150',
                        labelStyle: TextStyle(color: Colors.grey))),
                SizedBox(height: 16),
                Row(children: [
                  ChoiceChip(
                      label: Text('Gastos'),
                      selected: tipo == 'gastos',
                      onSelected: (v) {
                        setDialog(() {
                          tipo = 'gastos';
                        });
                      }),
                  SizedBox(width: 8),
                  ChoiceChip(
                      label: Text('Kita'),
                      selected: tipo == 'kita',
                      selectedColor: Colors.green,
                      onSelected: (v) {
                        setDialog(() {
                          tipo = 'kita';
                        });
                      }),
                ]),
              ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child:
                        Text('KANSELA', style: TextStyle(color: Colors.grey))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF22C55E)),
                    onPressed: () {
                      if (nameCtrl.text.isEmpty || amountCtrl.text.isEmpty)
                        return;
                      double halaga = double.tryParse(amountCtrl.text) ?? 0;
                      var newItem = {
                        'pangalan': nameCtrl.text,
                        'halaga': halaga,
                        'tipo': tipo,
                        'petsa': DateTime.now().toIso8601String()
                      };
                      var list = box.get('list', defaultValue: []);
                      list.add(newItem);
                      box.put('list', list);
                      loadData();
                      Navigator.pop(context);
                    },
                    child:
                        Text('IDAGDAG', style: TextStyle(color: Colors.black)))
              ],
            );
          });
        });
  }

  void setBudget() {
    TextEditingController ctrl =
        TextEditingController(text: budgetLimit.toStringAsFixed(0));
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
              backgroundColor: Color(0xFF1E1E1E),
              title:
                  Text('Budget Limit', style: TextStyle(color: Colors.white)),
              content: TextField(
                  controller: ctrl,
                  keyboardType: TextInputType.number,
                  style: TextStyle(color: Colors.white, fontSize: 20),
                  decoration: InputDecoration(prefixText: '₱ ')),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Kansela')),
                ElevatedButton(
                    onPressed: () {
                      double? v = double.tryParse(ctrl.text);
                      if (v != null && v > 0) {
                        settingsBox.put('budgetLimit', v);
                        setState(() => budgetLimit = v);
                      }
                      Navigator.pop(context);
                    },
                    child: Text('I-SAVE'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF22C55E)))
              ],
            ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title:
              Text('GASTOS KO', style: TextStyle(fontWeight: FontWeight.bold)),
          actions: [
            IconButton(icon: Icon(Icons.flag_outlined), onPressed: setBudget)
          ]),
      body: ListView(padding: EdgeInsets.all(16), children: [
        Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: Color(0xFF1A1A1A),
                border: Border.all(color: Colors.green)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Balance',
                  style: TextStyle(color: Colors.grey, fontSize: 13)),
              Text(formatPeso(balance),
                  style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                      color: Colors.white)),
              Text(
                  'Kita: ${formatPeso(totalKita)} | Gastos: ${formatPeso(totalGastos)}',
                  style: TextStyle(color: Color(0xFF22C55E), fontSize: 12)),
            ])),
        SizedBox(height: 16),
        ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
                value: (percentGastos / 100).clamp(0, 1),
                minHeight: 8,
                backgroundColor: Colors.white10,
                valueColor: AlwaysStoppedAnimation(percentGastos >= 100
                    ? Colors.red
                    : percentGastos >= 80
                        ? Colors.orange
                        : Color(0xFF22C55E)))),
        SizedBox(height: 8),
        Text(
            '${percentGastos.toStringAsFixed(0)}% nagamit sa ${formatPeso(budgetLimit)}',
            style: TextStyle(color: Colors.grey, fontSize: 11)),
        if (percentGastos >= 70)
          Container(
              margin: EdgeInsets.only(top: 12),
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(
                  percentGastos >= 100
                      ? 'SAGAD NA SA BUDGET!'
                      : 'BABALA: ${percentGastos.toStringAsFixed(0)}% na ng budget mo!',
                  style: TextStyle(color: Colors.white))),
        SizedBox(height: 22),
        Text('Mga Transaksyon', style: TextStyle(fontWeight: FontWeight.bold)),
        ...transaksyon.reversed.map((t) {
          bool isGastos = t['tipo'] == 'gastos';
          return Container(
              margin: EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                  color: Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                  title: Text(t['pangalan'],
                      style: TextStyle(color: Colors.white, fontSize: 14)),
                  trailing: Text(
                      '${isGastos ? '-' : '+'} ${formatPeso((t['halaga'] as num).toDouble())}',
                      style: TextStyle(
                          color: isGastos ? Colors.white : Color(0xFF22C55E),
                          fontWeight: FontWeight.bold))));
        }).toList(),
        if (transaksyon.isEmpty)
          Padding(
              padding: EdgeInsets.all(30),
              child: Text('Wala pang transaksyon.\nPindutin + DAGDAG',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center)),
        SizedBox(height: 80),
      ]),
      floatingActionButton: FloatingActionButton.extended(
          onPressed: showAddDialog,
          backgroundColor: Color(0xFF22C55E),
          icon: Icon(Icons.add, color: Colors.black),
          label: Text('DAGDAG',
              style:
                  TextStyle(color: Colors.black, fontWeight: FontWeight.bold))),
    );
  }
}
