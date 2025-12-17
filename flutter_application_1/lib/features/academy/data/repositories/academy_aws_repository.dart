// lib/features/academy/data/repositories/academy_aws_repository.dart
import 'package:amplify_flutter/amplify_flutter.dart';
import '../../../../models/AcademyModel.dart';

/// AWS와 연동하는 Academy Repository
///
/// 주의: GraphQL 스키마에 Academy 타입이 없으므로
/// 현재는 기본 학원 정보(EDU-VICE)를 반환합니다.
///
/// 향후 다중 학원 지원이 필요하면:
/// 1. GraphQL 스키마에 Academy 타입 추가
/// 2. amplify push 실행
/// 3. 이 파일의 Mock 로직을 실제 GraphQL 쿼리로 변경
class AcademyAwsRepository {
  // 기본 학원 정보 (싱글 테넌트)
  static final _defaultAcademy = AcademyModel(
    id: 'default-academy',
    code: 'EDUVICE',
    name: 'EDU-VICE',
    address: null,
    phone: null,
    description: 'EDU-VICE 학원',
  );

  /// 학원 코드로 조회
  Future<AcademyModel?> getByCode(String code) async {
    try {
      safePrint('[AcademyAwsRepository] Fetching academy by code: $code');

      // GraphQL 스키마에 Academy 타입이 없으므로 기본값 반환
      if (code.toUpperCase() == 'EDUVICE' || code == 'default-academy') {
        safePrint('[AcademyAwsRepository] Returning default academy');
        return _defaultAcademy;
      }

      safePrint('[AcademyAwsRepository] Academy not found with code: $code');
      return null;
    } catch (e, stackTrace) {
      safePrint('[AcademyAwsRepository] getByCode error: $e');
      safePrint('[AcademyAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// ID로 학원 조회
  Future<AcademyModel?> getById(String id) async {
    try {
      safePrint('[AcademyAwsRepository] Fetching academy by ID: $id');

      // GraphQL 스키마에 Academy 타입이 없으므로 기본값 반환
      if (id == 'default-academy') {
        safePrint('[AcademyAwsRepository] Returning default academy');
        return _defaultAcademy;
      }

      safePrint('[AcademyAwsRepository] Academy not found with ID: $id');
      return null;
    } catch (e, stackTrace) {
      safePrint('[AcademyAwsRepository] getById error: $e');
      safePrint('[AcademyAwsRepository] Stack trace: $stackTrace');
      return null;
    }
  }

  /// 모든 학원 조회
  Future<List<AcademyModel>> getAll() async {
    try {
      safePrint('[AcademyAwsRepository] Fetching all academies...');

      // GraphQL 스키마에 Academy 타입이 없으므로 기본 학원만 반환
      return [_defaultAcademy];
    } catch (e, stackTrace) {
      safePrint('[AcademyAwsRepository] getAll error: $e');
      safePrint('[AcademyAwsRepository] Stack trace: $stackTrace');
      return [];
    }
  }

  /// 학원 생성 (Owner 전용)
  /// 현재는 지원하지 않음 (싱글 테넌트)
  Future<AcademyModel?> createAcademy({
    required String code,
    required String name,
    String? address,
    String? phone,
    String? description,
  }) async {
    safePrint('[AcademyAwsRepository] createAcademy: Not supported (single tenant mode)');
    safePrint('[AcademyAwsRepository] To enable multi-tenant:');
    safePrint('[AcademyAwsRepository] 1. Add Academy type to GraphQL schema');
    safePrint('[AcademyAwsRepository] 2. Run amplify push');
    safePrint('[AcademyAwsRepository] 3. Update this repository');

    // 임시로 기본 학원 반환
    return _defaultAcademy;
  }

  /// 학원 수정
  /// 현재는 지원하지 않음 (싱글 테넌트)
  Future<AcademyModel?> updateAcademy(AcademyModel academy) async {
    safePrint('[AcademyAwsRepository] updateAcademy: Not supported (single tenant mode)');
    return academy;
  }
}
