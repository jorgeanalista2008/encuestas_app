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