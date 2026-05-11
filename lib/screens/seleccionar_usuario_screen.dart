import 'package:flutter/material.dart';
import '../main.dart';
import 'responder_encuesta_screen.dart';
import '../models/encuesta_model.dart';

class SeleccionarUsuarioScreen extends StatefulWidget {
  final Encuesta encuesta;

  const SeleccionarUsuarioScreen({Key? key, required this.encuesta}) : super(key: key);

  @override
  _SeleccionarUsuarioScreenState createState() => _SeleccionarUsuarioScreenState();
}

class _SeleccionarUsuarioScreenState extends State<SeleccionarUsuarioScreen> {
  final _nombreController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _nombreController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
        title: 'Responder Encuesta',
      ),
      body: Form(
        key: _formKey,
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icono
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: MyApp.accentColor,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    size: 50,
                    color: MyApp.primaryColor,
                  ),
                ),
                
                SizedBox(height: 32),
                
                // Título
                Text(
                  'Identificación del Usuario',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: MyApp.primaryColor,
                  ),
                ),
                
                SizedBox(height: 8),
                
                // Subtítulo
                Text(
                  'Ingresa tu nombre para responder la encuesta',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
                
                SizedBox(height: 32),
                
                // Campo de nombre
                TextFormField(
                  controller: _nombreController,
                  decoration: InputDecoration(
                    labelText: 'Nombre completo',
                    hintText: 'Ej: Juan Pérez',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor ingresa tu nombre';
                    }
                    if (value.trim().length < 3) {
                      return 'El nombre debe tener al menos 3 caracteres';
                    }
                    return null;
                  },
                  textCapitalization: TextCapitalization.words,
                ),
                
                SizedBox(height: 32),
                
                // Botón para continuar
                ElevatedButton.icon(
                  onPressed: () {
                    if (_formKey.currentState!.validate()) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ResponderEncuestaScreen(
                            encuesta: widget.encuesta,
                            nombreUsuario: _nombreController.text.trim(),
                          ),
                        ),
                      );
                    }
                  },
                  icon: Icon(Icons.arrow_forward),
                  label: Text('Comenzar Encuesta'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: Size(double.infinity, 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}