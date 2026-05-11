import 'package:flutter/material.dart';
import '../main.dart';
import '../database/database_helper.dart';
import '../models/encuesta_model.dart';
import '../services/export_service.dart';

class ExportarScreen extends StatefulWidget {
  @override
  _ExportarScreenState createState() => _ExportarScreenState();
}

class _ExportarScreenState extends State<ExportarScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ExportService _exportService = ExportService();
  List<Encuesta> _encuestas = [];
  bool _isLoading = true;
  String _selectedTab = 'completo';

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    setState(() => _isLoading = true);
    try {
      final encuestas = await _dbHelper.obtenerEncuestas();
      setState(() {
        _encuestas = encuestas;
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
        title: 'Exportar Datos',
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: MyApp.primaryColor))
          : _buildBody(),
    );
  }

  Widget _buildBody() {
    return Column(
      children: [
        // Tabs de exportación
        Container(
          margin: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              _buildTabButton('completo', 'Todo'),
              _buildTabButton('estadisticas', 'Estadísticas'),
              _buildTabButton('usuario', 'Por Usuario'),
            ],
          ),
        ),

        // Contenido según tab seleccionado
        Expanded(
          child: _selectedTab == 'completo'
              ? _buildExportCompleto()
              : _selectedTab == 'estadisticas'
                  ? _buildExportEstadisticas()
                  : _buildExportPorUsuario(),
        ),
      ],
    );
  }

  Widget _buildTabButton(String tab, String label) {
    final isSelected = _selectedTab == tab;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedTab = tab),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? MyApp.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey[700],
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildExportCompleto() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Exportación Completa',
            'Exporta todas las encuestas, preguntas y respuestas de todos los usuarios en un archivo CSV.',
            Icons.description_outlined,
          ),
          SizedBox(height: 16),
          _buildPreviewData(),
          SizedBox(height: 24),
          _buildExportButton('completo'),
        ],
      ),
    );
  }

  Widget _buildExportEstadisticas() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Estadísticas Generales',
            'Exporta un resumen con total de usuarios, respuestas y tasas de respuesta por encuesta.',
            Icons.bar_chart_outlined,
          ),
          SizedBox(height: 24),
          _buildEstadisticasPreview(),
          SizedBox(height: 24),
          _buildExportButton('estadisticas'),
        ],
      ),
    );
  }

  Widget _buildExportPorUsuario() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildInfoCard(
            'Exportar por Usuario',
            'Selecciona una encuesta y un usuario para exportar sus respuestas.',
            Icons.person_outline,
          ),
          SizedBox(height: 16),
          ..._encuestas.map((encuesta) => _buildEncuestaCard(encuesta)).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String title, String description, IconData icon) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MyApp.accentColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: MyApp.primaryColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: MyApp.primaryColor),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: MyApp.primaryColor,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey[700],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPreviewData() {
    // Vista previa de los datos
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: MyApp.primaryColor),
              SizedBox(width: 8),
              Text(
                'Vista previa de datos',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          _buildDataRow('Encuestas', '${_encuestas.length}'),
          _buildDataRow('Preguntas totales', 
            '${_encuestas.fold<int>(0, (sum, e) => sum + e.preguntas.length)}'),
          _buildDataRow('Respuestas totales',
            '${_encuestas.fold<int>(0, (sum, e) => sum + e.preguntas.where((p) => p.respuesta != null).length)}'),
          _buildDataRow('Formato', 'CSV (Comma Separated Values)'),
          _buildDataRow('Columnas', '11 columnas de datos'),
        ],
      ),
    );
  }

  Widget _buildEstadisticasPreview() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Encuestas disponibles: ${_encuestas.length}',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 12),
          ..._encuestas.map((encuesta) => Padding(
            padding: EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Icon(Icons.circle, size: 8, color: MyApp.primaryColor),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    encuesta.titulo,
                    style: TextStyle(fontSize: 14),
                  ),
                ),
                Text(
                  '${encuesta.preguntas.length} preg.',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )).toList(),
        ],
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildEncuestaCard(Encuesta encuesta) {
    return Card(
      margin: EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        leading: Icon(Icons.assignment, color: MyApp.primaryColor),
        title: Text(encuesta.titulo),
        subtitle: Text('${encuesta.preguntas.length} preguntas'),
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Selecciona un usuario para exportar sus respuestas:',
                  style: TextStyle(color: Colors.grey[600]),
                ),
                SizedBox(height: 8),
                FutureBuilder<List<String>>(
                  future: _getUsuariosEncuesta(encuesta.id!),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Text('No hay respuestas aún');
                    }
                    return Wrap(
                      spacing: 8,
                      children: snapshot.data!.map((usuario) {
                        return ActionChip(
                          avatar: Icon(Icons.person, size: 18),
                          label: Text(usuario),
                          onPressed: () {
                            _exportarUsuario(encuesta.id!, usuario);
                          },
                          backgroundColor: MyApp.accentColor,
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<List<String>> _getUsuariosEncuesta(int encuestaId) async {
    final respuestas = await _dbHelper.obtenerRespuestasAgrupadas(encuestaId);
    return respuestas.map((r) => r.nombreUsuario).toSet().toList();
  }

  Widget _buildExportButton(String tipo) {
    return ElevatedButton.icon(
      onPressed: () => _exportService.exportarYCompartir(
        context: context,
        tipo: tipo,
      ),
      icon: Icon(Icons.file_download),
      label: Text('Exportar y Compartir'),
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  void _exportarUsuario(int encuestaId, String usuario) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.person, color: MyApp.primaryColor),
            SizedBox(width: 8),
            Text('Exportar respuestas'),
          ],
        ),
        content: Text('¿Exportar respuestas de "$usuario"?'),
        actions: [
          TextButton(
            child: Text('Cancelar'),
            onPressed: () => Navigator.pop(ctx),
          ),
          ElevatedButton(
            child: Text('Exportar'),
            onPressed: () {
              Navigator.pop(ctx);
              _exportService.exportarYCompartir(
                context: context,
                tipo: 'usuario',
                encuestaId: encuestaId,
                nombreUsuario: usuario,
              );
            },
          ),
        ],
      ),
    );
  }
}