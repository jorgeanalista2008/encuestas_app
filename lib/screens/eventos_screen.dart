import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../main.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';
import 'crear_evento_screen.dart';
import 'control_visitas_screen.dart';

class EventosScreen extends StatefulWidget {
  @override
  _EventosScreenState createState() => _EventosScreenState();
}

class _EventosScreenState extends State<EventosScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Evento> _eventos = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEventos();
  }

  Future<void> _cargarEventos() async {
    setState(() => _isLoading = true);
    try {
      final eventos = await _dbHelper.obtenerEventos();
      setState(() {
        _eventos = eventos;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
        title: 'Eventos',
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _cargarEventos,
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MyApp.primaryColor))
          : _eventos.isEmpty
              ? _buildEmptyState()
              : _buildListaEventos(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CrearEventoScreen()),
          ).then((_) => _cargarEventos());
        },
        backgroundColor: MyApp.primaryColor,
        child: Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.event_busy, size: 80, color: Colors.grey[400]),
          SizedBox(height: 16),
          Text(
            'No hay eventos creados',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.grey[600]),
          ),
          SizedBox(height: 8),
          Text(
            'Crea un evento para empezar a registrar visitas',
            style: TextStyle(color: Colors.grey[500]),
          ),
          SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CrearEventoScreen()),
              ).then((_) => _cargarEventos());
            },
            icon: Icon(Icons.add),
            label: Text('Crear Evento'),
          ),
        ],
      ),
    );
  }

  Widget _buildListaEventos() {
    return ListView.builder(
      padding: EdgeInsets.all(16),
      itemCount: _eventos.length,
      itemBuilder: (context, index) {
        final evento = _eventos[index];
        return _buildEventoCard(evento);
      },
    );
  }

  Widget _buildEventoCard(Evento evento) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ControlVisitasScreen(evento: evento),
            ),
          ).then((_) => _cargarEventos());
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: evento.activo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.event,
                      color: evento.activo ? Colors.green : Colors.grey,
                      size: 28,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          evento.nombre,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (evento.descripcion != null && evento.descripcion!.isNotEmpty)
                          Text(
                            evento.descripcion!,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                    onPressed: () => _eliminarEvento(evento),
                  ),
                ],
              ),
              SizedBox(height: 12),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    _buildInfoItem(Icons.calendar_today, 
                      evento.fechaEvento != null 
                        ? DateFormat('dd/MM/yyyy').format(evento.fechaEvento!)
                        : 'Sin fecha'),
                    SizedBox(width: 16),
                    _buildInfoItem(Icons.location_on, evento.ubicacion ?? 'Sin ubicación'),
                  ],
                ),
              ),
              SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: evento.activo ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      evento.activo ? 'Activo' : 'Inactivo',
                      style: TextStyle(
                        color: evento.activo ? Colors.green : Colors.grey,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: Colors.grey[600]),
        SizedBox(width: 4),
        Text(text, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Future<void> _eliminarEvento(Evento evento) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(Icons.warning_amber, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar Evento'),
          ],
        ),
        content: Text('¿Estás seguro de eliminar "${evento.nombre}" y todas sus visitas?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            child: Text('Eliminar'),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _dbHelper.eliminarEvento(evento.id!);
              Navigator.pop(context);
              _cargarEventos();
            },
          ),
        ],
      ),
    );
  }
}