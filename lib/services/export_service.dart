import 'dart:io';
import 'package:flutter/material.dart';  // ← FALTABA ESTE
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';

class ExportService {
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // Exportar todas las encuestas y sus preguntas
  Future<String> _generarCSVEncuestas() async {
    List<List<String>> rows = [];
    
    // Encabezados
    rows.add([
      'TIPO',
      'ID Encuesta',
      'Título Encuesta',
      'Fecha Creación',
      'ID Pregunta',
      'Texto Pregunta',
      'Tipo Pregunta',
      'Opciones',
      'Usuario',
      'Respuesta',
      'Fecha Respuesta',
    ]);

    // Obtener todas las encuestas
    final encuestas = await _dbHelper.obtenerEncuestas();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var encuesta in encuestas) {
      // Obtener respuestas agrupadas
      final respuestasAgrupadas = await _dbHelper.obtenerRespuestasAgrupadas(encuesta.id!);

      if (respuestasAgrupadas.isEmpty) {
        // Si no hay respuestas, solo mostrar la encuesta y preguntas
        for (var pregunta in encuesta.preguntas) {
          rows.add([
            'ENCUESTA',
            encuesta.id.toString(),
            encuesta.titulo,
            dateFormat.format(encuesta.fechaCreacion),
            pregunta.id.toString(),
            pregunta.texto,
            pregunta.tipo,
            pregunta.opciones?.join(' | ') ?? 'N/A',
            'Sin respuestas',
            'N/A',
            'N/A',
          ]);
        }
      } else {
        // Mostrar respuestas por usuario
        for (var respuestaAgrupada in respuestasAgrupadas) {
          for (var respuesta in respuestaAgrupada.respuestas) {
            // Encontrar la pregunta correspondiente
            final pregunta = encuesta.preguntas.firstWhere(
              (p) => p.id == respuesta.preguntaId,
              orElse: () => Pregunta(
                texto: 'Pregunta no encontrada',
                tipo: 'desconocido',
              ),
            );

            rows.add([
              'RESPUESTA',
              encuesta.id.toString(),
              encuesta.titulo,
              dateFormat.format(encuesta.fechaCreacion),
              pregunta.id?.toString() ?? 'N/A',
              pregunta.texto,
              pregunta.tipo,
              pregunta.opciones?.join(' | ') ?? 'N/A',
              respuestaAgrupada.nombreUsuario,
              respuesta.respuesta,
              dateFormat.format(respuestaAgrupada.fechaRespuesta),
            ]);
          }
        }
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  // Exportar solo estadísticas de encuestas
  Future<String> _generarCSVEstadisticas() async {
    List<List<String>> rows = [];
    
    rows.add([
      'ID Encuesta',
      'Título',
      'Fecha Creación',
      'Total Preguntas',
      'Total Usuarios',
      'Total Respuestas',
      'Tasa de Respuesta (%)',
    ]);

    final encuestas = await _dbHelper.obtenerEncuestas();
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

    for (var encuesta in encuestas) {
      final totalUsuarios = await _dbHelper.obtenerNumeroUsuarios(encuesta.id!);
      final totalRespuestas = await _dbHelper.obtenerTotalRespuestas(encuesta.id!);
      final totalPreguntas = encuesta.preguntas.length;
      
      double tasaRespuesta = totalUsuarios > 0 && totalPreguntas > 0
          ? (totalRespuestas / (totalUsuarios * totalPreguntas)) * 100
          : 0.0;

      rows.add([
        encuesta.id.toString(),
        encuesta.titulo,
        dateFormat.format(encuesta.fechaCreacion),
        totalPreguntas.toString(),
        totalUsuarios.toString(),
        totalRespuestas.toString(),
        tasaRespuesta.toStringAsFixed(1),
      ]);
    }

    return const ListToCsvConverter().convert(rows);
  }

  // Exportar respuestas por usuario específico
  Future<String> _generarCSVPorUsuario(int encuestaId, String nombreUsuario) async {
    List<List<String>> rows = [];
    
    rows.add([
      'Usuario',
      'ID Encuesta',
      'Título Encuesta',
      'Pregunta',
      'Tipo Pregunta',
      'Respuesta',
      'Fecha Respuesta',
    ]);

    final encuestas = await _dbHelper.obtenerEncuestas();
    final encuesta = encuestas.firstWhere((e) => e.id == encuestaId);
    final dateFormat = DateFormat('dd/MM/yyyy HH:mm');
    
    final respuestasAgrupadas = await _dbHelper.obtenerRespuestasAgrupadas(encuestaId);
    final respuestasUsuario = respuestasAgrupadas
        .where((r) => r.nombreUsuario.toLowerCase() == nombreUsuario.toLowerCase())
        .toList();

    for (var respuestaAgrupada in respuestasUsuario) {
      for (var respuesta in respuestaAgrupada.respuestas) {
        final pregunta = encuesta.preguntas.firstWhere(
          (p) => p.id == respuesta.preguntaId,
          orElse: () => Pregunta(texto: 'N/A', tipo: 'desconocido'),
        );

        rows.add([
          respuestaAgrupada.nombreUsuario,
          encuesta.id.toString(),
          encuesta.titulo,
          pregunta.texto,
          pregunta.tipo,
          respuesta.respuesta,
          dateFormat.format(respuestaAgrupada.fechaRespuesta),
        ]);
      }
    }

    return const ListToCsvConverter().convert(rows);
  }

  // Guardar archivo CSV
  Future<File> _guardarCSV(String csvContent, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final path = '${directory.path}/$fileName';
    final file = File(path);
    return await file.writeAsString(csvContent);
  }

  // Exportar y compartir archivo
  Future<void> exportarYCompartir({
    required BuildContext context,
    required String tipo,
    int? encuestaId,
    String? nombreUsuario,
  }) async {
    try {
      String csvContent;
      String fileName;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      switch (tipo) {
        case 'completo':
          csvContent = await _generarCSVEncuestas();
          fileName = 'encuestas_completas_$timestamp.csv';
          break;
        case 'estadisticas':
          csvContent = await _generarCSVEstadisticas();
          fileName = 'estadisticas_$timestamp.csv';
          break;
        case 'usuario':
          if (encuestaId == null || nombreUsuario == null) {
            throw Exception('Faltan datos del usuario');
          }
          csvContent = await _generarCSVPorUsuario(encuestaId, nombreUsuario);
          fileName = 'respuestas_${nombreUsuario}_$timestamp.csv';
          break;
        default:
          throw Exception('Tipo de exportación no válido');
      }

      // Guardar archivo
      final file = await _guardarCSV(csvContent, fileName);

      // Compartir archivo
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Exportación de encuestas',
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Archivo exportado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Exportar solo guardando (sin compartir)
  Future<String?> exportarAGuardar({
    required BuildContext context,
    required String tipo,
    int? encuestaId,
    String? nombreUsuario,
  }) async {
    try {
      String csvContent;
      String fileName;
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());

      switch (tipo) {
        case 'completo':
          csvContent = await _generarCSVEncuestas();
          fileName = 'encuestas_completas_$timestamp.csv';
          break;
        case 'estadisticas':
          csvContent = await _generarCSVEstadisticas();
          fileName = 'estadisticas_$timestamp.csv';
          break;
        case 'usuario':
          if (encuestaId == null || nombreUsuario == null) {
            throw Exception('Faltan datos del usuario');
          }
          csvContent = await _generarCSVPorUsuario(encuestaId, nombreUsuario);
          fileName = 'respuestas_${nombreUsuario}_$timestamp.csv';
          break;
        default:
          throw Exception('Tipo de exportación no válido');
      }

      // Guardar archivo
      final file = await _guardarCSV(csvContent, fileName);
      
      return file.path;
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al exportar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return null;
    }
  }
}