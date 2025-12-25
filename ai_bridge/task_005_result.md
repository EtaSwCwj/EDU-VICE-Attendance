# TASK_005: AWS DynamoDB 전체 테이블 덤프 결과

**작성자**: 윈 후임 (Sonnet)
**작성일**: 2025-12-20
**상태**: ✅ 완료

---

## 📊 테이블 목록

총 10개의 DynamoDB 테이블:

1. Academy-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
2. AcademyMember-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
3. AppUser-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
4. Assignment-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
5. Book-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
6. Chapter-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
7. Lesson-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
8. Student-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
9. Teacher-3ozlrdq2pvesbe2mcnxgs5e6nu-dev
10. TeacherStudent-3ozlrdq2pvesbe2mcnxgs5e6nu-dev

---

## 🔐 Cognito Users

```json
{
    "Users": [
        {
            "Username": "maknae12@gmail.com",
            "Attributes": [
                {
                    "Name": "email",
                    "Value": "maknae12@gmail.com"
                },
                {
                    "Name": "email_verified",
                    "Value": "true"
                },
                {
                    "Name": "name",
                    "Value": "주요한"
                },
                {
                    "Name": "sub",
                    "Value": "24e80dbc-b091-7097-6825-b6bf1e5331ca"
                }
            ],
            "UserCreateDate": "2025-12-20T21:24:35.628000+09:00",
            "UserLastModifiedDate": "2025-12-20T21:24:47.201000+09:00",
            "Enabled": true,
            "UserStatus": "CONFIRMED"
        },
        {
            "Username": "teacher_test2",
            "Attributes": [
                {
                    "Name": "email",
                    "Value": "teacher_test2@local.invalid"
                },
                {
                    "Name": "email_verified",
                    "Value": "true"
                },
                {
                    "Name": "sub",
                    "Value": "54882dec-8021-7093-fda2-9aef7711b52a"
                }
            ],
            "UserCreateDate": "2025-12-12T03:33:33.040000+09:00",
            "UserLastModifiedDate": "2025-12-12T03:35:28.458000+09:00",
            "Enabled": true,
            "UserStatus": "FORCE_CHANGE_PASSWORD"
        },
        {
            "Username": "student_test2@gmail.com",
            "Attributes": [
                {
                    "Name": "email",
                    "Value": "student_test2@gmail.com"
                },
                {
                    "Name": "email_verified",
                    "Value": "false"
                },
                {
                    "Name": "name",
                    "Value": "주요한"
                },
                {
                    "Name": "sub",
                    "Value": "74a80d0c-1021-70b7-e77a-03b4a8915ea5"
                }
            ],
            "UserCreateDate": "2025-12-16T23:59:53.880000+09:00",
            "UserLastModifiedDate": "2025-12-17T00:01:24.023000+09:00",
            "Enabled": true,
            "UserStatus": "CONFIRMED"
        },
        {
            "Username": "teacher_test1",
            "Attributes": [
                {
                    "Name": "email",
                    "Value": "teacher_test1@local.invalid"
                },
                {
                    "Name": "email_verified",
                    "Value": "true"
                },
                {
                    "Name": "sub",
                    "Value": "b448adfc-90e1-700e-8be5-aae145ac9024"
                }
            ],
            "UserCreateDate": "2025-11-08T23:37:18.186000+09:00",
            "UserLastModifiedDate": "2025-12-12T03:39:44.516000+09:00",
            "Enabled": true,
            "UserStatus": "CONFIRMED"
        },
        {
            "Username": "student_test1",
            "Attributes": [
                {
                    "Name": "email",
                    "Value": "student_test1@local.invalid"
                },
                {
                    "Name": "email_verified",
                    "Value": "true"
                },
                {
                    "Name": "sub",
                    "Value": "d4d8ad2c-0021-70be-34be-8ce9c95f8348"
                }
            ],
            "UserCreateDate": "2025-11-08T23:36:13.196000+09:00",
            "UserLastModifiedDate": "2025-11-09T01:17:01.025000+09:00",
            "Enabled": true,
            "UserStatus": "CONFIRMED"
        },
        {
            "Username": "owner_test1",
            "Attributes": [
                {
                    "Name": "email",
                    "Value": "owner_test1@local.invalid"
                },
                {
                    "Name": "email_verified",
                    "Value": "true"
                },
                {
                    "Name": "sub",
                    "Value": "e4d84d4c-e0a1-7069-342f-fffadfcc80b6"
                }
            ],
            "UserCreateDate": "2025-11-08T23:36:59.228000+09:00",
            "UserLastModifiedDate": "2025-11-09T01:19:36.160000+09:00",
            "Enabled": true,
            "UserStatus": "CONFIRMED"
        }
    ]
}
```

---

## 👤 AppUser 테이블

**Count**: 3

```json
{
    "Items": [
        {
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "cognitoUsername": {
                "S": "owner_test1"
            },
            "id": {
                "S": "user-owner-001"
            },
            "email": {
                "S": "owner_test1@local.invalid"
            },
            "name": {
                "S": "원장님"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            }
        },
        {
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "cognitoUsername": {
                "S": "student_test1"
            },
            "id": {
                "S": "user-student-001"
            },
            "email": {
                "S": "student_test1@local.invalid"
            },
            "name": {
                "S": "테스트학생"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            }
        },
        {
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "cognitoUsername": {
                "S": "teacher_test1"
            },
            "id": {
                "S": "user-teacher-001"
            },
            "email": {
                "S": "teacher_test1@local.invalid"
            },
            "name": {
                "S": "홍길동 선생님"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            }
        }
    ],
    "Count": 3,
    "ScannedCount": 3,
    "ConsumedCapacity": null
}
```

---

## 🏫 AcademyMember 테이블

**Count**: 3

```json
{
    "Items": [
        {
            "academyId": {
                "S": "academy-001"
            },
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "id": {
                "S": "member-003"
            },
            "role": {
                "S": "student"
            },
            "userId": {
                "S": "user-student-001"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            }
        },
        {
            "academyId": {
                "S": "academy-001"
            },
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "id": {
                "S": "member-001"
            },
            "role": {
                "S": "owner"
            },
            "userId": {
                "S": "user-owner-001"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            }
        },
        {
            "academyId": {
                "S": "academy-001"
            },
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "id": {
                "S": "member-002"
            },
            "role": {
                "S": "teacher"
            },
            "userId": {
                "S": "user-teacher-001"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            }
        }
    ],
    "Count": 3,
    "ScannedCount": 3,
    "ConsumedCapacity": null
}
```

---

## 🏢 Academy 테이블

**Count**: 1

```json
{
    "Items": [
        {
            "code": {
                "S": "MATH2025"
            },
            "updatedAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "createdAt": {
                "S": "2025-01-01T00:00:00.000Z"
            },
            "address": {
                "S": "서울시 강남구"
            },
            "id": {
                "S": "academy-001"
            },
            "phone": {
                "S": "02-1234-5678"
            },
            "name": {
                "S": "예두비 수학 학원"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

---

## 📝 Assignment 테이블

**Count**: 12

```json
{
    "Items": [
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-11T19:37:11.717Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-11T19:37:11.717Z"
            },
            "id": {
                "S": "430168b4-92f5-40b2-af1c-b7bb3c97ce8e"
            },
            "title": {
                "S": "아무 제목"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-11T19:56:32.312Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-11T19:56:32.312Z"
            },
            "id": {
                "S": "a0f4b34c-2dd0-4dbd-bfcf-903e5230d570"
            },
            "title": {
                "S": "숙제 제목"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-11-08T19:13:06.319Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-11-08T19:13:06.319Z"
            },
            "description": {
                "S": "테스트1"
            },
            "id": {
                "S": "d22740c3-211e-4256-b759-fd1507aacb6f"
            },
            "title": {
                "S": "숙제"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-11-09T07:26:11.887Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-11-09T07:26:11.887Z"
            },
            "description": {
                "S": "임시"
            },
            "id": {
                "S": "248b5e66-4a27-4c02-a55c-3560cd452037"
            },
            "title": {
                "S": "임시테스트"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-14T10:14:19.715Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "dueDate": {
                "S": "2025-12-18T14:59:00.000Z"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-14T10:14:19.715Z"
            },
            "id": {
                "S": "54825f76-d59c-4350-a872-24a6279842a6"
            },
            "title": {
                "S": "숙제 테스트"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-13T17:34:07.669Z"
            },
            "dueDate": {
                "S": "2025-12-17T14:59:00.000Z"
            },
            "status": {
                "S": "DONE"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "createdAt": {
                "S": "2025-12-13T15:06:50.357Z"
            },
            "id": {
                "S": "5f8a4b1b-1e92-471f-ad2d-e6f33afc7a88"
            },
            "title": {
                "S": "숙제"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-11T19:14:52.011Z"
            },
            "studentUsername": {
                "S": "student1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-11T19:14:52.011Z"
            },
            "description": {
                "S": "test"
            },
            "id": {
                "S": "053d2345-83d6-44ac-b985-cd61cd15bc25"
            },
            "title": {
                "S": "숙제 제목 1"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-13T11:43:20.142Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-13T11:43:20.142Z"
            },
            "id": {
                "S": "3c674711-a91c-4430-852a-68e9e127ba67"
            },
            "title": {
                "S": "숙제"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-14T07:10:40.592Z"
            },
            "dueDate": {
                "S": "2025-12-15T14:59:00.000Z"
            },
            "status": {
                "S": "DONE"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "createdAt": {
                "S": "2025-12-13T13:08:58.555Z"
            },
            "id": {
                "S": "aed6b943-7e7e-4602-8c01-48754a3c399e"
            },
            "title": {
                "S": "숙제"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-13T13:08:10.190Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-13T13:08:10.190Z"
            },
            "id": {
                "S": "df5a56ac-b529-4d05-ac53-1991872c8b60"
            },
            "title": {
                "S": "숙제"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-14T10:13:45.948Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-14T10:13:45.948Z"
            },
            "id": {
                "S": "6b851a58-2b6c-4b43-843a-82d1b783430c"
            },
            "title": {
                "S": "숙제 테스트"
            }
        },
        {
            "__typename": {
                "S": "Assignment"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "S": "2025-12-11T20:03:14.088Z"
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "status": {
                "S": "ASSIGNED"
            },
            "createdAt": {
                "S": "2025-12-11T20:03:14.088Z"
            },
            "id": {
                "S": "3b24d9cb-982f-4211-8003-88cca511f6b2"
            },
            "title": {
                "S": "숙제 제목"
            }
        }
    ],
    "Count": 12,
    "ScannedCount": 12,
    "ConsumedCapacity": null
}
```

---

## 📚 Book 테이블

**Count**: 1

```json
{
    "Items": [
        {
            "subject": {
                "S": "MATH"
            },
            "__typename": {
                "S": "Book"
            },
            "grade": {
                "S": "ELEMENTARY"
            },
            "updatedAt": {
                "NULL": true
            },
            "year": {
                "N": "2025"
            },
            "createdAt": {
                "NULL": true
            },
            "id": {
                "S": "52d5ef3f-7e78-44c6-98e8-cf7be3fcbb40"
            },
            "title": {
                "S": "교재 테스트"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

---

## 📖 Chapter 테이블

**Count**: 3

```json
{
    "Items": [
        {
            "__typename": {
                "S": "Chapter"
            },
            "orderIndex": {
                "N": "1"
            },
            "bookId": {
                "S": "52d5ef3f-7e78-44c6-98e8-cf7be3fcbb40"
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "endPage": {
                "NULL": true
            },
            "id": {
                "S": "1c9c7276-5c89-44c2-8130-df862423d6b1"
            },
            "startPage": {
                "NULL": true
            },
            "title": {
                "S": "일"
            }
        },
        {
            "__typename": {
                "S": "Chapter"
            },
            "orderIndex": {
                "N": "3"
            },
            "bookId": {
                "S": "52d5ef3f-7e78-44c6-98e8-cf7be3fcbb40"
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "endPage": {
                "NULL": true
            },
            "id": {
                "S": "705b8588-f003-462c-b237-5334cb36cd57"
            },
            "startPage": {
                "NULL": true
            },
            "title": {
                "S": "삼"
            }
        },
        {
            "__typename": {
                "S": "Chapter"
            },
            "orderIndex": {
                "N": "2"
            },
            "bookId": {
                "S": "52d5ef3f-7e78-44c6-98e8-cf7be3fcbb40"
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "endPage": {
                "NULL": true
            },
            "id": {
                "S": "0165328c-b92b-45dc-962f-259caa221e90"
            },
            "startPage": {
                "NULL": true
            },
            "title": {
                "S": "이"
            }
        }
    ],
    "Count": 3,
    "ScannedCount": 3,
    "ConsumedCapacity": null
}
```

---

## 📅 Lesson 테이블

**Count**: 1

```json
{
    "Items": [
        {
            "subject": {
                "S": "MATH"
            },
            "__typename": {
                "S": "Lesson"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "studentUsernames": {
                "L": [
                    {
                        "S": "student_test1"
                    }
                ]
            },
            "status": {
                "S": "SCHEDULED"
            },
            "createdAt": {
                "NULL": true
            },
            "score": {
                "NULL": true
            },
            "chapterId": {
                "NULL": true
            },
            "startTime": {
                "S": "01:00:00"
            },
            "endTime": {
                "NULL": true
            },
            "bookId": {
                "S": "2c57374c-fcf4-4492-8ec3-c9b462532c11"
            },
            "scheduledDate": {
                "S": "2025-12-16"
            },
            "updatedAt": {
                "NULL": true
            },
            "id": {
                "S": "c4270948-8939-47be-af81-439607b2f83d"
            },
            "duration": {
                "N": "60"
            },
            "title": {
                "S": "수업"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

---

## 🎓 Student 테이블

**Count**: 4

```json
{
    "Items": [
        {
            "__typename": {
                "S": "Student"
            },
            "grade": {
                "S": "1"
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "username": {
                "S": "test1"
            },
            "id": {
                "S": "216d480a-dd80-43eb-9590-a2b343f0310c"
            },
            "name": {
                "S": "test1"
            }
        },
        {
            "__typename": {
                "S": "Student"
            },
            "grade": {
                "NULL": true
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "username": {
                "S": "maknae12@gmail.com"
            },
            "id": {
                "S": "ecb5de59-8ad2-413f-b9ad-e562966adf03"
            },
            "name": {
                "S": "주요한"
            }
        },
        {
            "__typename": {
                "S": "Student"
            },
            "grade": {
                "NULL": true
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "username": {
                "S": "student_test2@gmail.com"
            },
            "id": {
                "S": "0d0846f3-a7fc-4529-9011-df3fe20c5230"
            },
            "name": {
                "S": "주요한"
            }
        },
        {
            "__typename": {
                "S": "Student"
            },
            "grade": {
                "NULL": true
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "username": {
                "S": "student_test1"
            },
            "id": {
                "S": "411e5284-d956-4097-ae86-048ff06a88f3"
            },
            "name": {
                "S": "student_test1"
            }
        }
    ],
    "Count": 4,
    "ScannedCount": 4,
    "ConsumedCapacity": null
}
```

---

## 👨‍🏫 Teacher 테이블

**Count**: 2

```json
{
    "Items": [
        {
            "__typename": {
                "S": "Teacher"
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "username": {
                "S": "teacher_test1"
            },
            "subjects": {
                "NULL": true
            },
            "id": {
                "S": "92c702f6-fe44-46a1-bf90-5b7b87c306b9"
            },
            "name": {
                "S": "홍길동"
            }
        },
        {
            "__typename": {
                "S": "Teacher"
            },
            "updatedAt": {
                "NULL": true
            },
            "createdAt": {
                "NULL": true
            },
            "username": {
                "S": "owner_test1"
            },
            "subjects": {
                "NULL": true
            },
            "id": {
                "S": "a64b4425-36b8-42ee-aff3-5cbfa62b402a"
            },
            "name": {
                "S": "owner_test1"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": null
}
```

---

## 🔗 TeacherStudent 테이블

**Count**: 2

```json
{
    "Items": [
        {
            "__typename": {
                "S": "TeacherStudent"
            },
            "teacherUsername": {
                "S": "b448adfc-90e1-700e-8be5-aae145ac9024"
            },
            "updatedAt": {
                "NULL": true
            },
            "studentUsername": {
                "S": "student_test1"
            },
            "createdAt": {
                "NULL": true
            },
            "subjects": {
                "NULL": true
            },
            "id": {
                "S": "dcafcb0a-976c-435b-b898-c2674b0ef9a6"
            }
        },
        {
            "__typename": {
                "S": "TeacherStudent"
            },
            "teacherUsername": {
                "S": "teacher_test1"
            },
            "updatedAt": {
                "NULL": true
            },
            "studentUsername": {
                "S": "test1"
            },
            "createdAt": {
                "NULL": true
            },
            "subjects": {
                "NULL": true
            },
            "id": {
                "S": "779de35d-0883-47d4-82b5-7c801a97a765"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": null
}
```

---

## 📊 요약

| 테이블명 | Count | 주요 내용 |
|---------|-------|-----------|
| **Cognito Users** | 6 | maknae12@gmail.com 포함, teacher_test2는 FORCE_CHANGE_PASSWORD 상태 |
| **AppUser** | 3 | owner_test1, teacher_test1, student_test1만 존재 |
| **AcademyMember** | 3 | academy-001에 3명 소속 (owner, teacher, student) |
| **Academy** | 1 | academy-001 (예두비 수학 학원) |
| **Assignment** | 12 | teacher_test1이 부여한 숙제들 (대부분 ASSIGNED, 일부 DONE) |
| **Book** | 1 | 교재 테스트 (초등 수학, 2025) |
| **Chapter** | 3 | 일, 이, 삼 (교재 테스트의 챕터) |
| **Lesson** | 1 | 2025-12-16 예정 수업 |
| **Student** | 4 | test1, maknae12@gmail.com, student_test2@gmail.com, student_test1 |
| **Teacher** | 2 | teacher_test1, owner_test1 |
| **TeacherStudent** | 2 | teacher-student 매핑 관계 |

---

## 🔍 주요 발견사항

### 1. maknae12@gmail.com 계정 상태
- ✅ **Cognito**: 존재함 (CONFIRMED, 2025-12-20 생성)
- ❌ **AppUser**: 없음
- ✅ **Student**: 존재함 (username: maknae12@gmail.com)

### 2. 데이터 불일치 문제
- **Cognito**에는 6명 (maknae12@gmail.com, teacher_test2, student_test2@gmail.com 등)
- **AppUser**에는 3명만 (test1, test2, maknae12 없음)
- **Student**에는 4명 (maknae12@gmail.com 포함)

### 3. teacher_test2 계정
- Cognito 상태: `FORCE_CHANGE_PASSWORD` (비정상)
- AppUser, Teacher 테이블: 없음

---

**덤프 완료**
