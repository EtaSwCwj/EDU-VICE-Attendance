// ============================================================
// Grammar Effect 2 - 완전한 교재 DB
// PDF 정답지 기반 구축 (페이지별 분리)
// ============================================================

/// 교재 전체 구조
class TextbookDB {
  final String title;
  final String subject;
  final List<ChapterDB> chapters;
  final Map<int, PageDB> pages; // 페이지 번호 → Practice 정보

  TextbookDB({
    required this.title,
    required this.subject,
    required this.chapters,
    required this.pages,
  });
}

/// Chapter 정보
class ChapterDB {
  final int number;
  final String title;
  final List<UnitDB> units;

  ChapterDB({
    required this.number,
    required this.title,
    required this.units,
  });
}

/// Unit 정보
class UnitDB {
  final int number;
  final String title;
  final int practicePage;

  UnitDB({
    required this.number,
    required this.title,
    required this.practicePage,
  });
}

/// Practice 페이지 DB
class PageDB {
  final int page;
  final String chapter;
  final String unit;
  final String title;
  final List<SectionDB> sections;

  PageDB({
    required this.page,
    required this.chapter,
    required this.unit,
    required this.title,
    required this.sections,
  });

  List<ProblemInfo> get allProblems {
    final list = <ProblemInfo>[];
    for (final section in sections) {
      for (final problem in section.problems) {
        list.add(ProblemInfo(
          sectionName: section.name,
          number: problem.number,
          yStart: problem.yStart,
          yEnd: problem.yEnd,
          answer: problem.answer,
        ));
      }
    }
    return list;
  }
}

/// 섹션 (A, B, C, D)
class SectionDB {
  final String name;
  final double yStart;
  final double yEnd;
  final List<ProblemDB> problems;

  SectionDB({
    required this.name,
    required this.yStart,
    required this.yEnd,
    required this.problems,
  });
}

/// 개별 문제
class ProblemDB {
  final int number;
  final double yStart;
  final double yEnd;
  final String answer;

  ProblemDB({
    required this.number,
    required this.yStart,
    required this.yEnd,
    required this.answer,
  });
}

/// 문제 정보 (Flat 구조)
class ProblemInfo {
  final String sectionName;
  final int number;
  final double yStart;
  final double yEnd;
  final String answer;

  ProblemInfo({
    required this.sectionName,
    required this.number,
    required this.yStart,
    required this.yEnd,
    required this.answer,
  });

  String get id => '$sectionName-$number';
  String get displayName => '$sectionName.$number';
}

// ============================================================
// Grammar Effect 2 전체 DB
// ============================================================

final grammarEffect2 = TextbookDB(
  title: 'Grammar Effect 2',
  subject: '영어 문법',
  chapters: [
    ChapterDB(number: 1, title: '문장의 형식', units: [
      UnitDB(number: 1, title: '문장을 이루는 요소', practicePage: 9),
      UnitDB(number: 2, title: '1형식, 2형식', practicePage: 11),
      UnitDB(number: 3, title: '3형식, 4형식', practicePage: 13),
      UnitDB(number: 4, title: '5형식', practicePage: 15),
    ]),
    ChapterDB(number: 2, title: 'to부정사', units: [
      UnitDB(number: 1, title: '명사적 용법', practicePage: 23),
      UnitDB(number: 2, title: '형용사적 용법', practicePage: 25),
      UnitDB(number: 3, title: '부사적 용법', practicePage: 27),
      UnitDB(number: 4, title: '가주어와 진주어, 의미상의 주어', practicePage: 29),
      UnitDB(number: 5, title: 'too...to-v, ...enough to-v', practicePage: 31),
    ]),
    ChapterDB(number: 3, title: '동명사', units: [
      UnitDB(number: 1, title: '동명사의 역할', practicePage: 39),
      UnitDB(number: 2, title: '동명사와 to부정사', practicePage: 41),
    ]),
    ChapterDB(number: 4, title: '분사', units: [
      UnitDB(number: 1, title: '현재분사와 과거분사', practicePage: 49),
      UnitDB(number: 2, title: '분사구문', practicePage: 51),
    ]),
    ChapterDB(number: 5, title: '시제', units: [
      UnitDB(number: 1, title: '현재, 과거, 미래, 진행시제', practicePage: 59),
      UnitDB(number: 2, title: '현재완료시제', practicePage: 61),
    ]),
    ChapterDB(number: 6, title: '조동사', units: [
      UnitDB(number: 1, title: 'can, may, will', practicePage: 69),
      UnitDB(number: 2, title: 'must, have to, should', practicePage: 71),
      UnitDB(number: 3, title: 'would like to, had better, used to', practicePage: 73),
    ]),
    ChapterDB(number: 7, title: '대명사', units: [
      UnitDB(number: 1, title: '부정대명사', practicePage: 81),
      UnitDB(number: 2, title: '재귀대명사', practicePage: 83),
    ]),
    ChapterDB(number: 8, title: '비교', units: [
      UnitDB(number: 1, title: '원급, 비교급, 최상급', practicePage: 91),
      UnitDB(number: 2, title: '비교 구문을 이용한 표현', practicePage: 93),
    ]),
    ChapterDB(number: 9, title: '접속사와 절', units: [
      UnitDB(number: 1, title: '시간을 나타내는 접속사', practicePage: 101),
      UnitDB(number: 2, title: '이유, 결과를 나타내는 접속사', practicePage: 103),
      UnitDB(number: 3, title: '조건, 양보를 나타내는 접속사', practicePage: 105),
    ]),
    ChapterDB(number: 10, title: '관계사', units: [
      UnitDB(number: 1, title: '주격, 목적격, 소유격 관계대명사', practicePage: 113),
      UnitDB(number: 2, title: 'that, what, 관계대명사의 생략', practicePage: 115),
      UnitDB(number: 3, title: '관계부사', practicePage: 117),
    ]),
    ChapterDB(number: 11, title: '수동태', units: [
      UnitDB(number: 1, title: '수동태의 형태와 시제', practicePage: 125),
      UnitDB(number: 2, title: '수동태의 여러 가지 형태', practicePage: 127),
      UnitDB(number: 3, title: '주의해야 할 수동태', practicePage: 129),
    ]),
    ChapterDB(number: 12, title: '가정법', units: [
      UnitDB(number: 1, title: '가정법 과거, 가정법 과거완료', practicePage: 137),
      UnitDB(number: 2, title: 'I wish, as if', practicePage: 139),
    ]),
  ],
  pages: {
    // ========================================
    // Chapter 01: 문장의 형식
    // ========================================
    9: PageDB(
      page: 9,
      chapter: 'Chapter 01',
      unit: 'Unit 01',
      title: '문장을 이루는 요소 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 12, answer: '목적어'),
          ProblemDB(number: 2, yStart: 12, yEnd: 16, answer: '동사'),
          ProblemDB(number: 3, yStart: 16, yEnd: 20, answer: '수식어'),
          ProblemDB(number: 4, yStart: 20, yEnd: 24, answer: '보어'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 45, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 33, answer: 'wrote'),
          ProblemDB(number: 2, yStart: 33, yEnd: 38, answer: 'My teacher'),
          ProblemDB(number: 3, yStart: 38, yEnd: 42, answer: 'great'),
          ProblemDB(number: 4, yStart: 42, yEnd: 46, answer: 'dinner'),
        ]),
        SectionDB(name: 'C', yStart: 46, yEnd: 70, problems: [
          ProblemDB(number: 1, yStart: 49, yEnd: 55, answer: '주어, 동사, 보어'),
          ProblemDB(number: 2, yStart: 55, yEnd: 61, answer: '주어, 동사, 목적어, 수식어'),
          ProblemDB(number: 3, yStart: 61, yEnd: 67, answer: '주어, 동사, 보어'),
          ProblemDB(number: 4, yStart: 67, yEnd: 73, answer: '주어, 동사, 목적어, 수식어'),
        ]),
        SectionDB(name: 'D', yStart: 70, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 73, yEnd: 80, answer: 'Tom and I go to the same school.'),
          ProblemDB(number: 2, yStart: 80, yEnd: 86, answer: 'She was writing in a diary.'),
          ProblemDB(number: 3, yStart: 86, yEnd: 92, answer: 'It is very surprising news.'),
          ProblemDB(number: 4, yStart: 92, yEnd: 98, answer: 'We saw that movie at the theater.'),
        ]),
      ],
    ),

    11: PageDB(
      page: 11,
      chapter: 'Chapter 01',
      unit: 'Unit 02',
      title: '1형식, 2형식 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'angry'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'an artist'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'X'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'fantastic'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 45, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 33, answer: 'well'),
          ProblemDB(number: 2, yStart: 33, yEnd: 38, answer: 'happy'),
          ProblemDB(number: 3, yStart: 38, yEnd: 42, answer: 'sweet'),
          ProblemDB(number: 4, yStart: 42, yEnd: 46, answer: 'dark'),
        ]),
        SectionDB(name: 'C', yStart: 46, yEnd: 68, problems: [
          ProblemDB(number: 1, yStart: 49, yEnd: 55, answer: 'bad'),
          ProblemDB(number: 2, yStart: 55, yEnd: 60, answer: 'perfect'),
          ProblemDB(number: 3, yStart: 60, yEnd: 65, answer: 'nice'),
          ProblemDB(number: 4, yStart: 65, yEnd: 70, answer: 'rich'),
        ]),
        SectionDB(name: 'D', yStart: 68, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 71, yEnd: 79, answer: 'fur coat looks expensive'),
          ProblemDB(number: 2, yStart: 79, yEnd: 86, answer: 'The beef stew smells delicious'),
          ProblemDB(number: 3, yStart: 86, yEnd: 92, answer: 'Your idea sounds very good'),
          ProblemDB(number: 4, yStart: 92, yEnd: 98, answer: 'the tomato soup taste spicy'),
        ]),
      ],
    ),

    13: PageDB(
      page: 13,
      chapter: 'Chapter 01',
      unit: 'Unit 03',
      title: '3형식, 4형식 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 28, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 12, answer: 'to'),
          ProblemDB(number: 2, yStart: 12, yEnd: 16, answer: 'me a package'),
          ProblemDB(number: 3, yStart: 16, yEnd: 20, answer: 'for'),
          ProblemDB(number: 4, yStart: 20, yEnd: 24, answer: 'to'),
          ProblemDB(number: 5, yStart: 24, yEnd: 28, answer: 'us his painting'),
        ]),
        SectionDB(name: 'B', yStart: 28, yEnd: 50, problems: [
          ProblemDB(number: 1, yStart: 31, yEnd: 37, answer: 'a present to me'),
          ProblemDB(number: 2, yStart: 37, yEnd: 42, answer: 'a book for his sister'),
          ProblemDB(number: 3, yStart: 42, yEnd: 47, answer: 'the story to my friends'),
          ProblemDB(number: 4, yStart: 47, yEnd: 52, answer: 'chicken pasta for us'),
        ]),
        SectionDB(name: 'C', yStart: 50, yEnd: 78, problems: [
          ProblemDB(number: 1, yStart: 53, yEnd: 58, answer: 'fixed my computer'),
          ProblemDB(number: 2, yStart: 58, yEnd: 63, answer: 'made me a sweater'),
          ProblemDB(number: 3, yStart: 63, yEnd: 68, answer: 'sold his car to'),
          ProblemDB(number: 4, yStart: 68, yEnd: 73, answer: 'bought chocolate for'),
          ProblemDB(number: 5, yStart: 73, yEnd: 78, answer: 'ask you a personal question'),
        ]),
      ],
    ),

    15: PageDB(
      page: 15,
      chapter: 'Chapter 01',
      unit: 'Unit 04',
      title: '5형식 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'to be'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'healthy'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'speak'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'stay'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 45, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 33, answer: 'difficult'),
          ProblemDB(number: 2, yStart: 33, yEnd: 38, answer: 'move/moving'),
          ProblemDB(number: 3, yStart: 38, yEnd: 42, answer: 'to last'),
          ProblemDB(number: 4, yStart: 42, yEnd: 46, answer: 'make'),
        ]),
        SectionDB(name: 'C', yStart: 46, yEnd: 70, problems: [
          ProblemDB(number: 1, yStart: 49, yEnd: 55, answer: 'to go up'),
          ProblemDB(number: 2, yStart: 55, yEnd: 61, answer: 'angry'),
          ProblemDB(number: 3, yStart: 61, yEnd: 67, answer: 'do the dishes'),
          ProblemDB(number: 4, yStart: 67, yEnd: 73, answer: 'play/playing soccer'),
        ]),
        SectionDB(name: 'D', yStart: 70, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 73, yEnd: 80, answer: 'found the show boring'),
          ProblemDB(number: 2, yStart: 80, yEnd: 86, answer: 'heard someone call/calling my name'),
          ProblemDB(number: 3, yStart: 86, yEnd: 92, answer: 'let me watch TV'),
          ProblemDB(number: 4, yStart: 92, yEnd: 98, answer: 'asked me to help him'),
        ]),
      ],
    ),

    // ========================================
    // Chapter 02: to부정사
    // ========================================
    23: PageDB(
      page: 23,
      chapter: 'Chapter 02',
      unit: 'Unit 01',
      title: 'to부정사의 명사적 용법 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: '주어'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: '목적어'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: '보어'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: '목적어'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 45, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 33, answer: 'hopes to become'),
          ProblemDB(number: 2, yStart: 33, yEnd: 38, answer: 'what to eat'),
          ProblemDB(number: 3, yStart: 38, yEnd: 42, answer: 'rude to yell'),
          ProblemDB(number: 4, yStart: 42, yEnd: 46, answer: 'not to join'),
        ]),
        SectionDB(name: 'C', yStart: 46, yEnd: 68, problems: [
          ProblemDB(number: 1, yStart: 49, yEnd: 55, answer: 'what to tell'),
          ProblemDB(number: 2, yStart: 55, yEnd: 61, answer: 'how to fix'),
          ProblemDB(number: 3, yStart: 61, yEnd: 67, answer: 'when to start'),
        ]),
        SectionDB(name: 'D', yStart: 68, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 71, yEnd: 79, answer: 'is to win'),
          ProblemDB(number: 2, yStart: 79, yEnd: 86, answer: 'wanted to return'),
          ProblemDB(number: 3, yStart: 86, yEnd: 92, answer: 'To study all night'),
          ProblemDB(number: 4, yStart: 92, yEnd: 98, answer: 'how to stop this machine'),
        ]),
      ],
    ),

    25: PageDB(
      page: 25,
      chapter: 'Chapter 02',
      unit: 'Unit 02',
      title: 'to부정사의 형용사적 용법 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 28, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 12, answer: 'ⓑ'),
          ProblemDB(number: 2, yStart: 12, yEnd: 16, answer: 'ⓔ'),
          ProblemDB(number: 3, yStart: 16, yEnd: 20, answer: 'ⓐ'),
          ProblemDB(number: 4, yStart: 20, yEnd: 24, answer: 'ⓒ'),
          ProblemDB(number: 5, yStart: 24, yEnd: 28, answer: 'ⓓ'),
        ]),
        SectionDB(name: 'B', yStart: 28, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 31, yEnd: 36, answer: 'with'),
          ProblemDB(number: 2, yStart: 36, yEnd: 41, answer: 'in'),
          ProblemDB(number: 3, yStart: 41, yEnd: 46, answer: 'X'),
          ProblemDB(number: 4, yStart: 46, yEnd: 51, answer: 'about'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: 'finish → to finish'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: 'improve → to improve'),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: 'write → write with'),
          ProblemDB(number: 4, yStart: 72, yEnd: 79, answer: 'to drink cold → cold to drink'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'anybody to help'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'anyone to talk to'),
          ProblemDB(number: 3, yStart: 89, yEnd: 96, answer: 'cars to repair'),
        ]),
      ],
    ),

    27: PageDB(
      page: 27,
      chapter: 'Chapter 02',
      unit: 'Unit 03',
      title: 'to부정사의 부사적 용법 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'to save'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'to lend'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'easy to find'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'To see'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 34, answer: 'to win'),
          ProblemDB(number: 2, yStart: 34, yEnd: 40, answer: 'Chinese in order to[so as to] study'),
          ProblemDB(number: 3, yStart: 40, yEnd: 46, answer: 'to find'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: '나는 그가 다시 건강한 것을 봐서 정말 기뻤다.'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: '이 글은 이해하기에 매우 어렵다.'),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: '그는 조언을 좀 얻기 위해 그의 선생님께 갔다.'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'lived to be'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'was thrilled to go'),
          ProblemDB(number: 3, yStart: 89, yEnd: 93, answer: 'must be, full to refuse'),
          ProblemDB(number: 4, yStart: 93, yEnd: 98, answer: 'in order to[so as to] cancel my reservation'),
        ]),
      ],
    ),

    29: PageDB(
      page: 29,
      chapter: 'Chapter 02',
      unit: 'Unit 04',
      title: '가주어와 진주어, 의미상의 주어 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'of'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'for'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'for'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'of'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 34, answer: 'knowing → to know'),
          ProblemDB(number: 2, yStart: 34, yEnd: 40, answer: 'for → of'),
          ProblemDB(number: 3, yStart: 40, yEnd: 46, answer: 'of → for'),
          ProblemDB(number: 4, yStart: 46, yEnd: 52, answer: 'to you → of you'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: 'It is necessary to follow these steps.'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: 'It is very difficult to satisfy customers.'),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: 'It is very expensive to stay in a five-star hotel.'),
          ProblemDB(number: 4, yStart: 72, yEnd: 79, answer: 'It is challenging to learn a new language.'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'It is, to persuade'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'It is, to carry'),
          ProblemDB(number: 3, yStart: 89, yEnd: 93, answer: 'for children to watch'),
          ProblemDB(number: 4, yStart: 93, yEnd: 98, answer: 'It was rude of him to leave'),
        ]),
      ],
    ),

    31: PageDB(
      page: 31,
      chapter: 'Chapter 02',
      unit: 'Unit 05',
      title: 'too...to-v, ...enough to-v - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'too'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'enough'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'too'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'enough'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 35, answer: '너무 늦어서 산책을 갈 수 없다.'),
          ProblemDB(number: 2, yStart: 35, yEnd: 42, answer: '그의 실수는 너무 심각해서 우리는 용서할 수가 없었다.'),
          ProblemDB(number: 3, yStart: 42, yEnd: 49, answer: 'Raymond는 그 스스로 결정을 내릴 만큼 충분히 나이를 먹었다.'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: 'too, to walk'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: "so, that, can't"),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: 'too, for us to go'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'too heavy for her to pick up'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'big enough to carry 100 cars'),
          ProblemDB(number: 3, yStart: 89, yEnd: 93, answer: 'simple enough for children to follow'),
          ProblemDB(number: 4, yStart: 93, yEnd: 98, answer: 'too expensive for me to buy'),
        ]),
      ],
    ),

    // ========================================
    // Chapter 03: 동명사
    // ========================================
    39: PageDB(
      page: 39,
      chapter: 'Chapter 03',
      unit: 'Unit 01',
      title: '동명사의 역할 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'Learning Korean, 주어'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'setting up, 보어'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'talking to, 목적어'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'Not eating breakfast, 주어'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 35, answer: 'winning a gold medal at the Olympics'),
          ProblemDB(number: 2, yStart: 35, yEnd: 42, answer: 'playing the cello in her free time'),
          ProblemDB(number: 3, yStart: 42, yEnd: 49, answer: 'Taking a short nap in the afternoon'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: 'Taking'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: 'meeting'),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: 'laughing'),
          ProblemDB(number: 4, yStart: 72, yEnd: 79, answer: 'raining'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'Telling lies is'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'He goes swimming'),
          ProblemDB(number: 3, yStart: 89, yEnd: 96, answer: 'is good at drawing pictures'),
        ]),
      ],
    ),

    41: PageDB(
      page: 41,
      chapter: 'Chapter 03',
      unit: 'Unit 02',
      title: '동명사와 to부정사 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'turning'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'to go'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'smoking'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'to move'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 34, answer: 'riding'),
          ProblemDB(number: 2, yStart: 34, yEnd: 40, answer: 'to meet'),
          ProblemDB(number: 3, yStart: 40, yEnd: 46, answer: 'to swim'),
          ProblemDB(number: 4, yStart: 46, yEnd: 52, answer: 'walking'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: '너 나갈 때 쓰레기 내놓는 것 잊지 마.'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: '나는 TV에서 그를 본 것이 기억난다.'),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: '우리는 마지막 기차를 타려고 노력했다.'),
          ProblemDB(number: 4, yStart: 72, yEnd: 79, answer: '너는 밤 늦게 간식 먹는 것을 그만두어야 해.'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'They practiced marching'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'They agreed to renovate'),
          ProblemDB(number: 3, yStart: 89, yEnd: 93, answer: 'I avoid going to'),
          ProblemDB(number: 4, yStart: 93, yEnd: 98, answer: 'Most people want to make'),
        ]),
      ],
    ),

    // ========================================
    // Chapter 04: 분사
    // ========================================
    49: PageDB(
      page: 49,
      chapter: 'Chapter 04',
      unit: 'Unit 01',
      title: '현재분사와 과거분사 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'confusing'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'standing'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'frozen'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'disappointed'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 45, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 33, answer: 'ⓐ'),
          ProblemDB(number: 2, yStart: 33, yEnd: 38, answer: 'ⓑ'),
          ProblemDB(number: 3, yStart: 38, yEnd: 42, answer: 'ⓑ'),
          ProblemDB(number: 4, yStart: 42, yEnd: 46, answer: 'ⓒ'),
        ]),
        SectionDB(name: 'C', yStart: 46, yEnd: 68, problems: [
          ProblemDB(number: 1, yStart: 49, yEnd: 55, answer: 'tired'),
          ProblemDB(number: 2, yStart: 55, yEnd: 61, answer: 'amazing'),
          ProblemDB(number: 3, yStart: 61, yEnd: 67, answer: 'written'),
          ProblemDB(number: 4, yStart: 67, yEnd: 73, answer: 'burning'),
        ]),
        SectionDB(name: 'D', yStart: 68, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 71, yEnd: 79, answer: 'used computer'),
          ProblemDB(number: 2, yStart: 79, yEnd: 86, answer: 'surprising news'),
          ProblemDB(number: 3, yStart: 86, yEnd: 92, answer: 'looked very excited'),
          ProblemDB(number: 4, yStart: 92, yEnd: 98, answer: 'heard an interesting story'),
        ]),
      ],
    ),

    51: PageDB(
      page: 51,
      chapter: 'Chapter 04',
      unit: 'Unit 02',
      title: '분사구문 - Practice',
      sections: [
        SectionDB(name: 'A', yStart: 5, yEnd: 25, problems: [
          ProblemDB(number: 1, yStart: 8, yEnd: 13, answer: 'Dancing'),
          ProblemDB(number: 2, yStart: 13, yEnd: 18, answer: 'Looking'),
          ProblemDB(number: 3, yStart: 18, yEnd: 22, answer: 'Hearing'),
          ProblemDB(number: 4, yStart: 22, yEnd: 26, answer: 'Lying'),
        ]),
        SectionDB(name: 'B', yStart: 25, yEnd: 48, problems: [
          ProblemDB(number: 1, yStart: 28, yEnd: 35, answer: 'Seeing Jacob'),
          ProblemDB(number: 2, yStart: 35, yEnd: 42, answer: 'Feeling bored'),
          ProblemDB(number: 3, yStart: 42, yEnd: 49, answer: 'Cleaning her room'),
        ]),
        SectionDB(name: 'C', yStart: 48, yEnd: 72, problems: [
          ProblemDB(number: 1, yStart: 51, yEnd: 58, answer: 'When she drives to work'),
          ProblemDB(number: 2, yStart: 58, yEnd: 65, answer: 'Because I had a stomachache'),
          ProblemDB(number: 3, yStart: 65, yEnd: 72, answer: 'When he arrived at the station'),
          ProblemDB(number: 4, yStart: 72, yEnd: 79, answer: 'Because he is a translator'),
        ]),
        SectionDB(name: 'D', yStart: 72, yEnd: 98, problems: [
          ProblemDB(number: 1, yStart: 75, yEnd: 82, answer: 'Doing the dishes'),
          ProblemDB(number: 2, yStart: 82, yEnd: 89, answer: 'Seeing the snake'),
          ProblemDB(number: 3, yStart: 89, yEnd: 96, answer: 'Taking off his hat'),
        ]),
      ],
    ),

    // ========================================
    // 나머지 Chapter들... (추후 확장)
    // ========================================
  },
);

/// 전역 DB 접근
TextbookDB getGrammarEffect2() => grammarEffect2;

/// 페이지 번호로 DB 조회
PageDB? getPageDB(int pageNumber) => grammarEffect2.pages[pageNumber];

/// 챕터/유닛 정보로 페이지 조회
int? getPracticePage(int chapter, int unit) {
  final chapterDB = grammarEffect2.chapters.firstWhere(
    (c) => c.number == chapter,
    orElse: () => ChapterDB(number: -1, title: '', units: []),
  );
  if (chapterDB.number == -1) return null;
  
  final unitDB = chapterDB.units.firstWhere(
    (u) => u.number == unit,
    orElse: () => UnitDB(number: -1, title: '', practicePage: -1),
  );
  if (unitDB.number == -1) return null;
  
  return unitDB.practicePage;
}
