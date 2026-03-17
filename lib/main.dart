import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
 
void main() {
  runApp(const MyApp());
}


 
class MyApp extends StatelessWidget {
  const MyApp({super.key});
 

 
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(colorScheme: .fromSeed(seedColor: const Color.fromARGB(255, 53, 83, 219))),
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
  List<Zaznam> zaznamy = [];

    int _vybranyIndex = 0;

   List<Widget> get _sekce => [
    _mojeSekceUkolu(),
    const Center(child: Text("GloveBox")),
    const Center(child: Text("Spotřeba")),
  ];
 
  void otevritDialog() {
    TextEditingController nazevController = TextEditingController();
    TextEditingController popisController = TextEditingController();
    TextEditingController datumOdController = TextEditingController();
    TextEditingController datumDoController = TextEditingController();
 
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Nová Položka"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nazevController,
                decoration: InputDecoration(labelText: "Název"),
              ),
              TextField(
                controller: popisController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(labelText: "Popis"),
              ),
              TextField(
                controller: datumOdController,
                readOnly: true,
                decoration: InputDecoration(labelText: "Datum Od"),
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
                decoration: InputDecoration(labelText: "Datum Do"),
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
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text("Zrušit"),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  zaznamy.add(
                    Zaznam(
                      nazevController.text,
                      popisController.text,
                      datumOdController.text,
                      datumDoController.text,
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: Text("OK"),
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
          BottomNavigationBarItem(icon: Icon(Icons.assignment_outlined), label: 'Úkolníček'),
          BottomNavigationBarItem(icon: Icon(Icons.info_outline), label: 'GloveBox'),
          BottomNavigationBarItem(icon: Icon(Icons.local_gas_station), label: 'Spotřeba'),
        ],
      ),
      floatingActionButton: _vybranyIndex == 0
      ? FloatingActionButton(
        onPressed: otevritDialog,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ) : null
    );
      
      
}
Widget _mojeSekceUkolu() {
    return Center(
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Expanded(
  child: ListView.builder(
    itemCount: zaznamy.length,
    itemBuilder: (context, index) {
      final zaznam = zaznamy[index];
    
      double progress = _spocitejProgres(zaznam.datumOd, zaznam.datumDo);

      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                      zaznam.nazev,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis, // Aby dlouhý název nerozhodil design
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "${zaznam.datumOd} - ${zaznam.datumDo}",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Text(
                zaznam.popis,
                style: const TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              ClipRRect(
                borderRadius: BorderRadius.circular(4), 
                child: LinearProgressIndicator(
                  value: progress, 
                  backgroundColor: const Color.fromARGB(255, 204, 9, 9),
                  color: const Color.fromRGBO(20, 119, 199, 1),
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
      );
    },
  ),
),
            ElevatedButton(
              onPressed: otevritDialog,
              child: const Text('Přidat'),
            ),
          ],
        ),
      );
      
  }
  }

 
class Zaznam {
  final String nazev;
  final String popis;
  final String datumOd;
  final String datumDo;
 
  Zaznam(this.nazev, this.popis, this.datumOd, this.datumDo,);
}
 