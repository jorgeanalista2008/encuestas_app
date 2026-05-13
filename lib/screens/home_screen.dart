import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';
import '../main.dart';
import 'crear_encuesta_screen.dart';
import 'responder_encuesta_screen.dart';
import 'seleccionar_usuario_screen.dart';
import 'exportar_screen.dart';
import 'control_stand_screen.dart';
import 'eventos_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  List<Encuesta> _encuestas = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _cargarEncuestas();
  }
int _getTotalUsuarios() {
  // Contar usuarios únicos de todas las encuestas
  Set<String> usuarios = {};
  for (var encuesta in _encuestas) {
    // Aquí necesitarías obtener los usuarios de cada encuesta
    // Por ahora usamos un placeholder
  }
  return usuarios.length;
}

int _getTotalRespuestas() {
  int total = 0;
  for (var encuesta in _encuestas) {
    total += encuesta.preguntas
        .where((p) => p.respuesta != null && p.respuesta!.isNotEmpty)
        .length;
  }
  return total;
}
  Future<void> _cargarEncuestas() async {
    setState(() => _isLoading = true);
    try {
      final encuestas = await _dbHelper.obtenerEncuestas();
      setState(() {
        _encuestas = encuestas;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar encuestas: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: LogoAppBar(
      title: 'Mis Encuestas',
      actions: [
         IconButton(
            icon: Icon(Icons.event_note),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => EventosScreen()),
              );
            },
            tooltip: 'Control de Eventos',
          ),
         // Botón de Stand
        IconButton(
          icon: Icon(Icons.storefront_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ControlStandScreen()),
            );
          },
          tooltip: 'Control de Stand',
        ),

        IconButton(
          icon: Icon(Icons.file_download_outlined),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ExportarScreen()),
            );
          },
          tooltip: 'Exportar datos',
        ),
        IconButton(
          icon: Icon(Icons.refresh),
          onPressed: _cargarEncuestas,
        ),
      ],
    ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: MyApp.primaryColor,
              ),
            )
          : _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CrearEncuestaScreen()),
          ).then((_) => _cargarEncuestas());
        },
        child: Icon(Icons.add, size: 28),
      ),
    );
  }

  Widget _buildBody() {
    if (_encuestas.isEmpty) {
      return _buildEmptyState();
    }
    return _buildEncuestasList();
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CorporateLogo(size: 100, showText: false),
          SizedBox(height: 24),
          Text(
            'No hay encuestas creadas',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: MyApp.primaryColor,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Toca el botón + para crear tu primera encuesta',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => CrearEncuestaScreen()),
              ).then((_) => _cargarEncuestas());
            },
            icon: Icon(Icons.add),
            label: Text('Crear Encuesta'),
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEncuestasList() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Estadísticas rápidas
        Container(
          margin: EdgeInsets.all(16),
          padding: EdgeInsets.all(16),
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
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(
              icon: Icons.assignment,
              value: '${_encuestas.length}',
              label: 'Encuestas',
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildStatItem(
              icon: Icons.people,
              value: '${_getTotalUsuarios()}',
              label: 'Usuarios',
            ),
            Container(
              width: 1,
              height: 40,
              color: Colors.white.withOpacity(0.3),
            ),
            _buildStatItem(
              icon: Icons.check_circle,
              value: '${_getTotalRespuestas()}',
              label: 'Respuestas',
            ),
            ],
          ),
        ),
        
        // Título de la sección
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Encuestas disponibles',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
          ),
        ),
        
        SizedBox(height: 8),
        
        // Lista de encuestas
        Expanded(
          child: ListView.builder(
            itemCount: _encuestas.length,
            padding: EdgeInsets.only(bottom: 80),
            itemBuilder: (context, index) {
              final encuesta = _encuestas[index];
              int preguntasRespondidas = encuesta.preguntas
                  .where((p) => p.respuesta != null && p.respuesta!.isNotEmpty)
                  .length;
              int totalPreguntas = encuesta.preguntas.length;
              double progreso = totalPreguntas > 0 
                  ? preguntasRespondidas / totalPreguntas 
                  : 0.0;
              
              return Card(
                margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => SeleccionarUsuarioScreen(  // CAMBIAR AQUÍ
                          encuesta: encuesta,
                        ),
                      ),
                    ).then((_) => _cargarEncuestas());
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
                                color: MyApp.accentColor,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Icon(
                                Icons.assignment,
                                color: MyApp.primaryColor,
                                size: 24,
                              ),
                            ),
                            SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    encuesta.titulo,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.grey[800],
                                    ),
                                  ),
                                  SizedBox(height: 4),
                                  Text(
                                    '${encuesta.fechaCreacion.day}/${encuesta.fechaCreacion.month}/${encuesta.fechaCreacion.year}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                              onPressed: () => _eliminarEncuesta(encuesta.id!),
                            ),
                          ],
                        ),
                        
                        SizedBox(height: 12),
                        
                        // Barra de progreso
                        Row(
                          children: [
                            Text(
                              '$preguntasRespondidas de $totalPreguntas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            SizedBox(width: 8),
                            Text(
                              'respondidas',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[500],
                              ),
                            ),
                            Spacer(),
                            Text(
                              '${(progreso * 100).toInt()}%',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: progreso == 1.0 
                                    ? Colors.green 
                                    : MyApp.primaryColor,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: progreso,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(
                              progreso == 1.0 ? Colors.green : MyApp.primaryColor,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem({required IconData icon, required String value, required String label}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white, size: 24),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
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

  Future<void> _eliminarEncuesta(int id) async {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red),
            SizedBox(width: 8),
            Text('Eliminar encuesta'),
          ],
        ),
        content: Text('¿Estás seguro de eliminar esta encuesta? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text('Eliminar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () async {
              await _dbHelper.eliminarEncuesta(id);
              Navigator.pop(ctx);
              _cargarEncuestas();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Encuesta eliminada correctamente'),
                  backgroundColor: Colors.red[400],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}