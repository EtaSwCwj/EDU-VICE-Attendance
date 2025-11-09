# =========================
# EDU-VICE — GraphQL Schema
# 22-3: 도메인 확정 + 권한 강화 + 인덱스
# =========================

enum AssignmentStatus {
  ASSIGNED
  DONE
}

type Assignment
  @model
  @auth(rules: [
    # 원장(owners 그룹): 전체 CRUD
    { allow: groups, groups: ["owners"], operations: [create, read, update, delete] },

    # 교사 소유: 생성/조회/수정/삭제
    { allow: owner, ownerField: "teacherUsername", operations: [create, read, update, delete] },

    # 학생 소유: 조회/상태 갱신(수정)
    { allow: owner, ownerField: "studentUsername", operations: [read, update] }
  ])
  # 교사별 과제 조회/정렬(기본: dueDate 정렬)
  @index(name: "byTeacher", queryField: "assignmentsByTeacher", fields: ["teacherUsername", "dueDate"])
  # 학생별 과제 조회/정렬(기본: dueDate 정렬)
  @index(name: "byStudent", queryField: "assignmentsByStudent", fields: ["studentUsername", "dueDate"])
{
  id: ID!
  title: String!
  description: String
  status: AssignmentStatus!

  # 소유자 필드(권한 기준)
  teacherUsername: String!
  studentUsername: String!

  # 정렬/검색 키(옵션)
  dueDate: AWSDateTime

  # @model 기본 타임스탬프
  createdAt: AWSDateTime
  updatedAt: AWSDateTime
}

type Student
  @model
  @auth(rules: [
    # 원장 전체 CRUD
    { allow: groups, groups: ["owners"], operations: [create, read, update, delete] },

    # 본인(학생)만 자신의 프로필 read/update
    { allow: owner, ownerField: "username", operations: [read, update] },

    # 교사는 학생 프로필 read 허용
    { allow: groups, groups: ["teachers"], operations: [read] }
  ])
  # username 단건 조회/중복 방지
  @index(name: "byUsername", queryField: "getStudentByUsername", fields: ["username"])
{
  id: ID!
  username: String!   # Cognito username(고유)
  name: String
  grade: String
  classId: String
  phone: String
  note: String

  createdAt: AWSDateTime
  updatedAt: AWSDateTime
}

type Teacher
  @model
  @auth(rules: [
    # 원장 전체 CRUD
    { allow: groups, groups: ["owners"], operations: [create, read, update, delete] },

    # 본인(교사) 프로필 read/update
    { allow: owner, ownerField: "username", operations: [read, update] },

    # 교사끼리 서로 read 허용(운영 편의)
    { allow: groups, groups: ["teachers"], operations: [read] }
  ])
  @index(name: "byUsername", queryField: "getTeacherByUsername", fields: ["username"])
{
  id: ID!
  username: String!   # Cognito username(고유)
  name: String
  subject: String
  phone: String
  note: String

  createdAt: AWSDateTime
  updatedAt: AWSDateTime
}
