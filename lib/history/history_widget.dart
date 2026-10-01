import '../flutter_flow/flutter_flow_icon_button.dart';
import '../flutter_flow/flutter_flow_theme.dart';
import '../flutter_flow/flutter_flow_util.dart';
import '../services/diagnosis_service.dart';
import 'package:flutter/material.dart';
import 'history_model.dart';
export 'history_model.dart';

class HistoryWidget extends StatefulWidget {
  const HistoryWidget({super.key});

  @override
  State<HistoryWidget> createState() => _HistoryWidgetState();
}

class _HistoryWidgetState extends State<HistoryWidget> {
  late HistoryModel _model;

  final scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _model = createModel(context, () => HistoryModel());
    
    // Load history when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _model.loadHistory();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _model.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _model.unfocusNode.canRequestFocus
          ? FocusScope.of(context).requestFocus(_model.unfocusNode)
          : FocusScope.of(context).unfocus(),
      child: Scaffold(
        key: scaffoldKey,
        backgroundColor: FlutterFlowTheme.of(context).primaryBackground,
        appBar: AppBar(
          backgroundColor: FlutterFlowTheme.of(context).primary,
          automaticallyImplyLeading: false,
          leading: FlutterFlowIconButton(
            borderColor: Colors.transparent,
            borderRadius: 30.0,
            borderWidth: 1.0,
            buttonSize: 60.0,
            icon: Icon(
              Icons.arrow_back_rounded,
              color: Colors.white,
              size: 30.0,
            ),
            onPressed: () async {
              context.pop();
            },
          ),
          title: Text(
            'History',
            style: FlutterFlowTheme.of(context).headlineMedium.override(
                  fontFamily: 'Readex Pro',
                  color: Colors.white,
                  fontSize: 22.0,
                ),
          ),
          actions: [],
          centerTitle: false,
          elevation: 2.0,
        ),
        body: SafeArea(
          top: true,
          child: RefreshIndicator(
            color: FlutterFlowTheme.of(context).primary,
            onRefresh: () async {
              await _model.refreshHistory();
              setState(() {});
            },
            child: _buildHistoryContent(),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryContent() {
    if (_model.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            FlutterFlowTheme.of(context).primary,
          ),
        ),
      );
    }

    if (_model.errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 80.0,
              color: FlutterFlowTheme.of(context).error,
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 8.0),
              child: Text(
                'Error Loading History',
                style: FlutterFlowTheme.of(context).headlineSmall.override(
                      fontFamily: 'Readex Pro',
                      color: FlutterFlowTheme.of(context).error,
                    ),
              ),
            ),
            Text(
              _model.errorMessage!,
              textAlign: TextAlign.center,
              style: FlutterFlowTheme.of(context).bodyMedium.override(
                    fontFamily: 'Readex Pro',
                    color: FlutterFlowTheme.of(context).secondaryText,
                  ),
            ),
            Padding(
              padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 0.0),
              child: ElevatedButton(
                onPressed: () async {
                  await _model.refreshHistory();
                  setState(() {});
                },
                child: Text('Retry'),
              ),
            ),
          ],
        ),
      );
    }

    if (_model.historyItems.isEmpty) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.history,
                  size: 80.0,
                  color: FlutterFlowTheme.of(context).secondaryText,
                ),
                Padding(
                  padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 8.0),
                  child: Text(
                    'No Diagnosis History',
                    style: FlutterFlowTheme.of(context).headlineSmall.override(
                          fontFamily: 'Readex Pro',
                          color: FlutterFlowTheme.of(context).secondaryText,
                        ),
                  ),
                ),
                Text(
                  'Your diagnosis history will appear here after you start using the diagnosis feature.',
                  textAlign: TextAlign.center,
                  style: FlutterFlowTheme.of(context).bodyMedium.override(
                        fontFamily: 'Readex Pro',
                        color: FlutterFlowTheme.of(context).secondaryText,
                      ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsetsDirectional.fromSTEB(0.0, 16.0, 0.0, 16.0),
      itemCount: _model.historyItems.length,
      itemBuilder: (context, index) {
        final DiagnosisRecord record = _model.historyItems[index];
        return _buildHistoryListItem(record);
      },
    );
  }

  Widget _buildHistoryListItem(DiagnosisRecord record) {
    // Get risk color based on diagnosis type
    Color getRiskColor() {
      switch (record.diagnosisType.toLowerCase()) {
        case 'melanoma':
        case 'measles':
        case 'chicken pox':
          return Color(0xFFE74C3C); // Red for high risk
        case 'acne':
        case 'eczema':
        case 'shingles':
          return Color(0xFFF39C12); // Orange for medium risk
        case 'birthmark':
        case 'skin tag':
        case 'wart':
          return Color(0xFF27AE60); // Green for low risk
        default:
          return Color(0xFF3498DB); // Blue for others
      }
    }

    return Padding(
      padding: EdgeInsetsDirectional.fromSTEB(16.0, 0.0, 16.0, 12.0),
      child: InkWell(
        splashColor: Colors.transparent,
        focusColor: Colors.transparent,
        hoverColor: Colors.transparent,
        highlightColor: Colors.transparent,
        onTap: () async {
          await _model.navigateToDiagnosisResult(context, record);
        },
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: FlutterFlowTheme.of(context).secondaryBackground,
            borderRadius: BorderRadius.circular(12.0),
            border: Border.all(
              color: FlutterFlowTheme.of(context).alternate,
              width: 1.0,
            ),
            boxShadow: [
              BoxShadow(
                blurRadius: 3.0,
                color: Color(0x33000000),
                offset: Offset(0.0, 1.0),
              )
            ],
          ),
          child: Padding(
            padding: EdgeInsetsDirectional.fromSTEB(12.0, 12.0, 12.0, 12.0),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              children: [
                // Picture Container
                Container(
                  width: 60.0,
                  height: 60.0,
                  decoration: BoxDecoration(
                    color: FlutterFlowTheme.of(context).accent4,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: FlutterFlowTheme.of(context).alternate,
                      width: 1.0,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: record.diagnosisImageLink.isNotEmpty
                        ? Image.network(
                            record.diagnosisImageLink,
                            width: 60.0,
                            height: 60.0,
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Container(
                                width: 60.0,
                                height: 60.0,
                                child: Center(
                                  child: CircularProgressIndicator(
                                    color: FlutterFlowTheme.of(context).primary,
                                    strokeWidth: 2.0,
                                  ),
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 60.0,
                                height: 60.0,
                                color: FlutterFlowTheme.of(context).alternate,
                                child: Icon(
                                  Icons.image_not_supported,
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  size: 24.0,
                                ),
                              );
                            },
                          )
                        : Icon(
                            Icons.image_outlined,
                            color: FlutterFlowTheme.of(context).secondaryText,
                            size: 24.0,
                          ),
                  ),
                ),
                
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsetsDirectional.fromSTEB(12.0, 0.0, 8.0, 0.0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // History Description Text (Diagnosis Type)
                        Text(
                          record.diagnosisType,
                          style: FlutterFlowTheme.of(context).bodyLarge.override(
                                fontFamily: 'Readex Pro',
                                fontWeight: FontWeight.w600,
                                fontSize: 16.0,
                              ),
                        ),
                        
                        // Time Text
                        Padding(
                          padding: EdgeInsetsDirectional.fromSTEB(0.0, 4.0, 0.0, 8.0),
                          child: Text(
                            record.formattedTimestamp,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Readex Pro',
                                  color: FlutterFlowTheme.of(context).secondaryText,
                                  fontSize: 12.0,
                                ),
                          ),
                        ),
                        
                        // Risk/Confidence Badge
                        Container(
                          padding: EdgeInsetsDirectional.fromSTEB(8.0, 4.0, 8.0, 4.0),
                          decoration: BoxDecoration(
                            color: getRiskColor(),
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            record.riskLevel,
                            style: FlutterFlowTheme.of(context).bodySmall.override(
                                  fontFamily: 'Readex Pro',
                                  color: Colors.white,
                                  fontSize: 10.0,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Arrow Icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: FlutterFlowTheme.of(context).secondaryText,
                  size: 16.0,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
