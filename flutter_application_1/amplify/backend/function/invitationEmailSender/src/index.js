/**
 * invitationEmailSender Lambda Function
 *
 * Invitation 생성 시 트리거되어 이메일을 발송하는 함수
 * 현재는 SES 설정이 없으므로 로그만 출력
 */

const AWS = require('aws-sdk');

// AWS 클라이언트 초기화
const dynamodb = new AWS.DynamoDB.DocumentClient();
// SES 클라이언트 초기화 (향후 사용)
// const ses = new AWS.SES({ region: 'ap-northeast-2' });

exports.handler = async (event) => {
    console.log('[invitationEmailSender] 함수 시작');
    console.log('[invitationEmailSender] Event:', JSON.stringify(event, null, 2));

    try {
        // DynamoDB 스트림 이벤트 처리
        for (const record of event.Records) {
            console.log('[invitationEmailSender] 레코드 처리 중:', record.eventName);

            // INSERT 이벤트만 처리 (새로운 초대 생성)
            if (record.eventName === 'INSERT') {
                const invitation = record.dynamodb.NewImage;

                // 초대 정보 추출
                const invitationData = {
                    id: invitation.id?.S,
                    academyId: invitation.academyId?.S,
                    inviterName: invitation.inviterName?.S,
                    inviteeEmail: invitation.inviteeEmail?.S,
                    inviteeRole: invitation.inviteeRole?.S,
                    invitationCode: invitation.invitationCode?.S,
                    expiresAt: invitation.expiresAt?.S,
                    status: invitation.status?.S
                };

                console.log('[invitationEmailSender] 초대 정보:', invitationData);

                // Academy 정보 조회
                const academyName = await getAcademyName(invitationData.academyId);
                invitationData.academyName = academyName;

                // 이메일 발송
                await sendInvitationEmail(invitationData);
            }
        }

        return {
            statusCode: 200,
            body: JSON.stringify({
                message: '이메일 발송 처리 완료',
                processedRecords: event.Records.length
            })
        };

    } catch (error) {
        console.error('[invitationEmailSender] ERROR:', error);
        throw error;
    }
};

/**
 * 초대 이메일 발송 (현재는 로그만 출력)
 */
async function sendInvitationEmail(invitation) {
    console.log('[invitationEmailSender] 이메일 발송 시뮬레이션');

    // 이메일 내용 구성
    const emailData = {
        to: invitation.inviteeEmail,
        subject: `[EDU-VICE] ${invitation.inviterName}님이 초대를 보냈습니다`,
        body: generateEmailBody(invitation)
    };

    console.log('[invitationEmailSender] 이메일 데이터:', emailData);

    // TODO: SES 설정 후 아래 코드 활성화
    /*
    const params = {
        Source: 'noreply@your-domain.com', // 발신자 이메일 (SES에서 검증된 이메일)
        Destination: {
            ToAddresses: [invitation.inviteeEmail]
        },
        Message: {
            Subject: {
                Data: emailData.subject,
                Charset: 'UTF-8'
            },
            Body: {
                Html: {
                    Data: emailData.body,
                    Charset: 'UTF-8'
                }
            }
        }
    };

    try {
        const result = await ses.sendEmail(params).promise();
        console.log('[invitationEmailSender] SES 발송 성공:', result.MessageId);
        return result;
    } catch (error) {
        console.error('[invitationEmailSender] SES 발송 실패:', error);
        throw error;
    }
    */

    // 현재는 로그만 출력
    console.log('[invitationEmailSender] 이메일 발송 완료 (시뮬레이션)');
    return { MessageId: 'simulation-' + Date.now() };
}

/**
 * 이메일 본문 생성
 */
function generateEmailBody(invitation) {
    const expirationDate = new Date(invitation.expiresAt).toLocaleString('ko-KR', {
        year: 'numeric',
        month: 'long',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });

    const roleName = getRoleName(invitation.inviteeRole);
    const academyName = invitation.academyName || '학원';

    // 향후 웹페이지 연결용 placeholder
    const acceptLink = `https://edu-vice.com/accept-invitation?code=${invitation.invitationCode}`;

    return `<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>EDU-VICE 학원 초대</title>
</head>
<body style="font-family: Arial, sans-serif; padding: 20px; background-color: #f5f5f5;">
  <div style="max-width: 600px; margin: 0 auto; background-color: white; border-radius: 8px; overflow: hidden; box-shadow: 0 2px 8px rgba(0,0,0,0.1);">

    <!-- 헤더 -->
    <div style="background-color: #26A69A; padding: 30px 20px; text-align: center;">
      <h2 style="color: white; margin: 0; font-size: 24px;">🎓 EDU-VICE 학원 초대</h2>
    </div>

    <!-- 본문 -->
    <div style="padding: 40px 30px;">
      <p style="font-size: 16px; line-height: 1.6; color: #333; margin-bottom: 20px;">
        안녕하세요!
      </p>

      <p style="font-size: 16px; line-height: 1.6; color: #333; margin-bottom: 30px;">
        <strong style="color: #26A69A;">${invitation.inviterName}</strong>님이
        <strong style="color: #26A69A;">${academyName}</strong>에
        <strong style="color: #26A69A;">${roleName}</strong>(으)로 초대했습니다.
      </p>

      <!-- 초대 코드 박스 -->
      <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 30px 0; border-left: 4px solid #26A69A;">
        <p style="margin: 0 0 10px 0; color: #666; font-size: 14px;">초대 코드</p>
        <p style="margin: 0; font-size: 24px; font-weight: bold; color: #26A69A; font-family: 'Courier New', monospace; letter-spacing: 2px;">
          ${invitation.invitationCode}
        </p>
      </div>

      <!-- 수락 버튼 -->
      <div style="text-align: center; margin: 30px 0;">
        <a href="${acceptLink}"
           style="display: inline-block; background-color: #26A69A; color: white; padding: 15px 40px;
                  text-decoration: none; border-radius: 8px; font-size: 16px; font-weight: bold;
                  box-shadow: 0 2px 4px rgba(0,0,0,0.2);">
          초대 수락하기
        </a>
      </div>

      <!-- 안내 사항 -->
      <div style="background-color: #fff3cd; border: 1px solid #ffc107; padding: 15px; border-radius: 8px; margin: 30px 0;">
        <p style="margin: 0; color: #856404; font-size: 14px;">
          ⏰ 이 초대는 <strong>${expirationDate}</strong>까지 유효합니다.
        </p>
      </div>

      <!-- 가입 안내 -->
      <div style="margin: 30px 0; padding: 20px; background-color: #f8f9fa; border-radius: 8px;">
        <p style="margin: 0 0 15px 0; font-weight: bold; color: #333;">가입 방법:</p>
        <ol style="margin: 0; padding-left: 20px; color: #666; line-height: 1.8;">
          <li>EDU-VICE 앱을 다운로드하고 설치하세요</li>
          <li>"초대 코드로 가입" 버튼을 클릭하세요</li>
          <li>위의 초대 코드를 입력하세요</li>
          <li>가입 절차를 완료하세요</li>
        </ol>
      </div>
    </div>

    <!-- 푸터 -->
    <div style="background-color: #f8f9fa; padding: 20px 30px; border-top: 1px solid #dee2e6;">
      <p style="color: #999; font-size: 12px; margin: 0; text-align: center;">
        EDU-VICE - 교재 중심 학원 관리 시스템
      </p>
      <p style="color: #999; font-size: 12px; margin: 10px 0 0 0; text-align: center;">
        이 이메일은 자동으로 발송되었습니다.
      </p>
    </div>

  </div>
</body>
</html>`;
}

/**
 * Academy 정보 조회
 */
async function getAcademyName(academyId) {
    try {
        const tableName = process.env.API_EDUVICE_ACADEMYTABLE_NAME;

        if (!tableName) {
            console.error('[invitationEmailSender] Academy 테이블 이름을 찾을 수 없습니다');
            return '학원';
        }

        const result = await dynamodb.get({
            TableName: tableName,
            Key: { id: academyId }
        }).promise();

        if (result.Item) {
            console.log('[invitationEmailSender] Academy 조회 성공:', result.Item.name);
            return result.Item.name;
        } else {
            console.warn('[invitationEmailSender] Academy를 찾을 수 없습니다:', academyId);
            return '학원';
        }
    } catch (error) {
        console.error('[invitationEmailSender] Academy 조회 실패:', error);
        return '학원';
    }
}

/**
 * 역할 코드를 한글명으로 변환
 */
function getRoleName(role) {
    const roleNames = {
        'OWNER': '원장',
        'TEACHER': '선생님',
        'STUDENT': '학생'
    };
    return roleNames[role?.toUpperCase()] || role;
}