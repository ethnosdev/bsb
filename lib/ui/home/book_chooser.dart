import 'package:flutter/material.dart';

class BookChooser extends StatelessWidget {
  const BookChooser({
    super.key,
    required this.onBookSelected,
  });

  final void Function(String) onBookSelected;

  // static const Color pentateuchColor = Color(0xFF937662);
  // static const Color historicalColor = Color(0xFFb58463);
  // static const Color wisdomColor = Color(0xFFd08c60);
  // static const Color majorProphetsColor = Color(0xFFe8ac65);
  // static const Color minorProphetsColor = Color(0xFFffcb69);
  // static const Color gospelsColor = Color(0xFF6f725a);
  // static const Color paulineColor = Color(0xFF9b9b7a);
  // static const Color generalEpistlesColor = Color(0xFFbaa587);

  //   static Color pentateuchColor = Colors.brown.shade50;
  // static Color historicalColor = Colors.brown.shade100;
  // static Color wisdomColor = Colors.brown.shade50;
  // static Color majorProphetsColor = Colors.brown.shade100;
  // static Color minorProphetsColor = Colors.brown.shade50;
  // static Color gospelsColor = Colors.lime.shade100;
  // static Color paulineColor = Colors.lime.shade50;
  // static Color generalEpistlesColor = Colors.lime.shade100;

  static const Color ot1 = Color(0xFFe9edc9);
  static const Color ot2 = Color(0xFFccd5ae);
  static const Color nt1 = Color(0xFFfefae0);
  static const Color nt2 = Color.fromARGB(255, 248, 228, 180);
  static const Color nt3 = Color(0xFFd4a373);

  static Color pentateuchColor = ot1;
  static Color historicalColor = ot2;
  static Color wisdomColor = ot1;
  static Color majorProphetsColor = ot2;
  static Color minorProphetsColor = ot1;
  static Color gospelsColor = nt2;
  static Color paulineColor = nt1;
  static Color generalEpistlesColor = nt2;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Gen',
                color: pentateuchColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Exo',
                color: pentateuchColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Lev',
                color: pentateuchColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Num',
                color: pentateuchColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Deu',
                color: pentateuchColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Jos',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jdg',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Rut',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '1Sa',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Sa',
                color: historicalColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: '1Ki',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Ki',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '1Ch',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Ch',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Ezr',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Neh',
                color: historicalColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Est',
                color: historicalColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Job',
                color: wisdomColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Psa',
                color: wisdomColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Pro',
                color: wisdomColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Ecc',
                color: wisdomColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Sng',
                color: wisdomColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Isa',
                color: majorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jer',
                color: majorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Lam',
                color: majorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Ezk',
                color: majorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Dan',
                color: majorProphetsColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Hos',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jol',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Amo',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Oba',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jon',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Mic',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Nam',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Hab',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Zep',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Hag',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Zec',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Mal',
                color: minorProphetsColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Mat',
                color: gospelsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Mrk',
                color: gospelsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Luk',
                color: gospelsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jhn',
                color: gospelsColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Act',
                color: gospelsColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Rom',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '1Co',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Co',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Gal',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Eph',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Php',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Col',
                color: paulineColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: '1Th',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Th',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '1Ti',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Ti',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Tit',
                color: paulineColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Phm',
                color: paulineColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: 'Heb',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jas',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '1Pe',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Pe',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              BookItem(
                title: '1Jn',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '2Jn',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: '3Jn',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Jud',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
              BookItem(
                title: 'Rev',
                color: generalEpistlesColor,
                onTap: onBookSelected,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class BookItem extends StatelessWidget {
  const BookItem({
    super.key,
    required this.title,
    required this.color,
    required this.onTap,
  });

  final String title;
  final Color color;
  final void Function(String) onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: color,
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(width: 0.5),
          ),
          child: InkWell(
            onTap: () => onTap(title.toUpperCase()),
            // splashColor: Colors.white.withOpacity(0.2),
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  title,
                  maxLines: 1,
                  style: const TextStyle(
                    color: Colors.black87,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
