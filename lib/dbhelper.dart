import 'package:path/path.dart';
import './place.dart';
import 'package:sqflite/sqflite.dart';

class DbHelper {
  final int version = 1;
  late Database db;
  List<Place> places = [];

  static late final DbHelper _dbHelper = DbHelper._internal();
  DbHelper._internal();

  factory DbHelper() {
    return _dbHelper;
  }


  Future<Database> openDb() async {
    // Ensure that the path to the database is correct
      var databasesPath = await getDatabasesPath();
      String path = join(databasesPath, 'tmap3.db');

      // Open the database
      db = await openDatabase(path, version: 1,
          onCreate: (Database db, int version) async {
        // Create tables if needed
        await db.execute('''
      CREATE TABLE places (
        id INTEGER PRIMARY KEY,
        name TEXT,
        lat REAL,
        lon REAL,
        image TEXT
      )
    ''');
      });
    return db;
  }

  Future insertMockData() async {
    db = await openDb();
    await db.execute(
        'INSERT INTO places VALUES (4, "Beautiful park", 37.421, -122.084, "")');
    await db.execute(
        'INSERT INTO places VALUES (5, "Best Pizza", 37.422, -122.085, "")');
    await db.execute(
        'INSERT INTO places VALUES (6, "The best icecream", 37.423, -122.083, "")');
    List places = await db.rawQuery('select * from places');
  }

  Future<List<Place>> getPlaces() async {
    // get contents of 'places' table from DB
    final List<Map<String, dynamic>> maps = await db.query('places');
    // Convert the List<Map<String, dynamic> into a List<Places>.
    this.places = List.generate(maps.length, (i) {
      return Place(
        maps[i]['id'],
        maps[i]['name'],
        maps[i]['lat'],
        maps[i]['lon'],
        maps[i]['image'],
      );
    });
    return places;
  }

  Future<int> insertPlace(Place place) async {
    int id = await this.db.insert(
          'places',
          place.toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
    return id;
  }

  Future<int> updatePlace(Place place) async {
    int id = await this.db.update(
          'places',
          place.toMap(),
        );
    return id;
  }

  Future<int> deletePlace(Place place) async {
    int result =
        await db.delete("places", where: "id = ?", whereArgs: [place.id]);
    return result;
  }
}
