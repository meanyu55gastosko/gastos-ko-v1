import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

void main() => runApp(const GastosKoApp());

class GastosKoApp extends StatelessWidget {
  const GastosKoApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark()
            .copyWith(scaffoldBackgroundColor: const Color(0xFF121212)),
        home: const SplashScreen());
  }
}

class CommaFormatter extends TextInputFormatter {
  final NumberFormat _fmt = NumberFormat('#,##0');
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    String clean = newValue.text
        .replaceAll(',', '')
        .replaceAll('₱', '')
        .replaceAll(' ', '')
        .trim()
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return const TextEditingValue(text: '');
    int val = int.tryParse(clean) ?? 0;
    String formatted = _fmt.format(val);
    return TextEditingValue(
        text: formatted,
        selection: TextSelection.collapsed(offset: formatted.length));
  }
}

// SPLASH - CUSTOM ASSETS LOGO - PLAIN GOLD ASTIG!
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _glow;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 25, end: 60)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (!mounted) return;
      Navigator.pushReplacement(
          context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      body: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) =>
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Transform.scale(
              scale: _scale.value,
              child: Container(
                width: 130,
                height: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  // PLAIN GOLD GLOW LANG - WALANG DARK BORDER!
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                        blurRadius: _glow.value,
                        spreadRadius: 5)
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/icon.png',
                    width: 130, height: 130,
                    fit: BoxFit.cover,
                    // Kung di pa gold yung asset, gagawing gold pa rin - pero pag gold na asset mo, plain lang!
                    errorBuilder: (c, e, s) => Container(
                      decoration: const BoxDecoration(
                          color: Color(0xFFFFD700), shape: BoxShape.circle),
                      child: const Icon(Icons.account_balance_wallet,
                          size: 70, color: Color(0xFF121212)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
            const Text('BUDGET vs GASTOS',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2)),
            const SizedBox(height: 10),
            const Text('Loading...',
                style: TextStyle(color: Colors.white38, fontSize: 12)),
          ]),
        ),
      ),
    );
  }
}

class Expense {
  String id;
  String title;
  double amount;
  DateTime date;
  Color color;
  Expense(
      {required this.id,
      required this.title,
      required this.amount,
      required this.date,
      required this.color});
}

class GroupedExpense {
  String title;
  double total;
  Color color;
  int count;
  GroupedExpense(
      {required this.title,
      required this.total,
      required this.color,
      required this.count});
}

class PiePainter extends CustomPainter {
  final List<GroupedExpense> data;
  final double total;
  final int? selectedIndex;
  PiePainter({required this.data, required this.total, this.selectedIndex});
  @override
  void paint(Canvas canvas, Size size) {
    double startAngle = -math.pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width, size.height) / 2;
    for (int i = 0; i < data.length; i++) {
      var g = data[i];
      double sweep = (g.total / total) * 2 * math.pi;
      bool isSelected = i == selectedIndex;
      double extraRadius = isSelected ? 12 : 0;
      Offset offset = Offset.zero;
      if (isSelected) {
        double midAngle = startAngle + sweep / 2;
        offset = Offset(math.cos(midAngle) * 12, math.sin(midAngle) * 12);
      }
      final paint = Paint()
        ..color = isSelected ? g.color : g.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      if (isSelected) {
        final glowPaint = Paint()
          ..color = g.color.withValues(alpha: 0.5)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 8
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
        canvas.drawArc(
            Rect.fromCircle(
                center: center + offset, radius: radius + extraRadius),
            startAngle,
            sweep,
            true,
            glowPaint);
      }
      canvas.drawArc(
          Rect.fromCircle(
              center: center + offset, radius: radius + extraRadius),
          startAngle,
          sweep,
          true,
          paint);
      startAngle += sweep;
    }
    final holePaint = Paint()
      ..color = const Color(0xFF1E1E1E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.55, holePaint);
  }

  @override
  bool shouldRepaint(covariant PiePainter oldDelegate) =>
      oldDelegate.selectedIndex != selectedIndex || oldDelegate.data != data;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  double budget = 50000;
  List<Expense> all = [];
  DateTime sDate = DateTime(2026, 9, 13);
  DateTime eDate = DateTime(2026, 10, 13);
  Map<String, Color> colorMap = {};
  int? selectedIndex;
  final NumberFormat commaFormat = NumberFormat('#,##0');
  String fmt(num n) => commaFormat.format(n.toInt());
  String peso(num n) => '₱${fmt(n)}';
  Color _genUniqueColor(int index) {
    double hue = (index * 137.508) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.85, 0.95).toColor();
  }

  Color getColorForTitle(String title, {String? excludeId}) {
    String key = title.toLowerCase().trim();
    for (var e in all) {
      if (excludeId != null && e.id == excludeId) continue;
      if (e.title.toLowerCase().trim() == key) {
        colorMap[key] = e.color;
        return e.color;
      }
    }
    if (colorMap.containsKey(key)) return colorMap[key]!;
    Color c = _genUniqueColor(colorMap.length);
    colorMap[key] = c;
    return c;
  }

  List<Expense> get filtered => all.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        final s = DateTime(sDate.year, sDate.month, sDate.day);
        final en = DateTime(eDate.year, eDate.month, eDate.day);
        return !d.isBefore(s) && !d.isAfter(en);
      }).toList();
  List<GroupedExpense> get grouped {
    Map<String, GroupedExpense> map = {};
    for (var e in filtered) {
      String key = e.title.toLowerCase().trim();
      if (map.containsKey(key)) {
        map[key]!.total += e.amount;
        map[key]!.count += 1;
      } else {
        map[key] = GroupedExpense(
            title: e.title, total: e.amount, color: e.color, count: 1);
      }
    }
    var list = map.values.toList();
    list.sort((a, b) => b.total.compareTo(a.total));
    return list;
  }

  double get totAll => all.fold(0, (a, b) => a + b.amount);
  double get rem => budget - totAll;

  void checkOverBudget() {
    if (rem < 0) {
      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
                backgroundColor: const Color(0xFF2A0000),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                title: const Text('OVERBUDGET KA NA BOSS!',
                    style: TextStyle(
                        color: Colors.red,
                        fontSize: 16,
                        fontWeight: FontWeight.bold)),
                content: Text(
                    'Budget: ${peso(budget)}\nGastos: ${peso(totAll)}\n\nNegative: ${peso(rem)}',
                    style: const TextStyle(color: Colors.white, fontSize: 14)),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('HINDI MUNA',
                          style: TextStyle(color: Colors.white54))),
                  ElevatedButton(
                      style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD700)),
                      onPressed: () {
                        Navigator.pop(context);
                        addBudgetDialog(isAddMode: true);
                      },
                      child: const Text('DAGDAG BUDGET',
                          style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold)))
                ],
              ));
    }
  }

  void addBudgetDialog({bool isAddMode = false}) {
    final c = TextEditingController(text: isAddMode ? '' : fmt(budget));
    showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              title: Text(isAddMode ? 'DAGDAG BUDGET' : 'Edit Budget Limit',
                  style: const TextStyle(
                      color: Color(0xFFFFD700), fontWeight: FontWeight.bold)),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (isAddMode)
                      Text('Current: ${peso(budget)}\nKulang: ${peso(rem)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    if (!isAddMode)
                      Text('Current: ${peso(budget)}',
                          style: const TextStyle(
                              color: Colors.white54, fontSize: 12)),
                    const SizedBox(height: 12),
                    TextField(
                        controller: c,
                        keyboardType: TextInputType.number,
                        autofocus: true,
                        inputFormatters: [CommaFormatter()],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                            labelText: isAddMode
                                ? 'Magkano idadagdag?'
                                : 'Bagong limit',
                            labelStyle: const TextStyle(color: Colors.white54),
                            prefixText: '₱',
                            prefixStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                            hintText: isAddMode ? 'Ex: 10,000' : 'Ex: 50,000',
                            enabledBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(color: Colors.white24)),
                            focusedBorder: const UnderlineInputBorder(
                                borderSide: BorderSide(
                                    color: Color(0xFFFFD700), width: 2))))
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel',
                        style: TextStyle(color: Colors.white54))),
                ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700)),
                    onPressed: () {
                      double val =
                          double.tryParse(c.text.replaceAll(',', '').trim()) ??
                              0;
                      if (val <= 0) return;
                      setState(() {
                        if (isAddMode) {
                          budget += val;
                        } else {
                          budget = val;
                        }
                      });
                      Navigator.pop(context);
                    },
                    child: Text(isAddMode ? 'DAGDAG NA!' : 'SAVE',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold)))
              ],
            ));
  }

  void addEdit({Expense? ex}) {
    final tCtrl = TextEditingController(text: ex?.title ?? '');
    final aCtrl = TextEditingController(text: ex == null ? '' : fmt(ex.amount));
    DateTime dSel = ex?.date ?? DateTime.now();
    showDialog(
        context: context,
        builder: (ctx) => StatefulBuilder(
            builder: (ctx, setM) => AlertDialog(
                  backgroundColor: const Color(0xFF1E1E1E),
                  title: Text(ex == null ? 'Add Gastos' : 'Edit Gastos',
                      style: const TextStyle(color: Colors.white)),
                  content: Column(mainAxisSize: MainAxisSize.min, children: [
                    TextField(
                        controller: tCtrl,
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(labelText: 'Item')),
                    const SizedBox(height: 8),
                    TextField(
                        controller: aCtrl,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold),
                        keyboardType: TextInputType.number,
                        inputFormatters: [CommaFormatter()],
                        decoration: const InputDecoration(
                            labelText: 'Magkano?',
                            prefixText: '₱',
                            hintText: '10,000',
                            hintStyle: TextStyle(color: Colors.white24))),
                    const SizedBox(height: 10),
                    Text(DateFormat('MMM dd, yyyy').format(dSel),
                        style: const TextStyle(
                            color: Colors.white54, fontSize: 12)),
                    TextButton(
                        onPressed: () async {
                          final d = await showDatePicker(
                              context: context,
                              firstDate: DateTime(2023),
                              lastDate: DateTime(2030),
                              initialDate: dSel);
                          if (d != null) setM(() => dSel = d);
                        },
                        child: const Text('Pili Date',
                            style: TextStyle(color: Color(0xFFFFD700))))
                  ]),
                  actions: [
                    TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel')),
                    ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFD700)),
                        onPressed: () {
                          final amt = double.tryParse(
                                  aCtrl.text.replaceAll(',', '').trim()) ??
                              0;
                          final t = tCtrl.text.trim();
                          if (t.isEmpty || amt <= 0) return;
                          setState(() {
                            Color col = getColorForTitle(t, excludeId: ex?.id);
                            if (ex == null) {
                              all.add(Expense(
                                  id: DateTime.now()
                                      .millisecondsSinceEpoch
                                      .toString(),
                                  title: t,
                                  amount: amt,
                                  date: dSel,
                                  color: col));
                            } else {
                              ex.title = t;
                              ex.amount = amt;
                              ex.date = dSel;
                              ex.color = col;
                            }
                            selectedIndex = null;
                          });
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300),
                              () => checkOverBudget());
                        },
                        child: const Text('SAVE',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold)))
                  ],
                )));
  }

  @override
  Widget build(BuildContext context) {
    double totalGrouped = grouped.fold(0, (a, b) => a + b.total);
    return Scaffold(
      appBar: AppBar(
          title: const Text('BUDGET vs GASTOS',
              style: TextStyle(
                  color: Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                  fontSize: 18)),
          centerTitle: true,
          backgroundColor: const Color(0xFF1E1E1E),
          actions: [
            IconButton(
                icon: const Icon(Icons.wallet, color: Color(0xFFFFD700)),
                onPressed: () => addBudgetDialog(isAddMode: false))
          ]),
      floatingActionButton: FloatingActionButton(
          backgroundColor: const Color(0xFFFFD700),
          onPressed: () => addEdit(),
          child: const Icon(Icons.add, color: Colors.black)),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10)),
            child: Row(children: [
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    const Text('Budget',
                        style: TextStyle(color: Colors.white54, fontSize: 10)),
                    Text(peso(budget),
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15))
                  ])),
              Expanded(
                  child: Column(children: [
                const Text('Gastos',
                    style: TextStyle(color: Colors.white54, fontSize: 10)),
                Text(peso(totAll),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15))
              ])),
              Expanded(
                  child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: rem < 0
                              ? Colors.red.withValues(alpha: 0.2)
                              : const Color(0xFFFFD700).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8)),
                      child: Column(children: [
                        const Text('Remaining',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(peso(rem),
                            style: TextStyle(
                                color: rem < 0
                                    ? Colors.red
                                    : const Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 13))
                      ])))
            ])),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFFFFD700).withValues(alpha: 0.3))),
            child: InkWell(
                onTap: () async {
                  final r = await showDateRangePicker(
                      context: context,
                      firstDate: DateTime(2023),
                      lastDate: DateTime(2030),
                      initialDateRange:
                          DateTimeRange(start: sDate, end: eDate));
                  if (r != null) {
                    setState(() {
                      sDate = r.start;
                      eDate = r.end;
                    });
                  }
                },
                child: Row(children: [
                  Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('HISTORY REPORT',
                            style: TextStyle(
                                color: Color(0xFFFFD700),
                                fontWeight: FontWeight.bold,
                                fontSize: 11)),
                        Text(
                            '${DateFormat('MMM dd').format(sDate)} - ${DateFormat('MMM dd, yyyy').format(eDate)}',
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12))
                      ]),
                  const Spacer(),
                  const Icon(Icons.edit_calendar, color: Colors.white54)
                ]))),
        const SizedBox(height: 14),
        if (grouped.isNotEmpty)
          Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(16)),
              child: Column(children: [
                const Text('PIE CHART - ASTIG DONUT',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                Text(
                    selectedIndex == null
                        ? '${grouped.length} items - tap label to highlight!'
                        : 'Selected: ${grouped[selectedIndex!].title} ${peso(grouped[selectedIndex!].total)} - tap again to unselect',
                    style: TextStyle(
                        color: selectedIndex == null
                            ? Colors.white38
                            : const Color(0xFFFFD700),
                        fontSize: 10,
                        fontWeight: selectedIndex == null
                            ? FontWeight.normal
                            : FontWeight.bold)),
                const SizedBox(height: 16),
                GestureDetector(
                    onTap: () => setState(() => selectedIndex = null),
                    child: SizedBox(
                        height: 240,
                        child: Stack(alignment: Alignment.center, children: [
                          CustomPaint(
                              size: const Size(240, 240),
                              painter: PiePainter(
                                  data: grouped,
                                  total: totalGrouped,
                                  selectedIndex: selectedIndex)),
                          Column(mainAxisSize: MainAxisSize.min, children: [
                            const Text('TOTAL',
                                style: TextStyle(
                                    color: Colors.white54, fontSize: 10)),
                            Text(peso(totalGrouped),
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18)),
                            if (selectedIndex != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                  '${((grouped[selectedIndex!].total / totalGrouped) * 100).toStringAsFixed(1)}%',
                                  style: TextStyle(
                                      color: grouped[selectedIndex!].color,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12))
                            ]
                          ])
                        ]))),
                const SizedBox(height: 16),
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(grouped.length, (i) {
                      var g = grouped[i];
                      bool isSel = i == selectedIndex;
                      return InkWell(
                          onTap: () {
                            setState(() {
                              if (selectedIndex == i) {
                                selectedIndex = null;
                              } else {
                                selectedIndex = i;
                              }
                            });
                          },
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: EdgeInsets.symmetric(
                                  horizontal: isSel ? 12 : 8,
                                  vertical: isSel ? 6 : 4),
                              decoration: BoxDecoration(
                                  color: isSel
                                      ? g.color.withValues(alpha: 0.3)
                                      : g.color.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                      color: g.color, width: isSel ? 2.5 : 1),
                                  boxShadow: isSel
                                      ? [
                                          BoxShadow(
                                              color: g.color
                                                  .withValues(alpha: 0.6),
                                              blurRadius: 12,
                                              spreadRadius: 1)
                                        ]
                                      : []),
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                        width: isSel ? 10 : 8,
                                        height: isSel ? 10 : 8,
                                        decoration: BoxDecoration(
                                            color: g.color,
                                            shape: BoxShape.circle)),
                                    const SizedBox(width: 4),
                                    Text('${g.title} ${peso(g.total)}',
                                        style: TextStyle(
                                            color: g.color,
                                            fontSize: isSel ? 12 : 11,
                                            fontWeight: FontWeight.bold))
                                  ])));
                    })),
              ])),
        if (grouped.isEmpty)
          const Center(
              child: Padding(
                  padding: EdgeInsets.all(30),
                  child: Text('Wala pang gastos!',
                      style: TextStyle(color: Colors.white54)))),
        const SizedBox(height: 14),
        const Text('Recent Entries:',
            style: TextStyle(color: Colors.white38, fontSize: 11)),
        const SizedBox(height: 6),
        for (var e in filtered.reversed)
          Container(
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                  color: const Color(0xFF1E1E1E),
                  borderRadius: BorderRadius.circular(10)),
              child: ListTile(
                  leading: Container(
                      width: 6,
                      height: 36,
                      decoration: BoxDecoration(
                          color: e.color,
                          borderRadius: BorderRadius.circular(3))),
                  title: Text(e.title,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                  subtitle: Text(DateFormat('MMM dd, yyyy').format(e.date),
                      style:
                          const TextStyle(color: Colors.white54, fontSize: 11)),
                  trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                    Text(peso(e.amount),
                        style: TextStyle(
                            color: e.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 12)),
                    IconButton(
                        icon: const Icon(Icons.edit,
                            size: 16, color: Colors.white38),
                        onPressed: () => addEdit(ex: e)),
                    IconButton(
                        icon: const Icon(Icons.delete,
                            size: 16, color: Colors.redAccent),
                        onPressed: () => setState(() => all.remove(e)))
                  ]))),
      ]),
    );
  }
}
