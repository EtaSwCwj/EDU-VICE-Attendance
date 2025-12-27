import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';
import 'package:http/http.dart' as http;

/// AWS Textract 서비스
/// - 이미지에서 텍스트 + bounding box 추출
class TextractService {
  static const _region = 'ap-northeast-2'; // 서울 리전
  
  /// 이미지 파일에서 텍스트와 bounding box 추출
  Future<TextractResult> analyzeDocument(File imageFile) async {
    try {
      safePrint('[Textract] 분석 시작: ${imageFile.path}');
      
      // 이미지를 base64로 인코딩
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);
      
      // AWS 자격증명 가져오기
      final credentials = await _getCredentials();
      if (credentials == null) {
        throw Exception('AWS 자격증명을 가져올 수 없습니다');
      }
      
      // Textract API 호출
      final result = await _callTextract(base64Image, credentials);
      
      safePrint('[Textract] 분석 완료: ${result.blocks.length}개 블록');
      return result;
      
    } catch (e) {
      safePrint('[Textract] ERROR: $e');
      rethrow;
    }
  }
  
  /// Cognito에서 AWS 자격증명 가져오기
  Future<AWSCredentials?> _getCredentials() async {
    try {
      final session = await Amplify.Auth.fetchAuthSession();
      
      if (session is CognitoAuthSession) {
        final credentials = session.credentialsResult.value;
        return AWSCredentials(
          credentials.accessKeyId,
          credentials.secretAccessKey,
          credentials.sessionToken,
        );
      }
      return null;
    } catch (e) {
      safePrint('[Textract] 자격증명 가져오기 실패: $e');
      return null;
    }
  }
  
  /// Textract DetectDocumentText API 호출
  Future<TextractResult> _callTextract(
    String base64Image, 
    AWSCredentials credentials,
  ) async {
    final signer = AWSSigV4Signer(
      credentialsProvider: AWSCredentialsProvider(credentials),
    );
    
    final endpoint = Uri.parse('https://textract.$_region.amazonaws.com');
    
    final body = jsonEncode({
      'Document': {
        'Bytes': base64Image,
      },
    });
    
    final bodyBytes = utf8.encode(body);
    
    final request = AWSHttpRequest(
      method: AWSHttpMethod.post,
      uri: endpoint,
      headers: {
        'Content-Type': 'application/x-amz-json-1.1',
        'X-Amz-Target': 'Textract.DetectDocumentText',
        'Host': 'textract.$_region.amazonaws.com',
      },
      body: bodyBytes,
    );
    
    final signedRequest = await signer.sign(
      request,
      credentialScope: AWSCredentialScope(
        region: _region,
        service: AWSService.textract,
      ),
    );
    
    final response = await http.post(
      signedRequest.uri,
      headers: Map<String, String>.from(signedRequest.headers),
      body: bodyBytes,  // 원본 body 사용
    );
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body) as Map<String, dynamic>;
      return TextractResult.fromJson(data);
    } else {
      safePrint('[Textract] API 에러: ${response.statusCode}');
      safePrint('[Textract] 응답: ${response.body}');
      throw Exception('Textract API 호출 실패: ${response.statusCode} - ${response.body}');
    }
  }
}

/// Textract 분석 결과
class TextractResult {
  final List<TextBlock> blocks;
  
  TextractResult({required this.blocks});
  
  factory TextractResult.fromJson(Map<String, dynamic> json) {
    final blocks = <TextBlock>[];
    final blocksJson = json['Blocks'] as List<dynamic>? ?? [];
    
    for (final blockJson in blocksJson) {
      final block = blockJson as Map<String, dynamic>;
      final blockType = block['BlockType'] as String?;
      
      // LINE과 WORD 블록만 추출
      if (blockType == 'LINE' || blockType == 'WORD') {
        final geometry = block['Geometry'] as Map<String, dynamic>?;
        final boundingBox = geometry?['BoundingBox'] as Map<String, dynamic>?;
        
        if (boundingBox != null) {
          blocks.add(TextBlock(
            text: block['Text'] as String? ?? '',
            type: blockType ?? '',
            confidence: (block['Confidence'] as num?)?.toDouble() ?? 0,
            boundingBox: BoundingBox(
              left: (boundingBox['Left'] as num?)?.toDouble() ?? 0,
              top: (boundingBox['Top'] as num?)?.toDouble() ?? 0,
              width: (boundingBox['Width'] as num?)?.toDouble() ?? 0,
              height: (boundingBox['Height'] as num?)?.toDouble() ?? 0,
            ),
          ));
        }
      }
    }
    
    return TextractResult(blocks: blocks);
  }
  
  /// 특정 텍스트를 포함하는 블록 찾기
  List<TextBlock> findBlocksContaining(String text) {
    return blocks.where((b) => b.text.contains(text)).toList();
  }
  
  /// 문제 번호 패턴으로 블록 찾기 (예: "1", "1.", "1번", "(1)")
  List<TextBlock> findProblemNumbers() {
    final pattern = RegExp(r'^[\(\[]?\d+[\)\].]?$|^\d+번$');
    return blocks.where((b) => pattern.hasMatch(b.text.trim())).toList();
  }
}

/// 텍스트 블록
class TextBlock {
  final String text;
  final String type; // LINE or WORD
  final double confidence;
  final BoundingBox boundingBox;
  
  TextBlock({
    required this.text,
    required this.type,
    required this.confidence,
    required this.boundingBox,
  });
  
  @override
  String toString() => 'TextBlock("$text", ${boundingBox.toRect()})';
}

/// Bounding Box (0~1 비율 좌표)
class BoundingBox {
  final double left;   // 0~1
  final double top;    // 0~1
  final double width;  // 0~1
  final double height; // 0~1
  
  BoundingBox({
    required this.left,
    required this.top,
    required this.width,
    required this.height,
  });
  
  double get right => left + width;
  double get bottom => top + height;
  
  /// 실제 픽셀 좌표로 변환
  Map<String, int> toPixels(int imageWidth, int imageHeight) {
    return {
      'left': (left * imageWidth).round(),
      'top': (top * imageHeight).round(),
      'width': (width * imageWidth).round(),
      'height': (height * imageHeight).round(),
    };
  }
  
  String toRect() => 'Rect(${left.toStringAsFixed(2)}, ${top.toStringAsFixed(2)}, ${width.toStringAsFixed(2)}, ${height.toStringAsFixed(2)})';
}
