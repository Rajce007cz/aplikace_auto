import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
 
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
 
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
 
  runApp(const MyApp());
}
 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: .fromSeed(
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
 
  int _vybranyIndex = 0;
 
  List<Widget> get _sekce => [_ukolnicek(), _glovebox(), _spotreba()];
 
  void otevritDialog() {
    TextEditingController nazevController = TextEditingController();
    TextEditingController popisController = TextEditingController();
    TextEditingController datumOdController = TextEditingController();
    TextEditingController datumDoController = TextEditingController();
 
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Nová Položka"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nazevController,
                decoration: const InputDecoration(labelText: "Název"),
              ),
              TextField(
                controller: popisController,
                keyboardType: TextInputType.text,
                decoration: const InputDecoration(labelText: "Popis"),
              ),
              TextField(
                controller: datumOdController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Datum Od"),
                onTap: () async {
                  DateTime? datum = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (datum != null) {
                    datumOdController.text =
                        "${datum.day}.${datum.month}.${datum.year}";
                  }
                },
              ),
              TextField(
                controller: datumDoController,
                readOnly: true,
                decoration: const InputDecoration(labelText: "Datum Do"),
                onTap: () async {
                  DateTime? datum = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (datum != null) {
                    datumDoController.text =
                        "${datum.day}.${datum.month}.${datum.year}";
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Zrušit"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (nazevController.text.isEmpty ||
                    datumOdController.text.isEmpty ||
                    datumDoController.text.isEmpty) {
                  return;
                }
 
                try {
                  await FirebaseFirestore.instance.collection('ukoly').add({
                    'nazev': nazevController.text,
                    'popis': popisController.text,
                    'datumOd': datumOdController.text,
                    'datumDo': datumDoController.text,
                    'vytvoreno': FieldValue.serverTimestamp(),
                  });
 
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
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
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
      floatingActionButton: _vybranyIndex == 0
          ? FloatingActionButton(
              onPressed: otevritDialog,
              tooltip: 'Increment',
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
 
  Widget _ukolnicek() {
    return Center(
      child: Column(
        mainAxisAlignment: .center,
        children: [
          Expanded(
            // StreamBuilder poslouchá změny v kolekci 'ukoly'
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('ukoly')
                  .orderBy(
                    'vytvoreno',
                    descending: true,
                  ) // Seřadíme od nejnovějšího
                  .snapshots(),
              builder: (context, snapshot) {
                // 1. Zpracování stavu načítání
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
 
                // 2. Zpracování chyb
                if (snapshot.hasError) {
                  return Center(child: Text('Chyba: ${snapshot.error}'));
                }
 
                // 3. Kontrola, zda máme nějaká data
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text("Zatím tu nejsou žádné úkoly."),
                  );
                }
 
                // 4. Vykreslení seznamu
                final dokumenty = snapshot.data!.docs;
 
                return ListView.builder(
                  itemCount: dokumenty.length,
                  itemBuilder: (context, index) {
                    // Vytáhneme data z Firestore dokumentu
                    var data = dokumenty[index].data() as Map<String, dynamic>;
 
                    // Ošetříme případně chybějící data, abychom předešli pádům
                    String nazev = data['nazev'] ?? 'Bez názvu';
                    String datumOd = data['datumOd'] ?? '';
                    String datumDo = data['datumDo'] ?? '';
                    // Můžeš zobrazit i popis: String popis = data['popis'] ?? '';
 
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
                                Expanded(
                                  child: Text(
                                    nazev,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  "$datumOd - $datumDo",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            LinearProgressIndicator(value: progress),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          ElevatedButton(onPressed: otevritDialog, child: const Text('Přidat')),
        ],
      ),
    );
  }
 
  Widget _glovebox() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Widgety v hlavním okně
        ],
      ),
    );
  }
 
  Widget _spotreba() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          // Widgety v hlavním okně
        ],
      ),
    );
  }
}
 

/*class Zaznam {
  final String nazev;
  final String popis;
  final String datumOd;
  final String datumDo;
  Zaznam(this.nazev, this.popis, this.datumOd, this.datumDo,);
}
*/