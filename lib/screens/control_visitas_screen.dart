import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';

class ControlVisitasScreen extends StatefulWidget {
  final Evento evento;

  const ControlVisitasScreen({Key? key, required this.evento}) : super(key: key);

  @override
  _ControlVisitasScreenState createState() => _ControlVisitasScreenState();
}

class _ControlVisitasScreenState extends State<ControlVisitasScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  int _visitasHoy = 0;
  int _visitasTotales = 0;
  List<Map<String, dynamic>> _historial = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final hoy = await _dbHelper.obtenerVisitasEventoHoy(widget.evento.id!);
      final totales = await _dbHelper.obtenerTotalVisitasEvento(widget.evento.id!);
      final historial = await _dbHelper.obtenerHistorialVisitasEvento(widget.evento.id!);
      
      setState(() {
        _visitasHoy = hoy;
        _visitasTotales = totales;
        _historial = historial;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _incrementarVisita() async {
    await _dbHelper.registrarVisitaEvento(widget.evento.id!);
    _cargarDatos();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.person_add, color: Colors.white),
            SizedBox(width: 8),
            Text('¡Visita registrada en ${widget.evento.nombre}!'),
          ],
        ),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
        title: widget.evento.nombre,
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MyApp.primaryColor))
          : ListView(
              padding: EdgeInsets.all(20),
              children: [
                // Información del evento
                _buildInfoEvento(),
                
                SizedBox(height: 20),
                
                // Contador HOY
                _buildContadorHoy(),
                
                SizedBox(height: 15),
                
                // Total acumulado
                _buildTotalAcumulado(),
                
                SizedBox(height: 30),
                
                // Botón de registrar visita
                _buildBotonVisita(),
                
                SizedBox(height: 30),
                
                // Historial
                if (_historial.isNotEmpty) _buildHistorial(),
              ],
            ),
    );
  }

  Widget _buildInfoEvento() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyApp.accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyApp.primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.event, color: MyApp.primaryColor, size: 24),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.evento.nombre, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                if (widget.evento.ubicacion != null)
                  Text('📍 ${widget.evento.ubicacion}', style: TextStyle(fontSize: 13, color: Colors.grey[700])),
                if (widget.evento.fechaEvento != null)
                  Text('📅 ${DateFormat('dd/MM/yyyy').format(widget.evento.fechaEvento!)}', 
                    style: TextStyle(fontSize: 13, color: Colors.grey[700])),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContadorHoy() {
    return Container(
      padding: EdgeInsets.all(25),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyApp.primaryColor, MyApp.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: MyApp.primaryColor.withOpacity(0.4),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'VISITAS HOY',
            style: TextStyle(color: Colors.white70, fontSize: 14, letterSpacing: 3),
          ),
          SizedBox(height: 10),
          Text(
            _visitasHoy.toString(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            DateFormat('EEEE d \'de\' MMMM', 'es').format(DateTime.now()),
            style: TextStyle(color: Colors.white70, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalAcumulado() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 5, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.summarize, color: MyApp.primaryColor),
          SizedBox(width: 8),
          Text('Total acumulado: ', style: TextStyle(color: Colors.grey[600], fontSize: 15)),
          Text(
            _visitasTotales.toString(),
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: MyApp.primaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBotonVisita() {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.green.withOpacity(0.3), blurRadius: 15, offset: Offset(0, 8)),
        ],
      ),
      child: ElevatedButton(
        onPressed: _incrementarVisita,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 0,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, size: 40),
            SizedBox(width: 15),
            Text(
              'REGISTRAR VISITA',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHistorial() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('📋 Historial', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800])),
        SizedBox(height: 12),
        ..._historial.map((item) {
          final fecha = DateTime.parse(item['dia']);
          final total = item['total'] as int;
          return Card(
            margin: EdgeInsets.only(bottom: 6),
            child: ListTile(
              leading: Icon(Icons.calendar_today, color: MyApp.primaryColor),
              title: Text(DateFormat('EEEE d \'de\' MMMM', 'es').format(fecha)),
              trailing: Text('$total', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            ),
          );
        }).toList(),
      ],
    );
  }
}