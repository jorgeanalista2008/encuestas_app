import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';
import '../main.dart';

class ResponderEncuestaScreen extends StatefulWidget {
  final Encuesta encuesta;
  final String nombreUsuario;

  ResponderEncuestaScreen({
    required this.encuesta,
    required this.nombreUsuario,
  });

  @override
  _ResponderEncuestaScreenState createState() => _ResponderEncuestaScreenState();
}

class _ResponderEncuestaScreenState extends State<ResponderEncuestaScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final _formKey = GlobalKey<FormState>();
  
  Map<int, String> _respuestas = {};
  Map<int, TextEditingController> _textControllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    
    for (var pregunta in widget.encuesta.preguntas) {
      if (pregunta.tipo == 'texto') {
        _textControllers[pregunta.id!] = TextEditingController();
      }
    }
  }

  Future<void> _guardarRespuestas() async {
    // Verificar que todas las preguntas tengan respuesta
    bool todasRespondidas = true;
    List<int> preguntasSinResponder = [];

    for (var pregunta in widget.encuesta.preguntas) {
      String? respuesta;
      
      if (pregunta.tipo == 'texto') {
        respuesta = _textControllers[pregunta.id!]?.text;
      } else {
        respuesta = _respuestas[pregunta.id!];
      }
      
      if (respuesta == null || respuesta.isEmpty) {
        todasRespondidas = false;
        preguntasSinResponder.add(pregunta.id!);
      }
    }

    if (!todasRespondidas) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('⚠️ Por favor responde todas las preguntas'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      // Preparar respuestas para guardar
      Map<int, String> respuestasParaGuardar = {};
      
      for (var pregunta in widget.encuesta.preguntas) {
        String? respuesta;
        
        if (pregunta.tipo == 'texto') {
          respuesta = _textControllers[pregunta.id!]?.text;
        } else {
          respuesta = _respuestas[pregunta.id!];
        }
        
        if (respuesta != null && respuesta.isNotEmpty) {
          respuestasParaGuardar[pregunta.id!] = respuesta;
        }
      }

      // Guardar usando el nuevo método
      await _dbHelper.guardarRespuestasUsuario(
        encuestaId: widget.encuesta.id!,
        nombreUsuario: widget.nombreUsuario,
        respuestas: respuestasParaGuardar,
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Respuestas guardadas exitosamente'),
          backgroundColor: Colors.green,
        ),
      );

      // Regresar a la pantalla principal
      Navigator.of(context).popUntil((route) => route.isFirst);
      
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Error al guardar: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
        title: 'Respondiendo',
        actions: [
          // Mostrar usuario actual
          Center(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 8),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.person, size: 16, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      widget.nombreUsuario,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Información de la encuesta
          Container(
            width: double.infinity,
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [MyApp.primaryColor, MyApp.secondaryColor],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.encuesta.titulo,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '${widget.encuesta.preguntas.length} preguntas • Respondiendo como: ${widget.nombreUsuario}',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          
          // Lista de preguntas
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: widget.encuesta.preguntas.length,
                itemBuilder: (context, index) {
                  final pregunta = widget.encuesta.preguntas[index];
                  return _buildPreguntaCard(pregunta, index);
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.3),
              blurRadius: 5,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: ElevatedButton.icon(
          onPressed: _isSaving ? null : _guardarRespuestas,
          icon: _isSaving 
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.save),
          label: Text(_isSaving ? 'Guardando...' : 'Guardar Respuestas'),
          style: ElevatedButton.styleFrom(
            minimumSize: Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPreguntaCard(Pregunta pregunta, int index) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: MyApp.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${index + 1}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: MyApp.primaryColor,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pregunta.texto,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildRespuestaWidget(pregunta),
          ],
        ),
      ),
    );
  }

  Widget _buildRespuestaWidget(Pregunta pregunta) {
    switch (pregunta.tipo) {
      case 'texto':
        return TextFormField(
          controller: _textControllers[pregunta.id!],
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Escribe tu respuesta...',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.edit, color: MyApp.primaryColor),
          ),
        );
      
      case 'si_no':
        return Column(
          children: [
            RadioListTile<String>(
              title: Text('Sí'),
              value: 'Sí',
              groupValue: _respuestas[pregunta.id!],
              onChanged: (value) {
                setState(() {
                  _respuestas[pregunta.id!] = value!;
                });
              },
              activeColor: MyApp.primaryColor,
            ),
            RadioListTile<String>(
              title: Text('No'),
              value: 'No',
              groupValue: _respuestas[pregunta.id!],
              onChanged: (value) {
                setState(() {
                  _respuestas[pregunta.id!] = value!;
                });
              },
              activeColor: MyApp.primaryColor,
            ),
          ],
        );
      
      case 'opcion_multiple':
        return DropdownButtonFormField<String>(
          value: _respuestas[pregunta.id!],
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixIcon: Icon(Icons.list, color: MyApp.primaryColor),
            hintText: 'Selecciona una opción',
          ),
          items: pregunta.opciones?.map((opcion) {
            return DropdownMenuItem(
              value: opcion,
              child: Text(opcion),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _respuestas[pregunta.id!] = value!;
            });
          },
        );
      
      default:
        return Container();
    }
  }

  @override
  void dispose() {
    _textControllers.forEach((key, controller) {
      controller.dispose();
    });
    super.dispose();
  }
}