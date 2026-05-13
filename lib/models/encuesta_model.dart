class Encuesta {
  int? id;
  String titulo;
  DateTime fechaCreacion;
  List<Pregunta> preguntas;

  Encuesta({
    this.id,
    required this.titulo,
    required this.fechaCreacion,
    required this.preguntas,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'titulo': titulo,
      'fechaCreacion': fechaCreacion.toIso8601String(),
    };
  }

  factory Encuesta.fromMap(Map<String, dynamic> map) {
    return Encuesta(
      id: map['id'],
      titulo: map['titulo'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      preguntas: [],
    );
  }
}

class Pregunta {
  int? id;
  int? encuestaId;
  String texto;
  String tipo; // 'texto', 'opcion_multiple', 'si_no'
  List<String>? opciones;
  String? respuesta; // Mantenemos para compatibilidad

  Pregunta({
    this.id,
    this.encuestaId,
    required this.texto,
    required this.tipo,
    this.opciones,
    this.respuesta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encuestaId': encuestaId,
      'texto': texto,
      'tipo': tipo,
      'opciones': opciones?.join(','),
      'respuesta': respuesta,
    };
  }

  factory Pregunta.fromMap(Map<String, dynamic> map) {
    return Pregunta(
      id: map['id'],
      encuestaId: map['encuestaId'],
      texto: map['texto'],
      tipo: map['tipo'],
      opciones: map['opciones'] != null && map['opciones'].toString().isNotEmpty
          ? map['opciones'].toString().split(',')
          : null,
      respuesta: map['respuesta'],
    );
  }
}

// NUEVO: Modelo para respuestas de usuarios
class RespuestaUsuario {
  int? id;
  int encuestaId;
  int preguntaId;
  String respuesta;
  String nombreUsuario;
  DateTime fechaRespuesta;

  RespuestaUsuario({
    this.id,
    required this.encuestaId,
    required this.preguntaId,
    required this.respuesta,
    required this.nombreUsuario,
    required this.fechaRespuesta,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'encuestaId': encuestaId,
      'preguntaId': preguntaId,
      'respuesta': respuesta,
      'nombreUsuario': nombreUsuario,
      'fechaRespuesta': fechaRespuesta.toIso8601String(),
    };
  }

  factory RespuestaUsuario.fromMap(Map<String, dynamic> map) {
    return RespuestaUsuario(
      id: map['id'],
      encuestaId: map['encuestaId'],
      preguntaId: map['preguntaId'],
      respuesta: map['respuesta'],
      nombreUsuario: map['nombreUsuario'],
      fechaRespuesta: DateTime.parse(map['fechaRespuesta']),
    );
  }
}

// NUEVO: Modelo para agrupar respuestas por usuario
class RespuestaAgrupada {
  String nombreUsuario;
  DateTime fechaRespuesta;
  List<RespuestaUsuario> respuestas;

  RespuestaAgrupada({
    required this.nombreUsuario,
    required this.fechaRespuesta,
    required this.respuestas,
  });
}

// NUEVO: Modelo para control de visitas al stand
class VisitaStand {
  int? id;
  DateTime fechaEntrada;
  DateTime? fechaSalida;
  String? nombreVisitante;
  String? motivoVisita;
  String? observaciones;
  bool atendido;

  VisitaStand({
    this.id,
    required this.fechaEntrada,
    this.fechaSalida,
    this.nombreVisitante,
    this.motivoVisita,
    this.observaciones,
    this.atendido = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fechaEntrada': fechaEntrada.toIso8601String(),
      'fechaSalida': fechaSalida?.toIso8601String(),
      'nombreVisitante': nombreVisitante,
      'motivoVisita': motivoVisita,
      'observaciones': observaciones,
      'atendido': atendido ? 1 : 0,
    };
  }

  factory VisitaStand.fromMap(Map<String, dynamic> map) {
    return VisitaStand(
      id: map['id'],
      fechaEntrada: DateTime.parse(map['fechaEntrada']),
      fechaSalida: map['fechaSalida'] != null 
          ? DateTime.parse(map['fechaSalida']) 
          : null,
      nombreVisitante: map['nombreVisitante'],
      motivoVisita: map['motivoVisita'],
      observaciones: map['observaciones'],
      atendido: map['atendido'] == 1,
    );
  }
}

// Estadísticas del stand
class EstadisticasStand {
  int totalVisitas;
  int visitasAtendidas;
  int visitasPendientes;
  int visitasHoy;
  double tiempoPromedioAtencion; // en minutos
  List<String> motivosFrecuentes;

  EstadisticasStand({
    this.totalVisitas = 0,
    this.visitasAtendidas = 0,
    this.visitasPendientes = 0,
    this.visitasHoy = 0,
    this.tiempoPromedioAtencion = 0.0,
    this.motivosFrecuentes = const [],
  });
}
// MODELO PARA EVENTOS Y VISITAS
class Evento {
  int? id;
  String nombre;
  String? descripcion;
  String? ubicacion;
  DateTime fechaCreacion;
  DateTime? fechaEvento;
  bool activo;

  Evento({
    this.id,
    required this.nombre,
    this.descripcion,
    this.ubicacion,
    required this.fechaCreacion,
    this.fechaEvento,
    this.activo = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nombre': nombre,
      'descripcion': descripcion,
      'ubicacion': ubicacion,
      'fechaCreacion': fechaCreacion.toIso8601String(),
      'fechaEvento': fechaEvento?.toIso8601String(),
      'activo': activo ? 1 : 0,
    };
  }

  factory Evento.fromMap(Map<String, dynamic> map) {
    return Evento(
      id: map['id'],
      nombre: map['nombre'],
      descripcion: map['descripcion'],
      ubicacion: map['ubicacion'],
      fechaCreacion: DateTime.parse(map['fechaCreacion']),
      fechaEvento: map['fechaEvento'] != null ? DateTime.parse(map['fechaEvento']) : null,
      activo: map['activo'] == 1,
    );
  }
}

class VisitaEvento {
  int? id;
  int eventoId;
  DateTime fecha;
  int cantidad;

  VisitaEvento({
    this.id,
    required this.eventoId,
    required this.fecha,
    this.cantidad = 1,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'eventoId': eventoId,
      'fecha': fecha.toIso8601String(),
      'cantidad': cantidad,
    };
  }

  factory VisitaEvento.fromMap(Map<String, dynamic> map) {
    return VisitaEvento(
      id: map['id'],
      eventoId: map['eventoId'],
      fecha: DateTime.parse(map['fecha']),
      cantidad: map['cantidad'] ?? 1,
    );
  }
}