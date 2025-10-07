import 'package:english_words/english_words.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (context) => MyAppState(),
      child: MaterialApp(
        title: 'Namer App',
        theme: ThemeData(
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        ),
        debugShowCheckedModeBanner: false,
        home: MyHomePage(),
      ),
    );
  }
}


class MyAppState extends ChangeNotifier {     // 앱의 '전역 상태 모듈' 클래스. ChangeNotifier를 상속해 변경 알림 기능을 가짐.
  var current = WordPair.random();           // 현재 상태 값. english_words 패키지의 랜덤 '영단어 쌍(WordPair)'을 한 번 생성해 보관.

  // ↓ Add this.
  void getNext() {                           // 상태를 갱신하는 메서드(멤버 함수). 버튼 콜백 등에서 호출됨.
    current = WordPair.random();             // 새 랜덤 WordPair로 현재 값을 교체(상태 변경).
    notifyListeners();                       // 상태가 바뀌었음을 구독자에게 알림 → watch 중인 위젯들만 build() 재실행.
  }
}


class MyHomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {           // ← 1: 위젯을 그릴 때 호출되는 메서드.
    // Provider가 제공하는 전역 상태를 읽어옴.
    // watch<T>()를 쓰면 T가 notifyListeners()될 때 이 위젯이 다시 build됨.
    var appState = context.watch<MyAppState>();  // ← 2
    var pair = appState.current;

    return Scaffold(                             // ← 3: Material Design 기본 골격(페이지 틀).
      body: Center(
        child: Column(                              // ← 4: 세로로 위젯들을 나열하는 레이아웃.
          mainAxisAlignment: MainAxisAlignment.center,  // ← Add this.
          children: [
            // 고정 문자열을 그리는 텍스트 위젯. (핫 리로드로 즉시 문구 변경 확인 가능)
            Text('A random AWESOME idea test:'),        // ← 5
        
            // 상태에서 현재 단어쌍을 가져와 소문자 형식으로 표시.
            // appState가 바뀌면(예: getNext() 호출) 이 Text도 새 값으로 다시 그림.
            BigCard(pair: pair),    // ← 6
            SizedBox(height: 10),
        
            // 버튼을 누르면 상태 객체의 getNext()를 호출하여
            // 새로운 단어쌍을 만들고 notifyListeners()로 화면 갱신 트리거.
            ElevatedButton(
              onPressed: () {
                appState.getNext();  // ← print 대신 실제 상태 변경을 호출.
              },
              child: Text('Next'),   // 버튼 라벨
            ),
          ],                                       // ← 7: Column의 children 리스트 끝.
        ),
      ),
    );
  }
}

class BigCard extends StatelessWidget {
  const BigCard({
    super.key,
    required this.pair,
  });

  final WordPair pair;

  @override
// ...

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.displayMedium!.copyWith(
      color: theme.colorScheme.onPrimary,
    );

    return Card(
      color: theme.colorScheme.primary,
      child: Padding(
        padding: const EdgeInsets.all(20),

        // ↓ Make the following change.
        child: Text(
          pair.asLowerCase,
          style: style,
          semanticsLabel: "${pair.first} ${pair.second}",
        ),
      ),
    );
  }
}
