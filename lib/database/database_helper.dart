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
      version: 4, // Versión 3 para incluir visitas al stand
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    // Tabla de encuestas
    await db.execute('''
      CREATE TABLE encuestas(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        titulo TEXT NOT NULL,
        fechaCreacion TEXT NOT NULL
      )
    ''');

    // Tabla de preguntas
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

    // Tabla de respuestas de usuarios
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

    // Tabla de visitas al stand
    await db.execute('''
      CREATE TABLE visitas_stand(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        fechaEntrada TEXT NOT NULL,
        fechaSalida TEXT,
        nombreVisitante TEXT,
        motivoVisita TEXT,
        observaciones TEXT,
        atendido INTEGER DEFAULT 0
      )
    ''');
      await db.execute('''
        CREATE TABLE eventos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          ubicacion TEXT,
          fechaCreacion TEXT NOT NULL,
          fechaEvento TEXT,
          activo INTEGER DEFAULT 1
        )
      ''');

    // Tabla de visitas por evento
    await db.execute('''
      CREATE TABLE visitas_eventos(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        eventoId INTEGER NOT NULL,
        fecha TEXT NOT NULL,
        cantidad INTEGER DEFAULT 1,
        FOREIGN KEY (eventoId) REFERENCES eventos(id)
      )
    ''');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Agregar tabla de respuestas de usuarios
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
    if (oldVersion < 3) {
      // Agregar tabla de visitas al stand
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visitas_stand(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          fechaEntrada TEXT NOT NULL,
          fechaSalida TEXT,
          nombreVisitante TEXT,
          motivoVisita TEXT,
          observaciones TEXT,
          atendido INTEGER DEFAULT 0
        )
      ''');
    }
    if (oldVersion < 4) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS eventos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          nombre TEXT NOT NULL,
          descripcion TEXT,
          ubicacion TEXT,
          fechaCreacion TEXT NOT NULL,
          fechaEvento TEXT,
          activo INTEGER DEFAULT 1
        )
      ''');
      
      await db.execute('''
        CREATE TABLE IF NOT EXISTS visitas_eventos(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          eventoId INTEGER NOT NULL,
          fecha TEXT NOT NULL,
          cantidad INTEGER DEFAULT 1,
          FOREIGN KEY (eventoId) REFERENCES eventos(id)
        )
      ''');
    }
  }

  // ==========================================
  // MÉTODOS PARA ENCUESTAS
  // ==========================================

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

  // Actualizar respuesta de una pregunta individual (compatibilidad)
  Future<void> actualizarRespuestaPregunta(int preguntaId, String respuesta) async {
    final db = await database;
    await db.update(
      'preguntas',
      {'respuesta': respuesta},
      where: 'id = ?',
      whereArgs: [preguntaId],
    );
  }

  // Eliminar encuesta y todos sus datos relacionados
  Future<void> eliminarEncuesta(int encuestaId) async {
    final db = await database;
    await db.delete('respuestas_usuarios', where: 'encuestaId = ?', whereArgs: [encuestaId]);
    await db.delete('preguntas', where: 'encuestaId = ?', whereArgs: [encuestaId]);
    await db.delete('encuestas', where: 'id = ?', whereArgs: [encuestaId]);
  }

  // ==========================================
  // MÉTODOS PARA RESPUESTAS DE USUARIOS
  // ==========================================

  // Guardar una respuesta de usuario individual
  Future<void> guardarRespuestaUsuario(RespuestaUsuario respuesta) async {
    final db = await database;
    await db.insert('respuestas_usuarios', respuesta.toMap());
  }

  // Guardar todas las respuestas de un usuario
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

  // Obtener respuestas de una encuesta agrupadas por usuario
  Future<List<RespuestaAgrupada>> obtenerRespuestasAgrupadas(int encuestaId) async {
    final db = await database;
    
    final List<Map<String, dynamic>> maps = await db.query(
      'respuestas_usuarios',
      where: 'encuestaId = ?',
      whereArgs: [encuestaId],
      orderBy: 'fechaRespuesta DESC',
    );

    Map<String, List<RespuestaUsuario>> agrupadas = {};
    
    for (var map in maps) {
      final respuesta = RespuestaUsuario.fromMap(map);
      final key = '${respuesta.nombreUsuario}_${respuesta.fechaRespuesta.toIso8601String()}';
      
      if (!agrupadas.containsKey(key)) {
        agrupadas[key] = [];
      }
      agrupadas[key]!.add(respuesta);
    }

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

  // Obtener número de usuarios únicos que respondieron una encuesta
  Future<int> obtenerNumeroUsuarios(int encuestaId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(DISTINCT nombreUsuario) as total FROM respuestas_usuarios WHERE encuestaId = ?',
      [encuestaId],
    );
    return result.first['total'] as int? ?? 0;
  }

  // Obtener total de respuestas de una encuesta
  Future<int> obtenerTotalRespuestas(int encuestaId) async {
    final db = await database;
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM respuestas_usuarios WHERE encuestaId = ?',
      [encuestaId],
    );
    return result.first['total'] as int? ?? 0;
  }

  // Eliminar respuestas de un usuario específico
  Future<void> eliminarRespuestasUsuario(int encuestaId, String nombreUsuario) async {
    final db = await database;
    await db.delete(
      'respuestas_usuarios',
      where: 'encuestaId = ? AND nombreUsuario = ?',
      whereArgs: [encuestaId, nombreUsuario],
    );
  }

  // ==========================================
  // MÉTODOS PARA CONTROL DE STAND
  // ==========================================

  // Registrar nueva visita al stand
  Future<int> registrarVisita(VisitaStand visita) async {
    final db = await database;
    return await db.insert('visitas_stand', visita.toMap());
  }

  // Actualizar visita (salida, atención, datos)
  Future<void> actualizarVisita(VisitaStand visita) async {
    final db = await database;
    await db.update(
      'visitas_stand',
      visita.toMap(),
      where: 'id = ?',
      whereArgs: [visita.id],
    );
  }

  // Obtener todas las visitas, con filtros opcionales
  Future<List<VisitaStand>> obtenerVisitas({DateTime? fecha, bool? soloPendientes}) async {
    final db = await database;
    
    String? where;
    List<dynamic>? whereArgs;
    List<String> conditions = [];
    
    if (fecha != null) {
      conditions.add('date(fechaEntrada) = date(?)');
      whereArgs = [fecha.toIso8601String()];
    }
    
    if (soloPendientes == true) {
      conditions.add('atendido = 0');
    }
    
    if (conditions.isNotEmpty) {
      where = conditions.join(' AND ');
    }
    
    final List<Map<String, dynamic>> maps = await db.query(
      'visitas_stand',
      where: where,
      whereArgs: whereArgs,
      orderBy: 'fechaEntrada DESC',
    );
    
    return List.generate(maps.length, (i) => VisitaStand.fromMap(maps[i]));
  }

  // Obtener estadísticas completas del stand
  Future<EstadisticasStand> obtenerEstadisticasStand() async {
    final db = await database;
    
    // Total de visitas
    final totalResult = await db.rawQuery('SELECT COUNT(*) as total FROM visitas_stand');
    final totalVisitas = totalResult.first['total'] as int? ?? 0;
    
    // Visitas atendidas
    final atendidasResult = await db.rawQuery('SELECT COUNT(*) as total FROM visitas_stand WHERE atendido = 1');
    final visitasAtendidas = atendidasResult.first['total'] as int? ?? 0;
    
    // Visitas pendientes
    final pendientesResult = await db.rawQuery('SELECT COUNT(*) as total FROM visitas_stand WHERE atendido = 0');
    final visitasPendientes = pendientesResult.first['total'] as int? ?? 0;
    
    // Visitas hoy
    final hoy = DateTime.now();
    final hoyResult = await db.rawQuery(
      'SELECT COUNT(*) as total FROM visitas_stand WHERE date(fechaEntrada) = date(?)',
      [hoy.toIso8601String()],
    );
    final visitasHoy = hoyResult.first['total'] as int? ?? 0;
    
    // Tiempo promedio de atención (en segundos)
    final tiempoResult = await db.rawQuery('''
      SELECT AVG(
        CAST(strftime('%s', fechaSalida) AS REAL) - 
        CAST(strftime('%s', fechaEntrada) AS REAL)
      ) as promedio
      FROM visitas_stand 
      WHERE fechaSalida IS NOT NULL
    ''');
    
    double tiempoPromedio = 0.0;
    if (tiempoResult.first['promedio'] != null) {
      tiempoPromedio = (tiempoResult.first['promedio'] as num).toDouble() / 60.0;
    }
    
    // Motivos frecuentes
    final motivosResult = await db.rawQuery('''
      SELECT motivoVisita, COUNT(*) as cantidad 
      FROM visitas_stand 
      WHERE motivoVisita IS NOT NULL AND motivoVisita != ''
      GROUP BY motivoVisita 
      ORDER BY cantidad DESC 
      LIMIT 5
    ''');
    
    List<String> motivosFrecuentes = motivosResult.map((m) => 
      '${m['motivoVisita']} (${m['cantidad']})'
    ).toList();
    
    return EstadisticasStand(
      totalVisitas: totalVisitas,
      visitasAtendidas: visitasAtendidas,
      visitasPendientes: visitasPendientes,
      visitasHoy: visitasHoy,
      tiempoPromedioAtencion: tiempoPromedio,
      motivosFrecuentes: motivosFrecuentes,
    );
  }

  // Obtener conteo rápido de visitas hoy
  Future<int> obtenerVisitasHoy() async {
    final db = await database;
    final hoy = DateTime.now();
    final result = await db.rawQuery(
      'SELECT COUNT(*) as total FROM visitas_stand WHERE date(fechaEntrada) = date(?)',
      [hoy.toIso8601String()],
    );
    return result.first['total'] as int? ?? 0;
  }

  // ==========================================
// MÉTODOS PARA EVENTOS
// ==========================================

// Crear evento
Future<int> crearEvento(Evento evento) async {
  final db = await database;
  return await db.insert('eventos', evento.toMap());
}

// Obtener todos los eventos
Future<List<Evento>> obtenerEventos({bool soloActivos = false}) async {
  final db = await database;
  
  String? where;
  if (soloActivos) {
    where = 'activo = 1';
  }
  
  final List<Map<String, dynamic>> maps = await db.query(
    'eventos',
    where: where,
    orderBy: 'fechaCreacion DESC',
  );
  
  return List.generate(maps.length, (i) => Evento.fromMap(maps[i]));
}

// Actualizar evento
Future<void> actualizarEvento(Evento evento) async {
  final db = await database;
  await db.update(
    'eventos',
    evento.toMap(),
    where: 'id = ?',
    whereArgs: [evento.id],
  );
}

// Eliminar evento
Future<void> eliminarEvento(int eventoId) async {
  final db = await database;
  await db.delete('visitas_eventos', where: 'eventoId = ?', whereArgs: [eventoId]);
  await db.delete('eventos', where: 'id = ?', whereArgs: [eventoId]);
}

// ==========================================
// MÉTODOS PARA VISITAS DE EVENTOS
// ==========================================

// Registrar visita a un evento
Future<void> registrarVisitaEvento(int eventoId) async {
  final db = await database;
  final hoy = DateTime.now();
  
  // Buscar si ya hay registro de hoy para este evento
  final result = await db.rawQuery(
    'SELECT * FROM visitas_eventos WHERE eventoId = ? AND date(fecha) = date(?)',
    [eventoId, hoy.toIso8601String()],
  );
  
  if (result.isNotEmpty) {
    // Actualizar registro existente
    await db.rawUpdate(
      'UPDATE visitas_eventos SET cantidad = cantidad + 1 WHERE eventoId = ? AND date(fecha) = date(?)',
      [eventoId, hoy.toIso8601String()],
    );
  } else {
    // Crear nuevo registro
    await db.insert('visitas_eventos', {
      'eventoId': eventoId,
      'fecha': hoy.toIso8601String(),
      'cantidad': 1,
    });
  }
}

// Obtener total de visitas de un evento hoy
Future<int> obtenerVisitasEventoHoy(int eventoId) async {
  final db = await database;
  final hoy = DateTime.now();
  
  final result = await db.rawQuery(
    'SELECT SUM(cantidad) as total FROM visitas_eventos WHERE eventoId = ? AND date(fecha) = date(?)',
    [eventoId, hoy.toIso8601String()],
  );
  
  return result.first['total'] as int? ?? 0;
}

// Obtener total de visitas de un evento (todo el historial)
Future<int> obtenerTotalVisitasEvento(int eventoId) async {
  final db = await database;
  
  final result = await db.rawQuery(
    'SELECT SUM(cantidad) as total FROM visitas_eventos WHERE eventoId = ?',
    [eventoId],
  );
  
  return result.first['total'] as int? ?? 0;
}

// Obtener historial de visitas de un evento
Future<List<Map<String, dynamic>>> obtenerHistorialVisitasEvento(int eventoId) async {
  final db = await database;
  
  return await db.rawQuery('''
    SELECT date(fecha) as dia, SUM(cantidad) as total
    FROM visitas_eventos
    WHERE eventoId = ?
    GROUP BY date(fecha)
    ORDER BY fecha DESC
    LIMIT 30
  ''', [eventoId]);
}
}