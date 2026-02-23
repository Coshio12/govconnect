import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:permission_handler/permission_handler.dart';
import 'package:printing/printing.dart';
import '../models/postulacion_model.dart';
import 'package:device_info_plus/device_info_plus.dart';

class PdfService {
  static const _primaryColor = PdfColor.fromInt(0xFF1A73E8);
  static const _accentColor = PdfColor.fromInt(0xFF34A853);
  static final _fmt = DateFormat('dd/MM/yyyy');
  static final _fmtShort = DateFormat('dd/MM/yy');

  /// Genera el objeto Document (usado para previsualizar o guardar)
  static Future<pw.Document> crearDocumento({
    required String puestoTitulo,
    required String dependencia,
    required int vacantes,
    required DateTime? fechaExamen,
    required List<PostulacionModel> postulantes,
  }) async {
    final pdf = pw.Document();
    final font = await PdfGoogleFonts.poppinsRegular();
    final fontBold = await PdfGoogleFonts.poppinsBold();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        header: (context) => _buildHeader(fontBold, font, puestoTitulo, dependencia, vacantes, fechaExamen, postulantes.length),
        footer: (context) => _buildFooter(font, context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildTable(fontBold, font, postulantes),
          pw.SizedBox(height: 20),
          _buildFirmas(fontBold, font),
        ],
      ),
    );
    return pdf;
  }

  static pw.Widget _buildHeader(pw.Font fontBold, pw.Font font, String titulo, String dep, int vac, DateTime? fecha, int total) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.all(16),
          decoration: pw.BoxDecoration(color: _primaryColor, borderRadius: pw.BorderRadius.circular(8)),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('GOBIERNO AUTÓNOMO DEPARTAMENTAL DE TARIJA',
                      style: pw.TextStyle(font: fontBold, fontSize: 11, color: PdfColors.white)),
                  pw.SizedBox(height: 4),
                  pw.Text(dep, style: pw.TextStyle(font: font, fontSize: 9, color: PdfColor.fromInt(0xB3FFFFFF))),
                ],
              ),
              pw.Text('LISTA DE POSTULANTES', style: pw.TextStyle(font: fontBold, fontSize: 10, color: _accentColor)),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: pw.BorderRadius.circular(6),
            border: pw.Border.all(color: PdfColors.grey300, width: 0.5),
          ),
          child: pw.Row(
            children: [
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text('PUESTO', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey600)),
                    pw.Text(titulo, style: pw.TextStyle(font: fontBold, fontSize: 12)),
                  ],
                ),
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  _infoChip(fontBold, font, 'Vacantes', '$vac'),
                  pw.SizedBox(height: 4),
                  _infoChip(fontBold, font, 'Examen', fecha != null ? _fmt.format(fecha) : 'Por definir',
                    color: fecha != null ? _accentColor : PdfColors.orange),
                  pw.SizedBox(height: 4),
                  _infoChip(fontBold, font, 'Postulantes', '$total'),
                ],
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Divider(color: PdfColors.grey300),
      ],
    );
  }

  static pw.Widget _infoChip(pw.Font fontBold, pw.Font font, String label, String value, {PdfColor color = _primaryColor}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: pw.BoxDecoration(color: color, borderRadius: pw.BorderRadius.circular(4)),
      child: pw.Row(
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text('$label: ', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.white)),
          pw.Text(value, style: pw.TextStyle(font: fontBold, fontSize: 8, color: PdfColors.white)),
        ],
      ),
    );
  }

  static pw.Widget _buildTable(pw.Font fontBold, pw.Font font, List<PostulacionModel> postulantes) {
    return pw.TableHelper.fromTextArray(
      headers: ['N°', 'Apellidos', 'Nombres', 'C.I.', 'Teléfono', 'Fecha'],
      headerStyle: pw.TextStyle(font: fontBold, fontSize: 9, color: PdfColors.white),
      headerDecoration: const pw.BoxDecoration(color: _primaryColor),
      cellStyle: pw.TextStyle(font: font, fontSize: 9),
      columnWidths: {
        0: const pw.FixedColumnWidth(25),
        1: const pw.FlexColumnWidth(2),
        2: const pw.FlexColumnWidth(2),
        3: const pw.FixedColumnWidth(70),
        4: const pw.FixedColumnWidth(70),
        5: const pw.FixedColumnWidth(60),
      },
      data: postulantes.asMap().entries.map((e) {
        final p = e.value;
        return [
          '${e.key + 1}',
          p.apellidos,
          p.nombres,
          p.carnet,
          p.telefono,
          _fmtShort.format(p.fechaPostulacion),
        ];
      }).toList(),
    );
  }

  static pw.Widget _buildFirmas(pw.Font fontBold, pw.Font font) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
      children: [
        _firmaBox(fontBold, font, 'Jefe de Recursos Humanos'),
        _firmaBox(fontBold, font, 'Secretario/a General'),
      ],
    );
  }

  static pw.Widget _firmaBox(pw.Font fontBold, pw.Font font, String cargo) {
    return pw.Column(
      children: [
        pw.SizedBox(width: 150, child: pw.Divider(color: PdfColors.black, thickness: 0.5)),
        pw.Text(cargo, style: pw.TextStyle(font: fontBold, fontSize: 8)),
      ],
    );
  }

  static pw.Widget _buildFooter(pw.Font font, pw.Context context) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text('Generado el ${_fmt.format(DateTime.now())}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
        pw.Text('Pág. ${context.pageNumber} / ${context.pagesCount}', style: pw.TextStyle(font: font, fontSize: 8, color: PdfColors.grey)),
      ],
    );
  }

  /// Guarda el PDF directamente en la carpeta Descargas del dispositivo
  static Future<String> guardarPdfLocal(String nombre, Uint8List bytes) async {
  if (Platform.isAndroid) {
    // En Android 13+ (SDK 33+) no se necesita permiso para escribir en Downloads
    // En versiones anteriores sí se necesita
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    final sdkInt = androidInfo.version.sdkInt;

    if (sdkInt < 33) {
      final status = await Permission.storage.request();
      if (status.isDenied) {
        throw Exception('Permiso de almacenamiento denegado');
      }
    }

    final downloadsDir = Directory('/storage/emulated/0/Download');
    if (!await downloadsDir.exists()) {
      await downloadsDir.create(recursive: true);
    }

    final file = File('${downloadsDir.path}/$nombre');
    await file.writeAsBytes(bytes);
    return file.path;

  } else if (Platform.isIOS) {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nombre');
    await file.writeAsBytes(bytes);
    return file.path;
  } else {
    final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$nombre');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
}