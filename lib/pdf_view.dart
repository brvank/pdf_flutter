import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spreadsheet_decoder/spreadsheet_decoder.dart';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

class PdfView extends StatefulWidget {
  const PdfView({Key? key}) : super(key: key);

  @override
  State<PdfView> createState() => _PdfViewState();
}

class _PdfViewState extends State<PdfView> {
  String excelPath = '', pdfPath = '', details = '';
  bool loading = false;

  late ScrollController scrollController;

  @override
  void initState() {
    super.initState();
    scrollController = ScrollController();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pdf Conversion'),
      ),
      body: Body(),
    );
  }

  Widget Body() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Column(
              children: [
                ElevatedButton(onPressed: pickFile, child: Text('Pick Files')),
                ElevatedButton(
                    onPressed: getDetails, child: Text('Get Details')),
                ElevatedButton(
                    onPressed: convertPdf, child: Text('Convert Pdf')),
              ],
            ),
            Column(
              children: [
                ElevatedButton(onPressed: openExcel, child: Text('Open Excel')),
                ElevatedButton(onPressed: openPdf, child: Text('Open Pdf')),
              ],
            )
          ],
        ),
        loading
            ? Expanded(
                flex: 1,
                child: Center(child: Text('Please wait...')),
              )
            : Expanded(
                flex: 1,
                child: SingleChildScrollView(
                  child: Container(
                      padding: EdgeInsets.all(16), child: Text(details)),
                ))
      ],
    );
  }

  Future<void> pickFile() async {
    FilePickerResult? filePickerResult = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ['xlsx']);

    if (filePickerResult != null) {
      PlatformFile file = filePickerResult.files[0];
      print(file.path!);

      excelPath = file.path!;
    }
  }

  Future<void> getDetails() async {
    if (excelPath.isEmpty) {
      await pickFile();
    }

    setState(() {
      loading = true;
    });

    if (excelPath.isNotEmpty) {
      File excelFile = File(excelPath);

      Uint8List bytes = await excelFile.readAsBytes();

      SpreadsheetDecoder decoder = SpreadsheetDecoder.decodeBytes(bytes);

      clearDetails();
      decoder.tables.forEach((key, value) {
        String sheet = key;
        add(value.name);
        add(value.rows.toString());
        if (value.rows.isEmpty) {
          add(value.toString());
        }
      });
    }

    setState(() {
      loading = false;
    });
  }

  void clearDetails() => details = '';

  void add(String temp) => details += '\n' + temp;

  Future<void> convertPdf() async {
    setState(() {
      loading = true;
    });

    pw.Document pdf = pw.Document();

    //make pdf
    if (excelPath.isNotEmpty) {
      File excelFile = File(excelPath);

      Uint8List bytes = await excelFile.readAsBytes();

      SpreadsheetDecoder decoder = SpreadsheetDecoder.decodeBytes(bytes);

      clearDetails();
      decoder.tables.forEach((key, value) {
        String sheet = key;
        add(value.name);
        add(value.rows.toString());
        if (value.rows.isEmpty) {
          add(value.toString());
        }
      });

      // Image image = Image.asset('assets/ic_launcher.png');

      pdf.addPage(pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: pw.EdgeInsets.all(32),
          build: (contetxt) {
            return pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text('AUDIT REPORT',
                      style: pw.TextStyle(color: PdfColors.grey600, fontSize: 16)),
                      pw.Text('Powered by STAQU', style: pw.TextStyle(color: PdfColors.grey, fontSize: 14),)
                    ]
                  ),
                  pw.Row(
                    mainAxisSize: pw.MainAxisSize.min,
                    children: [
                      pw.Text(decoder.tables['Summary']!.rows[1][1].toString() ?? '', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 16)),
                      pw.Text(' to ', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 16)),
                      pw.Text(decoder.tables['Summary']!.rows[2][1].toString() ?? '', style: pw.TextStyle(color: PdfColors.grey600, fontSize: 16)),
                    ],
                  )
                ]);
          }));
    }

    //save pdf

    print('pdf ki details');
    print(pdf.document.pdfPageList.pages.length);

    Directory? dir = await getTemporaryDirectory();
    pdfPath = dir.path + '/' + 'report.pdf';

    final file = File(pdfPath);

    await file.writeAsBytes(await pdf.save());

    setState(() {
      loading = false;
    });

    //open pdf
    openPdf();
  }

  Future<void> openPdf() async {
    if (pdfPath.isNotEmpty) {
      await OpenFile.open(pdfPath);
    }
  }

  Future<void> openExcel() async {
    if (excelPath.isNotEmpty) {
      await OpenFile.open(excelPath);
    }
  }
}
