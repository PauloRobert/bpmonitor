import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';

import '../../shared/models/measurement_model.dart';
import '../../shared/models/user_model.dart';
import '../../core/constants/app_constants.dart';

// Classe auxiliar para dados de categoria
class CategoryData {
  final String name;
  final PdfColor color;

  CategoryData(this.name, this.color);
}

class ReportPdfService {
  // Singleton pattern
  static final ReportPdfService _instance = ReportPdfService._internal();
  factory ReportPdfService() => _instance;
  ReportPdfService._internal();

  // Método principal para gerar PDF
  Future<String> generateHealthReport({
    required UserModel user,
    required List<MeasurementModel> measurements,
    required Map<String, dynamic> reportData,
    required String periodLabel,
  }) async {
    final pdf = pw.Document(
      title: 'Relatório de Saúde - ${user.name}',
      author: 'BPMonitor',
      creator: 'BPMonitor',
    );

    try {
      // Carregar fontes personalizadas (opcional)
      pw.Font? regularFont;
      pw.Font? boldFont;

      try {
        regularFont = await _loadFont('assets/fonts/regular.ttf');
        boldFont = await _loadFont('assets/fonts/bold.ttf');
      } catch (e) {
        // fallback: apenas log (usar fontes padrão do pacote)
        print('Não foi possível carregar fontes personalizadas: $e');
      }

      final pw.ThemeData? theme = (regularFont != null && boldFont != null)
          ? pw.ThemeData.withFont(base: regularFont, bold: boldFont)
          : null;

      pdf.addPage(
        pw.MultiPage(
          theme: theme,
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(40),
          header: (context) => _buildHeader(user, periodLabel),
          footer: (context) => _buildFooter(context),
          build: (context) => [
            _buildSummarySection(reportData),
            pw.SizedBox(height: 20),
            _buildTrendSection(reportData),
            pw.SizedBox(height: 20),
            _buildStatisticsSection(reportData),
            pw.SizedBox(height: 20),
            _buildCategoryDistributionSection(reportData),
            pw.SizedBox(height: 20),
            _buildInsightsSection(reportData, measurements),
          ],
        ),
      );

      final output = await _savePdfFile(pdf, user.name);
      return output;
    } catch (e, st) {
      print('Erro na geração do PDF: $e\n$st');
      rethrow;
    }
  }

  // Carrega a fonte - com cache para otimização
  Future<pw.Font> _loadFont(String path) async {
    try {
      final ByteData data = await rootBundle.load(path);
      return pw.Font.ttf(data);
    } catch (e) {
      throw Exception('Erro ao carregar fonte "$path": $e');
    }
  }

  // Constrói o cabeçalho do PDF
  pw.Widget _buildHeader(UserModel user, String periodLabel) {
    // Usar getters seguros do UserModel
    final DateTime? birthDate = user.birthDateAsDateTime;
    final String formattedBirthDate =
    birthDate != null ? DateFormat('dd/MM/yyyy').format(birthDate) : 'Data indisponível';
    final int age = user.age;

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Relatório de Saúde',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                periodLabel,
                style: const pw.TextStyle(
                  fontSize: 14,
                ),
              ),
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Paciente: ${user.name}', style: const pw.TextStyle(fontSize: 10)),
                pw.Text(
                  'Data Nasc.: $formattedBirthDate',
                  style: const pw.TextStyle(fontSize: 10),
                ),
                pw.Text(
                  'Idade: $age anos',
                  style: const pw.TextStyle(fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Constrói o rodapé do PDF
  pw.Widget _buildFooter(pw.Context context) {
    final now = DateTime.now();
    final dateFormatted = DateFormat('dd/MM/yyyy HH:mm').format(now);

    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 20),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Gerado em: $dateFormatted',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
          pw.Text(
            'Página ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey700,
            ),
          ),
        ],
      ),
    );
  }

  // Seção de resumo
  pw.Widget _buildSummarySection(Map<String, dynamic> reportData) {
    final averages = reportData['averages'] as Map<String, dynamic>? ?? {};
    final totalMeasurements = reportData['totalMeasurements'] as int? ?? 0;

    final systolic = _safeRound(averages['systolic']);
    final diastolic = _safeRound(averages['diastolic']);
    final heartRate = _safeRound(averages['heartRate']);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Resumo',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.Text(
            '$totalMeasurements medições registradas',
            style: const pw.TextStyle(
              fontSize: 10,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Row(
            children: [
              _buildSummaryItem('Sistólica', systolic.toString(), 'mmHg'),
              _buildSummaryItem('Diastólica', diastolic.toString(), 'mmHg'),
              _buildSummaryItem('Batimentos', heartRate.toString(), 'bpm'),
            ],
          ),
        ],
      ),
    );
  }

  // Item de resumo
  pw.Widget _buildSummaryItem(String label, String value, String unit) {
    return pw.Expanded(
      child: pw.Container(
        margin: const pw.EdgeInsets.symmetric(horizontal: 5),
        padding: const pw.EdgeInsets.all(8),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey100,
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
        ),
        child: pw.Column(
          children: [
            pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.Text(
              unit,
              style: const pw.TextStyle(
                fontSize: 8,
              ),
            ),
            pw.Text(
              label,
              style: const pw.TextStyle(
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Seção de tendência
  pw.Widget _buildTrendSection(Map<String, dynamic> reportData) {
    final trend = reportData['trend'] as String? ?? 'stable';
    final trendText = _getTrendText(trend);
    final trendColor = _getTrendPdfColor(trend);
    final lightColor = _getLightVersionOfColor(trendColor);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        color: lightColor,
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Tendência',
            style: pw.TextStyle(
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            trendText,
            style: pw.TextStyle(
              fontSize: 12,
              color: trendColor,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Container(
            padding: const pw.EdgeInsets.all(8),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(5)),
              border: pw.Border.all(width: 0.5, color: trendColor),
            ),
            child: pw.Text(
              _getTrendDescription(trend),
              style: const pw.TextStyle(
                fontSize: 10,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  // Seção de estatísticas
  pw.Widget _buildStatisticsSection(Map<String, dynamic> reportData) {
    final extremes = reportData['extremes'] as Map<String, dynamic>? ?? {};

    final maxSystolic = _safeValue(extremes['maxSystolic']);
    final maxDiastolic = _safeValue(extremes['maxDiastolic']);
    final minSystolic = _safeValue(extremes['minSystolic']);
    final minDiastolic = _safeValue(extremes['minDiastolic']);

    return pw.Row(
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              color: PdfColors.red50,
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Maior Pressão',
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  '$maxSystolic/$maxDiastolic',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red,
                  ),
                ),
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 10),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
              color: PdfColors.green50,
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Menor Pressão',
                  style: const pw.TextStyle(
                    fontSize: 12,
                  ),
                ),
                pw.Text(
                  '$minSystolic/$minDiastolic',
                  style: pw.TextStyle(
                    fontSize: 14,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Seção de distribuição por categoria
  pw.Widget _buildCategoryDistributionSection(Map<String, dynamic> reportData) {
    try {
      final Map<String, int> distribution = {};

      if (reportData['categoryDistribution'] != null) {
        final raw = reportData['categoryDistribution'];
        if (raw is Map) {
          raw.forEach((key, value) {
            final k = key?.toString() ?? 'desconhecido';
            distribution[k] = _safeValue(value);
          });
        }
      }

      if (distribution.isEmpty) {
        return pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          ),
          child: pw.Center(
            child: pw.Text(
              'Sem dados de distribuição disponíveis',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
            ),
          ),
        );
      }

      final total = distribution.values.fold<int>(0, (s, v) => s + v);

      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Distribuição por Categoria',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            ...distribution.entries.map((entry) {
              final category = entry.key;
              final count = entry.value;
              final percentage = total > 0 ? (count / total * 100).round() : 0;
              final categoryData = _getCategoryData(category);

              return pw.Container(
                margin: const pw.EdgeInsets.only(bottom: 5),
                child: pw.Column(
                  children: [
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 8,
                          height: 8,
                          color: categoryData.color,
                        ),
                        pw.SizedBox(width: 5),
                        pw.Expanded(
                          child: pw.Text(
                            categoryData.name,
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                        ),
                        pw.Text(
                          '$count ($percentage%)',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 2),
                    pw.Container(
                      height: 4,
                      child: pw.LinearProgressIndicator(
                        value: percentage / 100,
                        backgroundColor: PdfColors.grey200,
                        valueColor: categoryData.color,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao gerar seção de distribuição: $e');
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Text(
          'Não foi possível gerar a distribuição por categoria.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }
  }

  // Seção de insights
  pw.Widget _buildInsightsSection(Map<String, dynamic> reportData, List<MeasurementModel> measurements) {
    try {
      final mostCommonHour = _safeValue(reportData['mostCommonHour']);

      int morningMeasurements = 0;
      int afternoonMeasurements = 0;
      int eveningMeasurements = 0;

      for (var measurement in measurements) {
        try {
          final hour = measurement.measuredAt.hour;
          if (hour < 12) {
            morningMeasurements++;
          } else if (hour < 18) {
            afternoonMeasurements++;
          } else {
            eveningMeasurements++;
          }
        } catch (e) {
          print('Erro ao processar horário de medição: $e');
        }
      }

      String preferredTime = 'manhã';
      if (afternoonMeasurements > morningMeasurements && afternoonMeasurements > eveningMeasurements) {
        preferredTime = 'tarde';
      } else if (eveningMeasurements > morningMeasurements && eveningMeasurements > afternoonMeasurements) {
        preferredTime = 'noite';
      }

      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
          color: PdfColors.amber50,
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              'Insights Pessoais',
              style: pw.TextStyle(
                fontSize: 14,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
            pw.SizedBox(height: 10),
            _buildInsightItem('Horário preferido', 'Você costuma medir sua pressão mais na $preferredTime'),
            _buildInsightItem('Horário mais comum', 'Sua hora favorita é ${mostCommonHour}h'),
            if (measurements.length > 10)
              _buildInsightItem('Consistência', 'Você tem um bom histórico com ${measurements.length} medições'),
            _buildInsightItem('Dica', 'Meça sempre no mesmo horário para melhor precisão'),
          ],
        ),
      );
    } catch (e) {
      print('Erro ao gerar seção de insights: $e');
      return pw.Container(
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(width: 0.5, color: PdfColors.grey400),
          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
        ),
        child: pw.Text(
          'Não foi possível gerar insights personalizados.',
          style: const pw.TextStyle(fontSize: 10),
        ),
      );
    }
  }

  // Item de insight
  pw.Widget _buildInsightItem(String title, String description) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 5),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 8,
            height: 8,
            margin: const pw.EdgeInsets.only(top: 2),
            decoration: const pw.BoxDecoration(
              color: PdfColors.amber,
              shape: pw.BoxShape.circle,
            ),
          ),
          pw.SizedBox(width: 5),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  title,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.Text(
                  description,
                  style: const pw.TextStyle(
                    fontSize: 9,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Funções auxiliares
  int _calculateAge(DateTime birthDate) {
    try {
      final today = DateTime.now();
      int age = today.year - birthDate.year;
      if (today.month < birthDate.month ||
          (today.month == birthDate.month && today.day < birthDate.day)) {
        age--;
      }
      return age < 0 ? 0 : age;
    } catch (e) {
      print('Erro ao calcular idade: $e');
      return 0;
    }
  }

  String _getTrendText(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Tendência de alta';
      case 'decreasing':
        return 'Tendência de baixa';
      default:
        return 'Estável';
    }
  }

  String _getTrendDescription(String trend) {
    switch (trend) {
      case 'increasing':
        return 'Sua pressão tem aumentado. Considere consultar um médico.';
      case 'decreasing':
        return 'Sua pressão está diminuindo. Continue acompanhando.';
      default:
        return 'Sua pressão está estável, continue monitorando regularmente.';
    }
  }

  PdfColor _getTrendPdfColor(String trend) {
    switch (trend) {
      case 'increasing':
        return PdfColors.red;
      case 'decreasing':
        return PdfColors.green;
      default:
        return PdfColors.blue;
    }
  }

  // Helper para obter uma versão mais clara da cor
  PdfColor _getLightVersionOfColor(PdfColor color) {
    // Mapeamento seguro para versões "claras" das cores usadas
    if (color == PdfColors.red) return PdfColors.red50;
    if (color == PdfColors.green) return PdfColors.green50;
    if (color == PdfColors.blue) return PdfColors.blue50;
    if (color == PdfColors.orange) return PdfColors.orange50;
    if (color == PdfColors.amber) return PdfColors.amber50;
    if (color == PdfColors.purple) return PdfColors.purple50;
    return PdfColors.grey200;
  }

  // Processamento seguro de valores
  int _safeRound(dynamic value) {
    if (value == null) return 0;
    try {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  int _safeValue(dynamic value) {
    if (value == null) return 0;
    try {
      if (value is int) return value;
      if (value is double) return value.round();
      if (value is String) return int.tryParse(value) ?? double.tryParse(value)?.round() ?? 0;
      return 0;
    } catch (e) {
      return 0;
    }
  }

  CategoryData _getCategoryData(String category) {
    switch (category) {
      case 'optimal':
        return CategoryData('Ótima', PdfColors.green);
      case 'normal':
        return CategoryData('Normal', PdfColors.blue);
      case 'elevated':
        return CategoryData('Elevada', PdfColors.amber);
      case 'high_stage1':
        return CategoryData('Alta Estágio 1', PdfColors.orange);
      case 'high_stage2':
        return CategoryData('Alta Estágio 2', PdfColors.red);
      case 'crisis':
        return CategoryData('Crise', PdfColors.purple);
      default:
        return CategoryData('Desconhecida', PdfColors.grey);
    }
  }

  // Salvar o arquivo PDF
  Future<String> _savePdfFile(pw.Document pdf, String userName) async {
    try {
      final dir = await getTemporaryDirectory();

      final sanitizedName = userName
          .replaceAll(' ', '_')
          .replaceAll(RegExp(r'[^\w\s]+'), '')
          .toLowerCase();

      final dateStr = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final fileName = 'relatorio_saude_${sanitizedName}_$dateStr.pdf';
      final filePath = '${dir.path}/$fileName';

      final file = File(filePath);
      final bytes = await pdf.save();
      await file.writeAsBytes(bytes);
      return filePath;
    } catch (e) {
      print('Erro ao salvar arquivo PDF: $e');
      throw Exception('Não foi possível salvar o arquivo PDF: $e');
    }
  }

  // Método para compartilhar o PDF
  Future<void> sharePdf(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        throw Exception('Arquivo PDF não encontrado em: $filePath');
      }

      await Share.shareXFiles([XFile(filePath)], text: 'Relatório de Saúde');
    } catch (e) {
      print('Erro ao compartilhar PDF: $e');
      rethrow;
    }
  }
}