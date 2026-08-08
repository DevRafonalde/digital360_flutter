import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

/// Gera e abre pra impressao/download o certificado de conclusao de curso -
/// so no cliente, sem nenhuma chamada de rede. Usa `printing`, que funciona
/// tanto em mobile (compartilhar/imprimir) quanto na web (abre o dialogo de
/// impressao do navegador, de onde da pra salvar como PDF).
class CertificadoService {
  CertificadoService._();

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
          padding: const pw.EdgeInsets.all(48),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColor.fromHex('#7CFF9E'), width: 4),
          ),
          child: pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.Text('digital360',
                    style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 24),
                pw.Text('Certificado de Conclusão',
                    style: pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 24),
                pw.Text('Certificamos que', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 8),
                pw.Text(nomeAluno,
                    style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('concluiu o curso', style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 8),
                pw.Text('"$tituloCurso"',
                    style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 8),
                pw.Text('com carga horária de $cargaHoraria horas',
                    style: const pw.TextStyle(fontSize: 14)),
                pw.SizedBox(height: 32),
                pw.Text(dataFormatada, style: const pw.TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      ),
    );

    await Printing.layoutPdf(onLayout: (_) => doc.save());
  }

  static String _dataFormatada(DateTime d) {
    final meses = [
      'janeiro', 'fevereiro', 'março', 'abril', 'maio', 'junho',
      'julho', 'agosto', 'setembro', 'outubro', 'novembro', 'dezembro',
    ];
    return '${d.day} de ${meses[d.month - 1]} de ${d.year}';
  }
}
