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
      // Crear controlador para tipos que usan texto
      if (pregunta.tipo == 'texto' || pregunta.tipo == 'numero' || 
          pregunta.tipo == 'telefono' || pregunta.tipo == 'email') {
        _textControllers[pregunta.id!] = TextEditingController();
      }
    }
  }
    Future<void> _guardarRespuestas() async {
      // Verificar que todas las preguntas tengan respuesta
      bool todasRespondidas = true;
      List<String> errores = [];
      List<int> preguntasSinResponder = [];

      for (var pregunta in widget.encuesta.preguntas) {
        String? respuesta;
        
        // Obtener respuesta según el tipo de pregunta
        if (pregunta.tipo == 'texto' || pregunta.tipo == 'numero' || 
            pregunta.tipo == 'telefono' || pregunta.tipo == 'email') {
          respuesta = _textControllers[pregunta.id!]?.text?.trim();
        } else {
          respuesta = _respuestas[pregunta.id!];
        }
        
        // Verificar si está vacía
        if (respuesta == null || respuesta.isEmpty) {
          todasRespondidas = false;
          preguntasSinResponder.add(pregunta.id!);
        }
        
        // Validaciones específicas para cada tipo
        if (respuesta != null && respuesta.isNotEmpty) {
          if (pregunta.tipo == 'numero') {
            if (double.tryParse(respuesta) == null) {
              errores.add('"${pregunta.texto}" debe ser un valor numérico');
              todasRespondidas = false;
            }
          } else if (pregunta.tipo == 'email') {
            final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
            if (!emailRegex.hasMatch(respuesta)) {
              errores.add('"${pregunta.texto}" debe ser un email válido');
              todasRespondidas = false;
            }
          }
        }
      }

      // Si hay errores, mostrar mensaje
      if (!todasRespondidas) {
        String mensaje;
        if (errores.isNotEmpty) {
          mensaje = errores.join('\n');
        } else {
          mensaje = '⚠️ Por favor responde todas las preguntas (${preguntasSinResponder.length} pendientes)';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(mensaje),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        return;
      }

      // Si todo está bien, guardar
      setState(() => _isSaving = true);

      try {
        // Preparar respuestas para guardar
        Map<int, String> respuestasParaGuardar = {};
        
        for (var pregunta in widget.encuesta.preguntas) {
          String? respuesta;
          
          if (pregunta.tipo == 'texto' || pregunta.tipo == 'numero' || 
              pregunta.tipo == 'telefono' || pregunta.tipo == 'email') {
            respuesta = _textControllers[pregunta.id!]?.text?.trim();
          } else {
            respuesta = _respuestas[pregunta.id!];
          }
          
          if (respuesta != null && respuesta.isNotEmpty) {
            respuestasParaGuardar[pregunta.id!] = respuesta;
          }
        }

        // Guardar usando el método del helper
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
        print('Error al guardar: $e');
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
      print('🔍 Construyendo widget para pregunta ID: ${pregunta.id}, Tipo: ${pregunta.tipo}');
      
      switch (pregunta.tipo) {
        case 'texto':
          print('📝 Mostrando campo de texto');
          return TextFormField(
            controller: _textControllers[pregunta.id!],
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta aquí...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.edit, color: MyApp.primaryColor),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _respuestas[pregunta.id!] = value;
                } else {
                  _respuestas.remove(pregunta.id!);
                }
              });
            },
          );
        
        case 'numero':
          print('🔢 Mostrando campo numérico');
          return TextFormField(
            controller: _textControllers[pregunta.id!],
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'Ingresa un número...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.numbers, color: MyApp.primaryColor),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                if (double.tryParse(value) == null) {
                  return 'Ingresa un valor numérico válido';
                }
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _respuestas[pregunta.id!] = value;
                } else {
                  _respuestas.remove(pregunta.id!);
                }
              });
            },
          );
        
        case 'telefono':
          print('📱 Mostrando campo de teléfono');
          return TextFormField(
            controller: _textControllers[pregunta.id!],
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              hintText: 'Ej: +58 412 1234567',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.phone, color: MyApp.primaryColor),
              filled: true,
              fillColor: Colors.grey[50],
              helperText: 'Ingresa un número de teléfono válido',
              helperMaxLines: 1,
            ),
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _respuestas[pregunta.id!] = value;
                } else {
                  _respuestas.remove(pregunta.id!);
                }
              });
            },
          );
        
        case 'email':
          print('📧 Mostrando campo de email');
          return TextFormField(
            controller: _textControllers[pregunta.id!],
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: 'Ej: usuario@correo.com',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.email, color: MyApp.primaryColor),
              filled: true,
              fillColor: Colors.grey[50],
              helperText: 'Ingresa un correo electrónico válido',
              helperMaxLines: 1,
            ),
            validator: (value) {
              if (value != null && value.isNotEmpty) {
                final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                if (!emailRegex.hasMatch(value)) {
                  return 'Ingresa un correo electrónico válido';
                }
              }
              return null;
            },
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _respuestas[pregunta.id!] = value;
                } else {
                  _respuestas.remove(pregunta.id!);
                }
              });
            },
          );
        
        case 'si_no':
          print('✅ Mostrando opciones Sí/No');
          return Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green),
                          SizedBox(width: 8),
                          Text('Sí'),
                        ],
                      ),
                      value: 'Sí',
                      groupValue: _respuestas[pregunta.id!],
                      onChanged: (value) {
                        setState(() {
                          _respuestas[pregunta.id!] = value!;
                        });
                      },
                      activeColor: Colors.green,
                    ),
                    Divider(height: 1),
                    RadioListTile<String>(
                      title: Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Colors.red),
                          SizedBox(width: 8),
                          Text('No'),
                        ],
                      ),
                      value: 'No',
                      groupValue: _respuestas[pregunta.id!],
                      onChanged: (value) {
                        setState(() {
                          _respuestas[pregunta.id!] = value!;
                        });
                      },
                      activeColor: Colors.red,
                    ),
                  ],
                ),
              ),
            ],
          );
        
        case 'opcion_multiple':
          print('🔢 Mostrando opciones múltiples: ${pregunta.opciones}');
          if (pregunta.opciones == null || pregunta.opciones!.isEmpty) {
            return Text(
              'No hay opciones disponibles',
              style: TextStyle(color: Colors.red),
            );
          }
          
          return Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: DropdownButtonFormField<String>(
              value: _respuestas[pregunta.id!],
              decoration: InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                prefixIcon: Icon(Icons.arrow_drop_down_circle, color: MyApp.primaryColor),
                hintText: 'Selecciona una opción',
              ),
              items: pregunta.opciones!.map((opcion) {
                return DropdownMenuItem(
                  value: opcion,
                  child: Text(
                    opcion,
                    style: TextStyle(fontSize: 16),
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _respuestas[pregunta.id!] = value!;
                });
              },
              icon: Icon(Icons.expand_more),
            ),
          );
        
        default:
          print('❌ Tipo de pregunta no reconocido: ${pregunta.tipo}');
          // Por defecto, mostrar campo de texto
          return TextFormField(
            controller: _textControllers[pregunta.id!],
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Escribe tu respuesta aquí...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: Icon(Icons.edit, color: MyApp.primaryColor),
            ),
            onChanged: (value) {
              setState(() {
                if (value.isNotEmpty) {
                  _respuestas[pregunta.id!] = value;
                } else {
                  _respuestas.remove(pregunta.id!);
                }
              });
            },
          );
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