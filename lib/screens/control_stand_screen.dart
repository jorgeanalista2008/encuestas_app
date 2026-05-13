import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';

class ControlStandScreen extends StatefulWidget {
  @override
  _ControlStandScreenState createState() => _ControlStandScreenState();
}

class _ControlStandScreenState extends State<ControlStandScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  EstadisticasStand? _estadisticas;
  List<VisitaStand> _visitasRecientes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final estadisticas = await _dbHelper.obtenerEstadisticasStand();
      final visitas = await _dbHelper.obtenerVisitas();
      setState(() {
        _estadisticas = estadisticas;
        _visitasRecientes = visitas.take(10).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _registrarEntrada() async {
    final visita = VisitaStand(
      fechaEntrada: DateTime.now(),
      atendido: false,
    );
    
    await _dbHelper.registrarVisita(visita);
    _cargarDatos();
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('✅ Entrada registrada - ${DateFormat('HH:mm').format(DateTime.now())}'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _marcarAtendido(VisitaStand visita) async {
    showDialog(
      context: context,
      builder: (ctx) => _buildAtencionDialog(visita),
    );
  }

  Widget _buildAtencionDialog(VisitaStand visita) {
    final nombreController = TextEditingController(text: visita.nombreVisitante);
    final motivoController = TextEditingController(text: visita.motivoVisita);
    final observacionesController = TextEditingController(text: visita.observaciones);
    
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.person_add, color: MyApp.primaryColor),
          SizedBox(width: 8),
          Text('Atender Visitante'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Entrada: ${DateFormat('HH:mm').format(visita.fechaEntrada)}',
              style: TextStyle(color: Colors.grey[600], fontSize: 14),
            ),
            SizedBox(height: 16),
            TextFormField(
              controller: nombreController,
              decoration: InputDecoration(
                labelText: 'Nombre del visitante',
                prefixIcon: Icon(Icons.person),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: motivoController,
              decoration: InputDecoration(
                labelText: 'Motivo de visita',
                prefixIcon: Icon(Icons.question_answer),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            SizedBox(height: 12),
            TextFormField(
              controller: observacionesController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: 'Observaciones',
                prefixIcon: Icon(Icons.notes),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('Cancelar'),
          onPressed: () => Navigator.pop(context),
        ),
        ElevatedButton(
          child: Text('Guardar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: MyApp.primaryColor,
          ),
          onPressed: () async {
            visita.nombreVisitante = nombreController.text;
            visita.motivoVisita = motivoController.text;
            visita.observaciones = observacionesController.text;
            visita.atendido = true;
            visita.fechaSalida = DateTime.now();
            
            await _dbHelper.actualizarVisita(visita);
            Navigator.pop(context);
            _cargarDatos();
            
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('✅ Visitante atendido'),
                backgroundColor: Colors.green,
              ),
            );
          },
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
        title: 'Control de Stand',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarDatos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MyApp.primaryColor))
          : RefreshIndicator(
              onRefresh: _cargarDatos,
              color: MyApp.primaryColor,
              child: ListView(
                padding: EdgeInsets.all(16),
                children: [
                  _buildEstadisticasCard(),
                  SizedBox(height: 16),
                  _buildBotonEntrada(),
                  SizedBox(height: 24),
                  _buildListaVisitas(),
                ],
              ),
            ),
    );
  }

  Widget _buildEstadisticasCard() {
    if (_estadisticas == null) return SizedBox();
    
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [MyApp.primaryColor, MyApp.secondaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: MyApp.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.traffic, color: Colors.white, size: 28),
              SizedBox(width: 8),
              Text(
                'Estadísticas del Stand',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem('Total', _estadisticas!.totalVisitas.toString(), Icons.people),
              _buildStatItem('Hoy', _estadisticas!.visitasHoy.toString(), Icons.today),
              _buildStatItem('Atendidos', _estadisticas!.visitasAtendidas.toString(), Icons.check_circle),
              _buildStatItem('Pendientes', _estadisticas!.visitasPendientes.toString(), Icons.pending),
            ],
          ),
          if (_estadisticas!.tiempoPromedioAtencion > 0) ...[
            SizedBox(height: 16),
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: Colors.white, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Tiempo promedio: ${_estadisticas!.tiempoPromedioAtencion.toStringAsFixed(1)} min',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: Colors.white.withOpacity(0.9), size: 28),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildBotonEntrada() {
    return Container(
      width: double.infinity,
      height: 80,
      child: ElevatedButton.icon(
        onPressed: _registrarEntrada,
        icon: Icon(Icons.login, size: 30),
        label: Text(
          'REGISTRAR NUEVA ENTRADA',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 2),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 5,
        ),
      ),
    );
  }

  Widget _buildListaVisitas() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.history, color: MyApp.primaryColor),
            SizedBox(width: 8),
            Text(
              'Últimas visitas',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            Spacer(),
            Text(
              '${_visitasRecientes.length} registros',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        SizedBox(height: 12),
        ..._visitasRecientes.map((visita) => _buildVisitaCard(visita)),
      ],
    );
  }

  Widget _buildVisitaCard(VisitaStand visita) {
    final horaEntrada = DateFormat('HH:mm').format(visita.fechaEntrada);
    final fechaEntrada = DateFormat('dd/MM/yyyy').format(visita.fechaEntrada);
    
    return Card(
      margin: EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: visita.atendido 
                ? Colors.green.withOpacity(0.1) 
                : Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            visita.atendido ? Icons.check_circle : Icons.access_time,
            color: visita.atendido ? Colors.green : Colors.orange,
          ),
        ),
        title: Text(
          visita.nombreVisitante ?? 'Visitante sin registrar',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$fechaEntrada - $horaEntrada'),
            if (visita.motivoVisita != null)
              Text(
                visita.motivoVisita!,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: visita.atendido
            ? Icon(Icons.check, color: Colors.green)
            : TextButton(
                child: Text('Atender'),
                onPressed: () => _marcarAtendido(visita),
              ),
        isThreeLine: true,
      ),
    );
  }
}