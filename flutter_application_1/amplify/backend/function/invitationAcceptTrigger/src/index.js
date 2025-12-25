const { DynamoDBClient } = require('@aws-sdk/client-dynamodb');
const { DynamoDBDocumentClient, PutCommand } = require('@aws-sdk/lib-dynamodb');
const { v4: uuidv4 } = require('uuid');

const client = new DynamoDBClient({ region: 'ap-northeast-2' });
const docClient = DynamoDBDocumentClient.from(client);

// 테이블 이름 하드코딩
const ACADEMY_MEMBER_TABLE = 'AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev';

exports.handler = async (event) => {
  console.log('[invitationAcceptTrigger] Event:', JSON.stringify(event, null, 2));

  for (const record of event.Records) {
    if (record.eventName !== 'MODIFY') {
      console.log('[invitationAcceptTrigger] Skip:', record.eventName);
      continue;
    }

    const newImage = record.dynamodb.NewImage;
    const oldImage = record.dynamodb.OldImage;

    const newStatus = newImage?.status?.S;
    const oldStatus = oldImage?.status?.S;

    console.log('[invitationAcceptTrigger] Status:', oldStatus, '->', newStatus);

    if (newStatus === 'accepted' && oldStatus !== 'accepted') {
      const userId = newImage.usedBy?.S;
      const academyId = newImage.academyId?.S;
      const role = newImage.role?.S;

      console.log('[invitationAcceptTrigger] Creating:', { userId, academyId, role });

      if (!userId || !academyId || !role) {
        console.error('[invitationAcceptTrigger] Missing fields');
        continue;
      }

      try {
        const now = new Date().toISOString();
        const item = {
          id: uuidv4(),
          __typename: 'AcademyMember',
          userId,
          academyId,
          role,
          createdAt: now,
          updatedAt: now,
          _version: 1,
          _lastChangedAt: Date.now()
        };

        await docClient.send(new PutCommand({
          TableName: ACADEMY_MEMBER_TABLE,
          Item: item
        }));

        console.log('[invitationAcceptTrigger] Created:', item.id);
      } catch (error) {
        console.error('[invitationAcceptTrigger] Error:', error);
        throw error;
      }
    }
  }

  return { statusCode: 200, body: 'OK' };
};
