import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  try {
    if (FirebaseAuth.instance.currentUser == null) {
      await FirebaseAuth.instance.signInAnonymously();
      print("Uživatel byl nově anonymně přihlášen: ${FirebaseAuth.instance.currentUser?.uid}");
    } else {
      print("Uživatel už je přihlášen z minula: ${FirebaseAuth.instance.currentUser?.uid}");
    }
  } catch (e) {
    print("Chyba při přihlašování (pravděpodobně chybí internet při prvním startu): $e");
  }

  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 53, 83, 219),
        ),
      ),
      locale: Locale('cs'),
      supportedLocales: [Locale('cs'), Locale('en')],
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}
 
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;
 
  @override
  State<MyHomePage> createState() => _MyHomePageState();
}
 
class _MyHomePageState extends State<MyHomePage> {
  String Nazev = "";
  String Popis = "";
  DateTime? DatumOd;
  DateTime? DatumDo;
  //List<Zaznam> zaznamy = [];
  List<TankovaniZaznam> tankovaniZaznamy = [];

  String? vybraneAutoId;
  String vybraneAutoNazev = "Vyberte vozidlo";
  Color vybranaBarva = Colors.blue; // Výchozí barva
 
  int _vybranyIndex = 0;

  @override
  void initState() {
    super.initState();
    _nactiPrvniAuto();
  }

  Future<void> _nactiPrvniAuto() async {
    // Aplikace si při startu sáhne do databáze pro 1 auto
    final query = await FirebaseFirestore.instance.collection('auta').limit(1).get();
    
    if (query.docs.isNotEmpty) {
      final prvniAuto = query.docs.first;
      setState(() {
        vybraneAutoId = prvniAuto.id;
        vybraneAutoNazev = prvniAuto['nazev'];
        vybranaBarva = Color(prvniAuto['barva']);
      });
    }
  }
 
  List<Widget> get _sekce => [_ukolnicek(), _gloveBox(), _spotreba()];

  void otevritDialogNoveAuto([DocumentSnapshot? doc]) {
    TextEditingController nazevController = TextEditingController(text: doc != null ? doc['nazev'] : "");
    Color vybranaNovaBarva = doc != null ? Color(doc['barva']) : Colors.blue;
    List<Color> barvy = [Colors.blue, Colors.red, Colors.green, Colors.orange, Colors.purple, Colors.grey];

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(doc == null ? "Nové auto" : "Upravit auto"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(controller: nazevController, decoration: const InputDecoration(labelText: "Název auta")),
                  const SizedBox(height: 16),
                  const Text("Vyberte barvu auta:"),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: barvy.map((barva) {
                      return GestureDetector(
                        onTap: () => setDialogState(() => vybranaNovaBarva = barva),
                        child: CircleAvatar(
                          backgroundColor: barva,
                          child: vybranaNovaBarva == barva ? const Icon(Icons.check, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Zrušit")),
                ElevatedButton(
                  onPressed: () async {
                    if (nazevController.text.trim().isEmpty) return;
                    if (doc == null) {
                      await FirebaseFirestore.instance.collection('auta').add({
                        'nazev': nazevController.text.trim(),
                        'barva': vybranaNovaBarva.value, 
                        'vytvoreno': FieldValue.serverTimestamp(),
                      });
                    } else {
                      await FirebaseFirestore.instance.collection('auta').doc(doc.id).update({
                        'nazev': nazevController.text.trim(),
                        'barva': vybranaNovaBarva.value,
                      });
                      // Pokud upravujeme aktuálně vybrané auto, updatneme rovnou UI
                      if (vybraneAutoId == doc.id) {
                        setState(() {
                          vybraneAutoNazev = nazevController.text.trim();
                          vybranaBarva = vybranaNovaBarva;
                        });
                      }
                    }
                    if (context.mounted) Navigator.pop(context);
                  },
                  child: const Text("Uložit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // 2. DIALOG PRO ÚKOLNÍČEK
  void otevritDialog([DocumentSnapshot? doc]) {
    var data = doc?.data() as Map<String, dynamic>?;
    TextEditingController nazevController = TextEditingController(text: data?['nazev'] ?? '');
    TextEditingController popisController = TextEditingController(text: data?['popis'] ?? '');
    TextEditingController datumOdController = TextEditingController(text: data?['datumOd'] ?? '');
    TextEditingController datumDoController = TextEditingController(text: data?['datumDo'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc == null ? "Nová Položka" : "Upravit Položku"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nazevController, decoration: const InputDecoration(labelText: "Název")),
              TextField(controller: popisController, decoration: const InputDecoration(labelText: "Popis")),
              TextField(
                controller: datumOdController, readOnly: true, decoration: const InputDecoration(labelText: "Datum Od"),
                onTap: () async {
                  DateTime? datum = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (datum != null) datumOdController.text = "${datum.day}.${datum.month}.${datum.year}";
                },
              ),
              TextField(
                controller: datumDoController, readOnly: true, decoration: const InputDecoration(labelText: "Datum Do"),
                onTap: () async {
                  DateTime? datum = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                  if (datum != null) datumDoController.text = "${datum.day}.${datum.month}.${datum.year}";
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Zrušit")),
            ElevatedButton(
              onPressed: () async {
                if (nazevController.text.isEmpty || datumOdController.text.isEmpty || datumDoController.text.isEmpty) return;
                if (vybraneAutoId == null) return; 

                Map<String, dynamic> ukladanaData = {
                  'autoId': vybraneAutoId,
                  'nazev': nazevController.text,
                  'popis': popisController.text,
                  'datumOd': datumOdController.text,
                  'datumDo': datumDoController.text,
                };

                try {
                  if (doc == null) {
                    ukladanaData['vytvoreno'] = FieldValue.serverTimestamp();
                    await FirebaseFirestore.instance.collection('ukoly').add(ukladanaData);
                  } else {
                    await FirebaseFirestore.instance.collection('ukoly').doc(doc.id).update(ukladanaData);
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  print("Chyba při ukládání: $e");
                }
              },
              child: const Text("Uložit"),
            ),
          ],
        );
      },
    );
  }
 
  double _spocitejProgres(String datumZacatkuString, String datumKonceString) {
    DateTime prevedCeskeDatum(String datum) {
      List<String> casti = datum.split('.');
      if (casti.length == 3) {
        int den = int.parse(casti[0]);
        int mesic = int.parse(casti[1]);
        int rok = int.parse(casti[2]);
        return DateTime(rok, mesic, den);
      }
      return DateTime.now();
    }
 
    try {
      final datumZacatku = prevedCeskeDatum(datumZacatkuString);
      final datumKonce = prevedCeskeDatum(datumKonceString);
      final dnes = DateTime.now();
 
      final celkovyCas = datumKonce.difference(datumZacatku).inSeconds;
      final uplynulyCas = dnes.difference(datumZacatku).inSeconds;
 
      if (celkovyCas <= 0) return 1.0;
 
      double pomer = uplynulyCas / celkovyCas;
      return pomer.clamp(0.0, 1.0);
    } catch (e) {
      print("Chyba při výpočtu progresu: $e");
      return 0.0;
    }
  }

  bool _zbyvaMeneNezMesic(String datumKonceString) {
    try {
      List<String> casti = datumKonceString.split('.');
      if (casti.length == 3) {
        int den = int.parse(casti[0]);
        int mesic = int.parse(casti[1]);
        int rok = int.parse(casti[2]);
        DateTime datumKonce = DateTime(rok, mesic, den);
        DateTime dnes = DateTime.now();

        // Spočítáme rozdíl ve dnech
        int zbyvaDni = datumKonce.difference(dnes).inDays;
        
        // Vrací TRUE, pokud zbývá 30 nebo méně dní (případně pokud už je po termínu)
        return zbyvaDni <= 30; 
      }
    } catch (e) {
      print("Chyba při kontrole data: $e");
    }
    return false;
  }

  void otevritDialogGloveBox([DocumentSnapshot? doc]) {
    var data = doc?.data() as Map<String, dynamic>?;
    TextEditingController nadpisController = TextEditingController(text: data?['nadpis'] ?? '');
    TextEditingController textController = TextEditingController(text: data?['hodnota'] ?? '');

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(doc == null ? "Přidat do kastlíku" : "Upravit záznam"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nadpisController, decoration: const InputDecoration(labelText: "Nadpis")),
              const SizedBox(height: 16),
              TextField(controller: textController, decoration: const InputDecoration(labelText: "Hodnota")),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Zrušit")),
            ElevatedButton(
              onPressed: () async {
                if (nadpisController.text.trim().isEmpty || textController.text.trim().isEmpty) return;
                if (vybraneAutoId == null) return; 

                try {
                  if (doc == null) {
                    await FirebaseFirestore.instance.collection('glovebox').add({
                      'autoId': vybraneAutoId,
                      'nadpis': nadpisController.text.trim(),
                      'hodnota': textController.text.trim(),
                      'vytvoreno': FieldValue.serverTimestamp(),
                    });
                  } else {
                    await FirebaseFirestore.instance.collection('glovebox').doc(doc.id).update({
                      'nadpis': nadpisController.text.trim(),
                      'hodnota': textController.text.trim(),
                    });
                  }
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  print("Chyba při ukládání do kastlíku: $e");
                }
              },
              child: const Text("Uložit"),
            ),
          ],
        );
      },
    );
  }

  // 4. DIALOG PRO TANKOVÁNÍ
  void otevritDialogTankovani([TankovaniZaznam? zaznam]) {
    TextEditingController tachometrController = TextEditingController(text: zaznam != null ? zaznam.tachometr.toString() : "");
    TextEditingController litryController = TextEditingController(text: zaznam != null ? zaznam.litry.toString() : "");
    TextEditingController cenaController = TextEditingController(text: zaznam != null ? zaznam.cena.toString() : "");
    bool jePlna = zaznam != null ? zaznam.jePlna : true;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(zaznam == null ? "Nové tankování" : "Upravit tankování"),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: tachometrController, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: "Stav tachometru (km)")),
                    TextField(controller: litryController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Natankováno (litry)")),
                    TextField(controller: cenaController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: "Celková cena (Kč)")),
                    const SizedBox(height: 16),
                    CheckboxListTile(
                      title: const Text("Plná nádrž?"), value: jePlna, activeColor: Colors.blue,
                      onChanged: (bool? novaHodnota) => setDialogState(() => jePlna = novaHodnota ?? true),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text("Zrušit")),
                ElevatedButton(
                  onPressed: () async {
                    if (tachometrController.text.isEmpty || litryController.text.isEmpty) return;
                    if (vybraneAutoId == null) return;

                    try {
                      int tacho = int.tryParse(tachometrController.text) ?? 0;
                      double litry = double.tryParse(litryController.text.replaceAll(',', '.')) ?? 0.0;
                      double cena = double.tryParse(cenaController.text.replaceAll(',', '.')) ?? 0.0;

                      Map<String, dynamic> uprava = {
                        'tachometr': tacho,
                        'litry': litry,
                        'cena': cena,
                        'jePlna': jePlna,
                      };

                      if (zaznam == null) {
                        uprava['autoId'] = vybraneAutoId;
                        uprava['vytvoreno'] = FieldValue.serverTimestamp();
                        await FirebaseFirestore.instance.collection('tankovani').add(uprava);
                      } else {
                        await FirebaseFirestore.instance.collection('tankovani').doc(zaznam.id).update(uprava);
                      }
                      if (context.mounted) Navigator.pop(context);
                    } catch (e) {
                      print("Chyba při ukládání tankování: $e");
                    }
                  },
                  child: const Text("Uložit"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  String _spocitejSpotrebu(int index, List<TankovaniZaznam> seznam) {
    final aktualni = seznam[index];

    if (!aktualni.jePlna) return "Částečné tankování";

    int indexPredchoziPlne = -1;
    for (int i = index + 1; i < seznam.length; i++) {
      if (seznam[i].jePlna) {
        indexPredchoziPlne = i;
        break;
      }
    }

    if (indexPredchoziPlne == -1) return "První plná (Start měření)";

    double celkemLitru = aktualni.litry;
    for (int i = index + 1; i < indexPredchoziPlne; i++) {
      celkemLitru += seznam[i].litry;
    }

    double ujeteKm = (aktualni.tachometr - seznam[indexPredchoziPlne].tachometr).toDouble();

    if (ujeteKm <= 0) return "Chyba tachometru";

    double spotreba = (celkemLitru / ujeteKm) * 100;
    return "Spotřeba: ${spotreba.toStringAsFixed(2)} l/100 km";
  }

  void _otevritVyberAuta() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min, // Okno bude jen tak velké, jak potřebuje
            children: [
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16.0),
                child: Text("Vyberte vozidlo", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              // StreamBuilder nám tady dynamicky vypíše všechna auta
              Flexible(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance.collection('auta').snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text("Zatím žádná auta v garáži."),
                      );
                    }

                    final auta = snapshot.data!.docs;
                    return ListView.builder(
                      shrinkWrap: true, // DŮLEŽITÉ! Aby seznam v BottomSheetu nedělal chyby
                      itemCount: auta.length,
                      itemBuilder: (context, index) {
                        final auto = auta[index];
                        final barvaAuta = Color(auto['barva']);
                        final jeVybrano = vybraneAutoId == auto.id;

                        return ListTile(
                          leading: Icon(Icons.directions_car, color: barvaAuta),
                          title: Text(auto['nazev'], style: TextStyle(fontWeight: jeVybrano ? FontWeight.bold : FontWeight.normal)),
                          // NOVÉ MENU MÍSTO JEN FAJFKY
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (jeVybrano) const Icon(Icons.check, color: Colors.green),
                              PopupMenuButton<String>(
                                onSelected: (value) async {
                                  if (value == 'edit') {
                                    Navigator.pop(context);
                                    otevritDialogNoveAuto(auto);
                                  } else if (value == 'delete') {
                                    await FirebaseFirestore.instance.collection('auta').doc(auto.id).delete();
                                    if (jeVybrano) {
                                      setState(() { vybraneAutoId = null; vybraneAutoNazev = "Vyberte vozidlo"; vybranaBarva = Colors.blue; });
                                      _nactiPrvniAuto();
                                    }
                                    Navigator.pop(context);
                                  }
                                },
                                itemBuilder: (context) => [
                                  const PopupMenuItem(value: 'edit', child: Text('Upravit')),
                                  const PopupMenuItem(value: 'delete', child: Text('Smazat')),
                                ],
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() { vybraneAutoId = auto.id; vybraneAutoNazev = auto['nazev']; vybranaBarva = barvaAuta; });
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.add_circle_outline, color: Colors.blue),
                title: const Text('Přidat nové auto', style: TextStyle(color: Colors.blue, fontWeight: FontWeight.bold)),
                onTap: () {
                  Navigator.pop(context);
                  otevritDialogNoveAuto();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget? _vyberTlacitko() {
    if (_vybranyIndex == 0) {
      return FloatingActionButton(
        onPressed: otevritDialog,
        child: const Icon(Icons.add),
      );
    } else if (_vybranyIndex == 1) {
      return FloatingActionButton(
        onPressed: otevritDialogGloveBox,
        child: const Icon(Icons.note_add),
      );
    } else if (_vybranyIndex == 2) {
      return FloatingActionButton(
        onPressed: otevritDialogTankovani,
        child: const Icon(Icons.add),
      );
    }
    return null;
  }

 @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: vybranaBarva,
        title: GestureDetector(
          onTap: _otevritVyberAuta,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                vybraneAutoNazev, 
                style: const TextStyle(fontWeight: FontWeight.bold)
              ),
              const Icon(Icons.arrow_drop_down, size: 30),
            ],
          ),
        ),
      ),

      body: _sekce[_vybranyIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _vybranyIndex,
        onTap: (index) {
          setState(() {
            _vybranyIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.assignment_outlined),
            label: 'Úkolníček',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info_outline),
            label: 'GloveBox',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.local_gas_station),
            label: 'Spotřeba',
          ),
        ],
      ),
      floatingActionButton: _vyberTlacitko(),
    );
  }
 
  Widget _ukolnicek() {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ukoly')
                  .where('autoId', isEqualTo: vybraneAutoId)
                  .orderBy('vytvoreno', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(child: Text('Chyba: ${snapshot.error}'));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Zatím tu nejsou žádné úkoly."),
                  );
                }

                final dokumenty = snapshot.data!.docs;
 
                return ListView.builder(
                  itemCount: dokumenty.length,
                  itemBuilder: (context, index) {

                    var data = dokumenty[index].data() as Map<String, dynamic>;
 
                    String nazev = data['nazev'] ?? 'Bez názvu';
                    String datumOd = data['datumOd'] ?? '';
                    String datumDo = data['datumDo'] ?? '';
                    // Můžeš zobrazit i popis: String popis = data['popis'] ?? '';

                    bool jeKriticky = _zbyvaMeneNezMesic(datumDo);
 
                    double progress = _spocitejProgres(datumOd, datumDo);
 
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(child: Text(nazev, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                                  Text("$datumOd - $datumDo", style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                                  // NOVÉ MENU
                                  PopupMenuButton<String>(
                                    padding: EdgeInsets.zero,
                                    onSelected: (value) async {
                                      if (value == 'edit') otevritDialog(dokumenty[index]);
                                      else if (value == 'delete') await FirebaseFirestore.instance.collection('ukoly').doc(dokumenty[index].id).delete();
                                    },
                                    itemBuilder: (context) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Upravit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Smazat')),
                                    ],
                                  ),
                                ],
                              ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(
                              value: progress,
                              backgroundColor: Colors.grey[300],
                              color: jeKriticky ? Colors.red : Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
 
  Widget _gloveBox() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('glovebox')
          .where('autoId', isEqualTo: vybraneAutoId)
          .orderBy('vytvoreno', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Kastlík je prázdný. Přidej si sem informace o autě!"));
        }

        return ListView.builder(
          itemCount: snapshot.data!.docs.length,
          itemBuilder: (context, index) {
            final doc = snapshot.data!.docs[index];
            final data = doc.data() as Map<String, dynamic>;
            
            final String nadpis = data['nadpis'] ?? '';
            final String hodnota = data['hodnota'] ?? '';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: const Icon(Icons.text_snippet, color: Colors.blue, size: 32),
                title: Text(nadpis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                subtitle: Text(hodnota, style: const TextStyle(fontSize: 16, color: Colors.black87)),
                // NOVÉ MENU
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') otevritDialogGloveBox(doc);
                    else if (value == 'delete') await FirebaseFirestore.instance.collection('glovebox').doc(doc.id).delete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Upravit')),
                    const PopupMenuItem(value: 'delete', child: Text('Smazat')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
 
  Widget _spotreba() {
    return StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('tankovani')
            .where('autoId', isEqualTo: vybraneAutoId)
            .orderBy('tachometr', descending: true)
            .snapshots(),      builder: (context, snapshot) {
        // Pokud se data teprve načítají z internetu
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Zatím žádné tankování."));
        }

        final docs = snapshot.data!.docs;
        List<TankovaniZaznam> nacteneZaznamy = docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return TankovaniZaznam(
            doc.id,
            data['tachometr'] ?? 0,
            (data['litry'] ?? 0).toDouble(),
            (data['cena'] ?? 0).toDouble(),
            data['jePlna'] ?? false,
          );
        }).toList();

        return ListView.builder(
          itemCount: nacteneZaznamy.length,
          itemBuilder: (context, index) {
            final zaznam = nacteneZaznamy[index];
            
            String zobrazenoSpotreba = _spocitejSpotrebu(index, nacteneZaznamy);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: Icon(zaznam.jePlna ? Icons.local_gas_station : Icons.local_gas_station, color: zaznam.jePlna ? Colors.green : Colors.orange, size: 32),
                title: Text("${zaznam.litry} litrů | ${zaznam.cena} Kč", style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text("Tachometr: ${zaznam.tachometr} km\n$zobrazenoSpotreba"),
                isThreeLine: true,
                // NOVÉ MENU
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') otevritDialogTankovani(zaznam);
                    else if (value == 'delete') await FirebaseFirestore.instance.collection('tankovani').doc(zaznam.id).delete();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'edit', child: Text('Upravit')),
                    const PopupMenuItem(value: 'delete', child: Text('Smazat')),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class TankovaniZaznam {
  final String id;
  final int tachometr;
  final double litry;
  final double cena;
  final bool jePlna;

  TankovaniZaznam(this.id, this.tachometr, this.litry, this.cena, this.jePlna);
}
 
/*class Zaznam {
  final String nazev;
  final String popis;
  final String datumOd;
  final String datumDo;
  Zaznam(this.nazev, this.popis, this.datumOd, this.datumDo,);
}
*/