import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../models/encuesta_model.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'encuestas.db');
    return await openDatabase(
      path,
      version: 2, // Aumentamos la versión
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE encuestas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        fechaCreacion TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE preguntas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        encuestaId INTEGER,
        texto TEXT NOT NULL,
        tipo TEXT NOT NULL,
        opciones TEXT,
        respuesta TEXT,
        FOREIGN KEY (encuestaId) REFERENCES encuestas(id)
      )
    ''');

    // NUEVA TABLA para respuestas de usuarios
    await db.execute('''
      CREATE TABLE respuestas_usuarios(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        encuestaId INTEGER NOT NULL,
        preguntaId INTEGER NOT NULL,
        respuesta TEXT NOT NULL,
        nombreUsuario TEXT NOT NULL,
        fechaRespuesta TEXT NOT NULL,
        FOREIGN KEY (encuestaId) REFERENCES encuestas(id),
        FOREIGN KEY (preguntaId) REFERENCES preguntas(id)
      )
    ''');
  }

  // Para actualizar la base de datos si ya existe
  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS respuestas_usuarios(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          encuestaId INTEGER NOT NULL,
          preguntaId INTEGER NOT NULL,
          respuesta TEXT NOT NULL,
          nombreUsuario TEXT NOT NULL,
          fechaRespuesta TEXT NOT NULL,
          FOREIGN KEY (encuestaId) REFERENCES encuestas(id),
          FOREIGN KEY (preguntaId) REFERENCES preguntas(id)
        )
      ''');
    }
  }

  // Insertar una encuesta y sus preguntas
  Future<int> insertarEncuesta(Encuesta encuesta) async {
    final db = await database;
    int encuestaId = await db.insert('encuestas', encuesta.toMap());
    
    for (var pregunta in encuesta.preguntas) {
      pregunta.encuestaId = encuestaId;
      await db.insert('preguntas', pregunta.toMap());
    }
    
    return encuestaId;
  }

  // Obtener todas las encuestas con sus preguntas
  Future<List<Encuesta>> obtenerEncuestas() async {
    final db = await database;
    final List<Map<String, dynamic>> encuestasMaps = await db.query('encuestas');
    
    List<Encuesta> encuestas = [];
    for (var encuestaMap in encuestasMaps) {
      Encuesta encuesta = Encuesta.fromMap(encuestaMap);
      encuesta.preguntas = await obtenerPreguntasDeEncuesta(encuesta.id!);
      encuestas.add(encuesta);
    }
    
    return encuestas;
  }

  // Obtener preguntas de una encuesta específica
  Future<List<Pregunta>> obtenerPreguntasDeEncuesta(int encuestaId) async {
    final db = await database;
    final List<Map<String, dynamic>> preguntasMaps = await db.query(
      'preguntas',
      where: 'encuestaId = ?',
      whereArgs: [encuestaId],
    );
    
    return List.generate(preguntasMaps.length, (i) {
      return Pregunta.fromMap(preguntasMaps[i]);
    });
  }

  // NUEVO: Guardar respuesta de un usuario
  Future<void> guardarRespuestaUsuario(RespuestaUsuario respuesta) async {
    final db = await database;
    await db.insert('respuestas_usuarios', respuesta.toMap());
  }

  // NUEVO: Guardar todas las respuestas de un usuario
  Future<void> guardarRespuestasUsuario({
    required int encuestaId,
    required String nombreUsuario,
    required Map<int, String> respuestas,
  }) async {
    final db = await database;
    final batch = db.batch();
    final fechaActual = DateTime.now();

    for (var entry in respuestas.entries) {
      batch.insert('respuestas_usuarios', {
        'encuestaId': encuestaId,
        'preguntaId': entry.key,
        'respuesta': entry.value,
        'nombreUsuario': nombreUsuario,
        'fechaRespuesta': fechaActual.toIso8601String(),
      });
    }

    await batch.commit(noResult: true);
  }

  // NUEVO: Obtener respuestas de una encuesta agrupadas por usuario
  Future<List<RespuestaAgrupada>> obtenerRespuestasAgrupadas(int encuestaId) async {
    final db = await database;
    
    // Obtener todas las respuestas de la encuesta
    final List<Map<String, dynamic>> maps = await db.query(
      'respuestas_usuarios',
      where: 'encuestaId = ?',
      whereArgs: [encuestaId],
      orderBy: 'fechaRespuesta DESC',
    );

    // Agrupar por usuario y fecha
    Map<String, List<RespuestaUsuario>> agrupadas = {};
    
    for (var map in maps) {
      final respuesta = RespuestaUsuario.fromMap(map);
      final key = '${respuesta.nombreUsuario}_${respuesta.fechaRespuesta.toIso8601String()}';
      
      if (!agrupadas.containsKey(key)) {
        agrupadas[key] = [];
      }
      agrupadas[key]!.add(respuesta);
    }

    // Convertir a lista de RespuestaAgrupada
    List<RespuestaAgrupada> resultado = [];
    agrupadas.forEach((key, respuestas) {
      resultado.add(RespuestaAgrupada(
        nombreUsuario: respuestas.first.nombreUsuario,
        fechaRespuesta: respuestas.first.fechaRespuesta,
        respuestas: respuestas,
      ));
    });

    return resultado;
  }

  // NUEVO: Obtener número de usuarios que han respondido una encuesta
  Future<int> obtenerNumeroUsuarios(int encuestaId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT nombreUsuario) as total FROM respuestas_usuarios WHERE encuestaId = ?',
      [encuestaId],
    );
    return result.first['total'] as int? ?? 0;
  }

  // NUEVO: Obtener total de respuestas de una encuesta
  Future<int> obtenerTotalRespuestas(int encuestaId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM respuestas_usuarios WHERE encuestaId = ?',
      [encuestaId],
    );
    return result.first['total'] as int? ?? 0;
  }

  // Actualizar respuesta de una pregunta (mantenemos para compatibilidad)
  Future<void> actualizarRespuestaPregunta(int preguntaId, String respuesta) async {
    final db = await database;
    await db.update(
      'preguntas',
      {'respuesta': respuesta},
      where: 'id = ?',
      whereArgs: [preguntaId],
    );
  }

  // Eliminar encuesta y sus preguntas
  Future<void> eliminarEncuesta(int encuestaId) async {
    final db = await database;
    await db.delete('respuestas_usuarios', where: 'encuestaId = ?', whereArgs: [encuestaId]);
    await db.delete('preguntas', where: 'encuestaId = ?', whereArgs: [encuestaId]);
    await db.delete('encuestas', where: 'id = ?', whereArgs: [encuestaId]);
  }

  // NUEVO: Eliminar respuestas de un usuario específico
  Future<void> eliminarRespuestasUsuario(int encuestaId, String nombreUsuario) async {
    final db = await database;
    await db.delete(
      'respuestas_usuarios',
      where: 'encuestaId = ? AND nombreUsuario = ?',
      whereArgs: [encuestaId, nombreUsuario],
    );
  }
}