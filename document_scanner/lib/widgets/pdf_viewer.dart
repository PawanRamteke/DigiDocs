import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class PdfViewer extends StatefulWidget {
  final String filePath;
  final String fileName;

  const PdfViewer({
    super.key,
    required this.filePath,
    required this.fileName,
  });

  @override
  State<PdfViewer> createState() => _PdfViewerState();
}

class _PdfViewerState extends State<PdfViewer> {
  final Completer<PDFViewController> controller = Completer<PDFViewController>();
  int? pages = 0;
  int? currentPage = 0;
  bool isReady = false;
  String errorMessage = '';  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.fileName),),
      body: Stack(
        children: <Widget>[
          PDFView(
            filePath: widget.filePath,
            enableSwipe: true,
            swipeHorizontal: false,
            autoSpacing: false,
            pageFling: true,
            pageSnap: true,
            defaultPage: currentPage!,
            fitPolicy: FitPolicy.BOTH,
            preventLinkNavigation:
            false, // if set to true the link is handled in flutter
            backgroundColor: Color(0xFFFEF7FF),
            onRender: (_pages) {
              setState(() {
                pages = _pages;
                isReady = true;
              });
            },
            onError: (error) {
              setState(() {
                errorMessage = error.toString();
              });
              print(error.toString());
            },
            onPageError: (page, error) {
              setState(() {
                errorMessage = '$page: ${error.toString()}';
              });
              print('$page: ${error.toString()}');
            },
            onViewCreated: (PDFViewController pdfViewController) {
              controller.complete(pdfViewController);
            },
            onLinkHandler: (String? uri) {
              print('goto uri: $uri');
            },
            onPageChanged: (page, total) {
              print('page change: ${page ?? 0 + 1}/$total');
              setState(() {
                currentPage = page ?? 0;
              });
            },
          ),
          errorMessage.isEmpty
              ? !isReady
              ? Center(
            child: CircularProgressIndicator(),
          )
              : Container()
              : Center(
            child: Text(errorMessage),
          )
        ],
      ),
    );
  }

  void _goToPage(int page) {
    //controller.jumpToPage(page);
  }
}
