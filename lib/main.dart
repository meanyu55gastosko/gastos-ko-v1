import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

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
        .replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.isEmpty) return const TextEditingValue(text: '');
    int val = int.tryParse(clean) ?? 0;
    return TextEditingValue(
        text: _fmt.format(val),
        selection: TextSelection.collapsed(offset: _fmt.format(val).length));
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashState();
}

class _SplashState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale, _glow;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _scale = Tween<double>(begin: 0.9, end: 1.15)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    _glow = Tween<double>(begin: 25, end: 70)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted)
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
          builder: (_, __) =>
              Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Transform.scale(
              scale: _scale.value,
              child: Container(
                decoration: BoxDecoration(boxShadow: [
                  BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.8),
                      blurRadius: _glow.value,
                      spreadRadius: 5),
                  BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.4),
                      blurRadius: _glow.value * 1.8,
                      spreadRadius: 15)
                ]),
                child: Image.asset('assets/icon.png', width: 130, height: 130),
              ),
            ),
            const SizedBox(height: 30),
            const Text('BUDGET vs GASTOS',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontSize: 26,
                    fontWeight: FontWeight.bold)),
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
  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'amount': amount,
        'date': date.toIso8601String(),
        'color': color.toARGB32()
      };
  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
      id: j['id'],
      title: j['title'],
      amount: (j['amount'] as num).toDouble(),
      date: DateTime.parse(j['date']),
      color: Color(j['color']));
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
    double start = -math.pi / 2;
    final center = Offset(size.width / 2, size.height / 2);
    double radius = math.min(size.width, size.height) / 2;
    for (int i = 0; i < data.length; i++) {
      var g = data[i];
      double sweep = (g.total / total) * 2 * math.pi;
      bool sel = i == selectedIndex;
      Offset off = Offset.zero;
      if (sel) {
        double mid = start + sweep / 2;
        off = Offset(math.cos(mid) * 12, math.sin(mid) * 12);
      }
      final paint = Paint()
        ..color = sel ? g.color : g.color.withValues(alpha: 0.85)
        ..style = PaintingStyle.fill;
      canvas.drawArc(
          Rect.fromCircle(
              center: center + off, radius: radius + (sel ? 12 : 0)),
          start,
          sweep,
          true,
          paint);
      start += sweep;
    }
    canvas.drawCircle(
        center, radius * 0.55, Paint()..color = const Color(0xFF1E1E1E));
  }

  @override
  bool shouldRepaint(covariant PiePainter o) =>
      o.selectedIndex != selectedIndex || o.data != data;
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeState();
}

class _HomeState extends State<HomeScreen> {
  double budget = 50000;
  List<Expense> all = [];
  late DateTime sDate, eDate;
  Map<String, Color> colorMap = {};
  int? selectedIndex;
  final NumberFormat commaFormat = NumberFormat('#,##0');
  String fmt(num n) => commaFormat.format(n.toInt());
  String peso(num n) => '₱${fmt(n)}';

  // BOSS ITO YUNG TRIAL SETTINGS - PALITAN MO LANG PAG PRO NA!
  static const bool isTrialVersion = true;
  static const int trialLimit = 10;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    sDate = DateTime(now.year, now.month - 1, 1);
    eDate = DateTime(now.year, now.month + 2, 0);
    _loadData();
  }

  Future<void> _loadData() async {
    final p = await SharedPreferences.getInstance();
    setState(() {
      budget = p.getDouble('budget') ?? 50000;
      String? d = p.getString('expenses');
      if (d != null) {
        List l = jsonDecode(d);
        all = l.map((e) => Expense.fromJson(e)).toList();
        for (var e in all) {
          colorMap[e.title.toLowerCase().trim()] = e.color;
        }
      }
    });
  }

  Future<void> _saveData() async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble('budget', budget);
    await p.setString(
        'expenses', jsonEncode(all.map((e) => e.toJson()).toList()));
  }

  Future<void> _openProVersion() async {
    final Uri url = Uri.parse(
        'https://play.google.com/store/apps/details?id=com.budgetvsgastos.pro');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      await launchUrl(url, mode: LaunchMode.platformDefault);
    }
  }

  void _showTrialLockDialog() {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => AlertDialog(
              backgroundColor: const Color(0xFF1E1E1E),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFFFD700), width: 1.5)),
              title: const Row(children: [
                Icon(Icons.lock, color: Color(0xFFFFD700)),
                SizedBox(width: 8),
                Text('TRIAL LIMIT REACHED!',
                    style: TextStyle(
                        color: Color(0xFFFFD700),
                        fontSize: 16,
                        fontWeight: FontWeight.bold))
              ]),
              content: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Naka $trialLimit gastos ka na boss sa Trial Version!',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 13)),
                    const SizedBox(height: 10),
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            color:
                                const Color(0xFFFFD700).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8)),
                        child: const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('PRO VERSION FEATURES:',
                                  style: TextStyle(
                                      color: Color(0xFFFFD700),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 11)),
                              SizedBox(height: 6),
                              Text(
                                  '✓ Unlimited gastos entries\n✓ Export to Excel/PDF\n✓ No ads\n✓ Cloud backup',
                                  style: TextStyle(
                                      color: Colors.white70, fontSize: 11)),
                            ])),
                    const SizedBox(height: 10),
                    const Text('Mag-upgrade ka na sa PRO para sa unlimited!',
                        style: TextStyle(color: Colors.white54, fontSize: 11)),
                  ]),
              actions: [
                TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Later',
                        style: TextStyle(color: Colors.white54))),
                ElevatedButton.icon(
                    icon: const Icon(Icons.star, size: 16, color: Colors.black),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFD700)),
                    onPressed: () {
                      Navigator.pop(context);
                      _openProVersion();
                    },
                    label: const Text('UPGRADE TO PRO - ₱199',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 12))),
              ],
            ));
  }

  Color _genUniqueColor(int i) {
    double hue = (i * 137.508) % 360;
    return HSVColor.fromAHSV(1.0, hue, 0.85, 0.95).toColor();
  }

  Color getColorForTitle(String t, {String? excludeId}) {
    String k = t.toLowerCase().trim();
    for (var e in all) {
      if (excludeId != null && e.id == excludeId) continue;
      if (e.title.toLowerCase().trim() == k) {
        colorMap[k] = e.color;
        return e.color;
      }
    }
    if (colorMap.containsKey(k)) return colorMap[k]!;
    Color c = _genUniqueColor(colorMap.length);
    colorMap[k] = c;
    return c;
  }

  List<Expense> get filtered => all.where((e) {
        final d = DateTime(e.date.year, e.date.month, e.date.day);
        final s = DateTime(sDate.year, sDate.month, sDate.day);
        final en = DateTime(eDate.year, eDate.month, eDate.day);
        return !d.isBefore(s) && !d.isAfter(en);
      }).toList();
  List<GroupedExpense> get grouped {
    Map<String, GroupedExpense> m = {};
    for (var e in filtered) {
      String k = e.title.toLowerCase().trim();
      if (m.containsKey(k)) {
        m[k]!.total += e.amount;
        m[k]!.count += 1;
      } else {
        m[k] = GroupedExpense(
            title: e.title, total: e.amount, color: e.color, count: 1);
      }
    }
    var l = m.values.toList();
    l.sort((a, b) => b.total.compareTo(a.total));
    return l;
  }

  double get totAll => filtered.fold(0, (a, b) => a + b.amount);
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
                    'Budget: ${peso(budget)}\nGastos: ${peso(totAll)}\nKulang: ${peso(rem)}',
                    style: const TextStyle(color: Colors.white)),
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
                              fontWeight: FontWeight.bold))),
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
              title: Text(isAddMode ? 'DAGDAG BUDGET' : 'Edit Budget',
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
                    TextField(
                        controller: c,
                        keyboardType: TextInputType.number,
                        inputFormatters: [CommaFormatter()],
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold),
                        decoration: InputDecoration(
                            prefixText: '₱',
                            hintText: isAddMode ? 'Ex: 10,000' : 'Ex: 50,000')),
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
                      double v =
                          double.tryParse(c.text.replaceAll(',', '')) ?? 0;
                      if (v <= 0) return;
                      setState(() {
                        if (isAddMode)
                          budget += v;
                        else
                          budget = v;
                      });
                      _saveData();
                      Navigator.pop(context);
                    },
                    child: Text(isAddMode ? 'DAGDAG NA!' : 'SAVE',
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold))),
              ],
            ));
  }

  void addEdit({Expense? ex}) {
    // CHECK TRIAL LIMIT BOSS!
    if (ex == null && isTrialVersion && all.length >= trialLimit) {
      _showTrialLockDialog();
      return;
    }
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
                    if (ex == null && isTrialVersion)
                      Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                              color: Colors.orange.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: Text(
                              'Trial: ${all.length}/$trialLimit entries',
                              style: const TextStyle(
                                  color: Colors.orange, fontSize: 10))),
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
                            labelText: 'Magkano?', prefixText: '₱')),
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
                            style: TextStyle(color: Color(0xFFFFD700)))),
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
                          _saveData();
                          Navigator.pop(context);
                          Future.delayed(const Duration(milliseconds: 300),
                              () => checkOverBudget());
                        },
                        child: const Text('SAVE',
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.bold))),
                  ],
                )));
  }

  @override
  Widget build(BuildContext context) {
    double totalGrouped = grouped.fold(0, (a, b) => a + b.total);
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E1E1E),
        centerTitle: true,
        toolbarHeight: 75,
        title: Column(
          children: [
            const Text('BUDGET vs GASTOS',
                style: TextStyle(
                    color: Color(0xFFFFD700),
                    fontWeight: FontWeight.bold,
                    fontSize: 18)),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                      color: Colors.white10,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.white24, width: 0.5)),
                  child: const Text('Trial Version',
                      style: TextStyle(
                          color: Colors.white54,
                          fontSize: 9,
                          letterSpacing: 0.5)),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _openProVersion,
                  child: const Row(
                    children: [
                      Icon(Icons.star, size: 12, color: Color(0xFF00D1FF)),
                      SizedBox(width: 3),
                      Text('Upgrade to PRO',
                          style: TextStyle(
                              color: Color(0xFF00D1FF),
                              fontSize: 10,
                              decoration: TextDecoration.underline,
                              decorationColor: Color(0xFF00D1FF),
                              fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
              icon: const Icon(Icons.wallet, color: Color(0xFFFFD700)),
              onPressed: () => addBudgetDialog())
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: isTrialVersion && all.length >= trialLimit
            ? Colors.grey
            : const Color(0xFFFFD700),
        onPressed: () => addEdit(),
        child: Icon(
            isTrialVersion && all.length >= trialLimit ? Icons.lock : Icons.add,
            color: Colors.black),
      ),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        if (isTrialVersion)
          Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: all.length >= trialLimit
                      ? Colors.red.withValues(alpha: 0.15)
                      : Colors.orange.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color:
                          all.length >= trialLimit ? Colors.red : Colors.orange,
                      width: 0.5)),
              child: Row(children: [
                Icon(all.length >= trialLimit ? Icons.lock : Icons.info_outline,
                    size: 14,
                    color:
                        all.length >= trialLimit ? Colors.red : Colors.orange),
                const SizedBox(width: 6),
                Text(
                    all.length >= trialLimit
                        ? 'Trial limit reached!'
                        : 'Trial: ${all.length}/$trialLimit gastos',
                    style: TextStyle(
                        color: all.length >= trialLimit
                            ? Colors.red
                            : Colors.orange,
                        fontSize: 11,
                        fontWeight: FontWeight.bold)),
                const Spacer(),
                if (all.length >= trialLimit)
                  InkWell(
                      onTap: _openProVersion,
                      child: const Text('UPGRADE',
                          style: TextStyle(
                              color: Color(0xFF00D1FF),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline)))
              ])),
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
                const Text('PIE CHART',
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12)),
                const SizedBox(height: 16),
                SizedBox(
                    height: 240,
                    child: Stack(alignment: Alignment.center, children: [
                      CustomPaint(
                          size: const Size(240, 240),
                          painter:
                              PiePainter(data: grouped, total: totalGrouped)),
                      Column(mainAxisSize: MainAxisSize.min, children: [
                        const Text('TOTAL',
                            style:
                                TextStyle(color: Colors.white54, fontSize: 10)),
                        Text(peso(totalGrouped),
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18))
                      ])
                    ])),
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
                        onPressed: () {
                          setState(() => all.remove(e));
                          _saveData();
                        })
                  ]))),
      ]),
    );
  }
}
