import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';
import '../main.dart'; // Agregar este import

class CrearEncuestaScreen extends StatefulWidget {
  @override
  _CrearEncuestaScreenState createState() => _CrearEncuestaScreenState();
}

class _CrearEncuestaScreenState extends State<CrearEncuestaScreen> {
  final _formKey = GlobalKey<FormState>();
  final _tituloController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<_PreguntaData> _preguntas = [];

  void _agregarPregunta() {
    setState(() {
      _preguntas.add(_PreguntaData());
    });
  }

  void _eliminarPregunta(int index) {
    setState(() {
      // Limpiar controladores antes de eliminar
      _preguntas[index].textoController.dispose();
      _preguntas[index].opcionesController.dispose();
      _preguntas.removeAt(index);
    });
  }

  Future<void> _guardarEncuesta() async {
    // Validar título
    if (_tituloController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Ingresa un título para la encuesta')),
      );
      return;
    }

    // Validar que haya al menos una pregunta
    if (_preguntas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('⚠️ Agrega al menos una pregunta')),
      );
      return;
    }

    // Validar preguntas
    bool hayErrores = false;
    for (int i = 0; i < _preguntas.length; i++) {
      final pregunta = _preguntas[i];
      
      if (pregunta.textoController.text.isEmpty) {
        hayErrores = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ La pregunta ${i + 1} no tiene texto')),
        );
        break;
      }

      if (pregunta.tipoSeleccionado == 'opcion_multiple' && 
          pregunta.opcionesController.text.isEmpty) {
        hayErrores = true;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('⚠️ La pregunta ${i + 1} de opción múltiple necesita opciones')),
        );
        break;
      }
    }

    if (hayErrores) return;

    // Crear lista de preguntas
    List<Pregunta> preguntas = [];
    
    for (var preguntaData in _preguntas) {
      Pregunta nuevaPregunta = Pregunta(
        texto: preguntaData.textoController.text,
        tipo: preguntaData.tipoSeleccionado,
        opciones: preguntaData.tipoSeleccionado == 'opcion_multiple'
            ? preguntaData.opcionesController.text
                .split(',')
                .map((e) => e.trim())
                .where((e) => e.isNotEmpty)
                .toList()
            : null,
      );
      
      preguntas.add(nuevaPregunta);
    }

    // Crear y guardar encuesta
    Encuesta encuesta = Encuesta(
      titulo: _tituloController.text,
      fechaCreacion: DateTime.now(),
      preguntas: preguntas,
    );

    try {
      await _dbHelper.insertarEncuesta(encuesta);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Encuesta creada exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void dispose() {
    _tituloController.dispose();
    // Limpiar todos los controladores
    for (var pregunta in _preguntas) {
      pregunta.textoController.dispose();
      pregunta.opcionesController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Crear Encuesta'),
        backgroundColor: MyApp.primaryColor,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(16),
          children: [
            // Título de la encuesta
            TextFormField(
              controller: _tituloController,
              decoration: InputDecoration(
                labelText: 'Título de la encuesta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: Icon(Icons.title),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              style: TextStyle(fontSize: 16),
            ),
            
            SizedBox(height: 24),
            
            // Sección de preguntas
            Row(
              children: [
                Icon(Icons.question_answer, color: Colors.deepPurple),
                SizedBox(width: 8),
                Text(
                  'Preguntas',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                Spacer(),
                ElevatedButton.icon(
                  onPressed: _agregarPregunta,
                  icon: Icon(Icons.add, size: 20),
                  label: Text('Agregar'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.deepPurple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ],
            ),
            
            SizedBox(height: 16),
            
            // Lista de preguntas
            if (_preguntas.isEmpty)
              Card(
                color: Colors.grey[100],
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No hay preguntas. Toca "Agregar" para crear una.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ),
                ),
              )
            else
              ..._preguntas.asMap().entries.map((entry) {
                int index = entry.key;
                _PreguntaData preguntaData = entry.value;
                return _buildPreguntaWidget(index, preguntaData);
              }),
            
            SizedBox(height: 24),
            
            // Botón guardar
            ElevatedButton.icon(
              onPressed: _guardarEncuesta,
              icon: Icon(Icons.save),
              label: Text('Guardar Encuesta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreguntaWidget(int index, _PreguntaData preguntaData) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Encabezado de la pregunta
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: MyApp.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Pregunta ${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.deepPurple,
                    ),
                  ),
                ),
                Spacer(),
                IconButton(
                  icon: Icon(Icons.delete_forever, color: Colors.red),
                  onPressed: () => _eliminarPregunta(index),
                  tooltip: 'Eliminar pregunta',
                ),
              ],
            ),
            
            SizedBox(height: 12),
            
            // Campo de texto de la pregunta
            TextFormField(
              controller: preguntaData.textoController,
              decoration: InputDecoration(
                labelText: 'Escribe la pregunta',
                hintText: '¿Qué te gustaría preguntar?',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(Icons.help_outline),
              ),
              maxLines: 2,
              minLines: 1,
            ),
            
            SizedBox(height: 12),
            
            // Selector de tipo de respuesta
           // En el DropdownButtonFormField, cambia los items:
            DropdownButtonFormField<String>(
              value: preguntaData.tipoSeleccionado,
              decoration: InputDecoration(
                labelText: 'Tipo de respuesta',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: Icon(_getIconForType(preguntaData.tipoSeleccionado)),
              ),
              items: [
                DropdownMenuItem(
                  value: 'texto',
                  child: Row(
                    children: [
                      Icon(Icons.text_fields, size: 20),
                      SizedBox(width: 8),
                      Text('Texto libre'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'numero',  // NUEVO
                  child: Row(
                    children: [
                      Icon(Icons.numbers, size: 20),
                      SizedBox(width: 8),
                      Text('Numérico'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'telefono',  // NUEVO
                  child: Row(
                    children: [
                      Icon(Icons.phone, size: 20),
                      SizedBox(width: 8),
                      Text('Teléfono'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'email',  // NUEVO
                  child: Row(
                    children: [
                      Icon(Icons.email, size: 20),
                      SizedBox(width: 8),
                      Text('Correo electrónico'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'si_no',
                  child: Row(
                    children: [
                      Icon(Icons.thumbs_up_down, size: 20),
                      SizedBox(width: 8),
                      Text('Sí/No'),
                    ],
                  ),
                ),
                DropdownMenuItem(
                  value: 'opcion_multiple',
                  child: Row(
                    children: [
                      Icon(Icons.list_alt, size: 20),
                      SizedBox(width: 8),
                      Text('Opción múltiple'),
                    ],
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() {
                  preguntaData.tipoSeleccionado = value!;
                  if (value != 'opcion_multiple') {
                    preguntaData.opcionesController.clear();
                  }
                });
              },
            ),
            // Campo de opciones (solo visible para opción múltiple)
            if (preguntaData.tipoSeleccionado == 'opcion_multiple') ...[
              SizedBox(height: 12),
              TextFormField(
                controller: preguntaData.opcionesController,
                decoration: InputDecoration(
                  labelText: 'Opciones (separadas por coma)',
                  hintText: 'Ej: Opción 1, Opción 2, Opción 3',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: Icon(Icons.list),
                  helperText: 'Escribe las opciones separadas por comas',
                ),
              ),
            ],
            
            // Vista previa del tipo seleccionado
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, size: 16, color: Colors.blue[700]),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _getTypeDescription(preguntaData.tipoSeleccionado),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

      IconData _getIconForType(String type) {
        switch (type) {
          case 'texto':
            return Icons.text_fields;
          case 'numero':
            return Icons.numbers;
          case 'telefono':
            return Icons.phone;
          case 'email':
            return Icons.email;
          case 'si_no':
            return Icons.thumbs_up_down;
          case 'opcion_multiple':
            return Icons.list_alt;
          default:
            return Icons.help;
        }
      }

      String _getTypeDescription(String type) {
        switch (type) {
          case 'texto':
            return 'El usuario podrá escribir una respuesta libre';
          case 'numero':
            return 'Solo se permiten valores numéricos';
          case 'telefono':
            return 'Se validará formato de número telefónico';
          case 'email':
            return 'Se validará formato de correo electrónico';
          case 'si_no':
            return 'El usuario elegirá entre Sí o No';
          case 'opcion_multiple':
            return 'El usuario seleccionará una de las opciones';
          default:
            return '';
        }
      }
}

// Clase para manejar los datos de cada pregunta
class _PreguntaData {
  TextEditingController textoController = TextEditingController();
  TextEditingController opcionesController = TextEditingController();
  String tipoSeleccionado = 'texto';
}