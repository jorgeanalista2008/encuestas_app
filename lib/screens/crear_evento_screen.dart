import 'package:flutter/material.dart';
import '../main.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';

class CrearEventoScreen extends StatefulWidget {
  @override
  _CrearEventoScreenState createState() => _CrearEventoScreenState();
}

class _CrearEventoScreenState extends State<CrearEventoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _descripcionController = TextEditingController();
  final _ubicacionController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  DateTime? _fechaEvento;
  bool _isLoading = false;

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(primary: MyApp.primaryColor),
          ),
          child: child!,
        );
      },
    );
    
    if (fecha != null) {
      setState(() => _fechaEvento = fecha);
    }
  }

  Future<void> _crearEvento() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      
      try {
        final evento = Evento(
          nombre: _nombreController.text.trim(),
          descripcion: _descripcionController.text.trim().isNotEmpty 
              ? _descripcionController.text.trim() 
              : null,
          ubicacion: _ubicacionController.text.trim().isNotEmpty 
              ? _ubicacionController.text.trim() 
              : null,
          fechaCreacion: DateTime.now(),
          fechaEvento: _fechaEvento,
          activo: true,
        );
        
        await _dbHelper.crearEvento(evento);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ Evento creado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error al crear evento'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(title: 'Crear Evento'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: EdgeInsets.all(20),
          children: [
            // Nombre del evento
            TextFormField(
              controller: _nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del evento *',
                hintText: 'Ej: Feria Tecnológica 2024',
                prefixIcon: Icon(Icons.event),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'El nombre es obligatorio';
                }
                return null;
              },
            ),
            
            SizedBox(height: 16),
            
            // Descripción
            TextFormField(
              controller: _descripcionController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText: 'Descripción',
                hintText: 'Describe brevemente el evento...',
                prefixIcon: Icon(Icons.description),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Ubicación
            TextFormField(
              controller: _ubicacionController,
              decoration: InputDecoration(
                labelText: 'Ubicación',
                hintText: 'Ej: Stand #15, Pabellón Central',
                prefixIcon: Icon(Icons.location_on),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            
            SizedBox(height: 16),
            
            // Fecha del evento
            InkWell(
              onTap: _seleccionarFecha,
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Fecha del evento',
                  prefixIcon: Icon(Icons.calendar_today),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  _fechaEvento != null 
                      ? '${_fechaEvento!.day}/${_fechaEvento!.month}/${_fechaEvento!.year}'
                      : 'Seleccionar fecha',
                  style: TextStyle(
                    color: _fechaEvento != null ? Colors.black : Colors.grey,
                  ),
                ),
              ),
            ),
            
            SizedBox(height: 32),
            
            // Botón crear
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _crearEvento,
              icon: _isLoading 
                  ? SizedBox(
                      width: 20, height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : Icon(Icons.check),
              label: Text(_isLoading ? 'Creando...' : 'Crear Evento'),
              style: ElevatedButton.styleFrom(
                minimumSize: Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _descripcionController.dispose();
    _ubicacionController.dispose();
    super.dispose();
  }
}