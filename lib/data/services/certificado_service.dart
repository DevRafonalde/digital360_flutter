import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Gera e abre pra impressao/download o certificado de conclusao de curso -
/// so no cliente, sem nenhuma chamada de rede. Usa `printing`, que funciona
/// tanto em mobile (compartilhar/imprimir) quanto na web (abre o dialogo de
/// impressao do navegador, de onde da pra salvar como PDF).
class CertificadoService {
  CertificadoService._();

  // Paleta oficial "Minimal Tech" do Digital 360 (mesma de app_colors.dart) -
  // grafite quase preto + acento verde eletrico unico.
  static final _bg = PdfColor.fromHex('#0C0D0E');
  static final _surface = PdfColor.fromHex('#151718');
  static final _acento = PdfColor.fromHex('#7CFF9E');
  static final _acentoEscuro = PdfColor.fromHex('#149259');
  static final _textoClaro = PdfColor.fromHex('#EDEFF0');
  static final _textoMuted = PdfColor.fromHex('#B9BEC2');

  static Future<void> gerarEAbrir({
    required String nomeAluno,
    required String tituloCurso,
    required int cargaHoraria,
  }) async {
    final doc = pw.Document();
    final dataFormatada = _dataFormatada(DateTime.now());

    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => pw.Container(
          width: double.infinity,
          height: double.infinity,
          color: _bg,
          child: pw.Stack(
            children: [
              // cantos decorativos, no acento de marca
              pw.Positioned(top: 0, left: 0, child: _cantoDecorativo()),
              pw.Positioned(
                bottom: 0,
                right: 0,
                child: pw.Transform.rotate(angle: 3.14159, child: _cantoDecorativo()),
              ),
              pw.Padding(
                padding: const pw.EdgeInsets.all(56),
                child: pw.Container(
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: _acento, width: 1.5),
                  ),
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.all(40),
                    child: pw.Center(
                      child: pw.Column(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text('DIGITAL 360',
                              style: pw.TextStyle(
                                fontSize: 16,
                                fontWeight: pw.FontWeight.bold,
                                color: _acento,
                                letterSpacing: 4,
                              )),
                          pw.SizedBox(height: 4),
                          pw.Text('SMART HAS · SOCIEDADE 5.0',
                              style: pw.TextStyle(fontSize: 8, color: _textoMuted, letterSpacing: 2)),
                          pw.SizedBox(height: 28),
                          pw.Text('CERTIFICADO DE CONCLUSÃO',
                              style: pw.TextStyle(
                                fontSize: 26,
                                fontWeight: pw.FontWeight.bold,
                                color: _textoClaro,
                              )),
                          pw.SizedBox(height: 28),
                          pw.Text('Certificamos que',
                              style: pw.TextStyle(fontSize: 13, color: _textoMuted)),
                          pw.SizedBox(height: 10),
                          pw.Text(nomeAluno,
                              style: pw.TextStyle(
                                fontSize: 26,
                                fontWeight: pw.FontWeight.bold,
                                color: _acento,
                              )),
                          pw.SizedBox(height: 10),
                          pw.Text('concluiu com sucesso o curso',
                              style: pw.TextStyle(fontSize: 13, color: _textoMuted)),
                          pw.SizedBox(height: 8),
                          pw.Text('"$tituloCurso"',
                              style: pw.TextStyle(
                                fontSize: 19,
                                fontWeight: pw.FontWeight.bold,
                                color: _textoClaro,
                              )),
                          pw.SizedBox(height: 8),
                          pw.Text('com carga horária de $cargaHoraria horas',
                              style: pw.TextStyle(fontSize: 13, color: _textoMuted)),
                          pw.SizedBox(height: 36),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.center,
                            children: [
                              pw.Container(width: 60, height: 0.75, color: _textoMuted),
                              pw.SizedBox(width: 12),
                              pw.Text(dataFormatada,
                                  style: pw.TextStyle(fontSize: 11, color: _textoMuted)),
                              pw.SizedBox(width: 12),
                              pw.Container(width: 60, height: 0.75, color: _textoMuted),
                            ],
                          ),
                          pw.SizedBox(height: 20),
                          pw.Container(
                            padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: pw.BoxDecoration(
                              color: _surface,
                              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
                              border: pw.Border.all(color: _acentoEscuro, width: 0.75),
                            ),
                            child: pw.Text('Equipe Digital 360 · Smart HAS',
                                style: pw.TextStyle(fontSize: 9, color: _textoMuted)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static pw.Widget _cantoDecorativo() => pw.Container(
        width: 90,
        height: 90,
        decoration: pw.BoxDecoration(
          border: pw.Border(
            top: pw.BorderSide(color: _acento, width: 3),
            left: pw.BorderSide(color: _acento, width: 3),
          ),
        ),
      );

  static String _dataFormatada(DateTime d) {
    final meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}
