import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:visualmath_ai/adaptive.dart';
import 'package:visualmath_ai/question_bank.dart';

void main() {
  group('aturan adaptif (sama dengan backend web)', () {
    test('tingkat naik bila benar, turun bila salah, dengan batas', () {
      expect(nextDifficulty('mudah', true), 'sedang');
      expect(nextDifficulty('sedang', true), 'sulit');
      expect(nextDifficulty('sulit', true), 'sulit');
      expect(nextDifficulty('sulit', false), 'sedang');
      expect(nextDifficulty('mudah', false), 'mudah');
    });

    test('perubahan mastery', () {
      expect(masteryDelta('mudah', true), 8);
      expect(masteryDelta('sedang', true), 10);
      expect(masteryDelta('sulit', true), 14);
      expect(masteryDelta('sulit', false), -8);
      expect(masteryDelta('sulit', true, alreadyCorrect: true), 0);
    });
  });

  group('pencocokan jawaban', () {
    test('numerik dengan toleransi, koma desimal, dan pecahan', () {
      expect(answerMatches('numeric', '6.3246', '6.3246'), isTrue);
      expect(answerMatches('numeric', '6,33', '6.3246'), isTrue);
      expect(answerMatches('numeric', '1/3', '0.3333'), isTrue);
      expect(answerMatches('numeric', '−5', '-5'), isTrue);
      expect(answerMatches('numeric', '6.5', '6.3246'), isFalse);
      expect(answerMatches('numeric', 'abc', '1'), isFalse);
    });

    test('pilihan dan benar/salah tidak peka huruf besar', () {
      expect(answerMatches('choice', 'kerucut', 'Kerucut'), isTrue);
      expect(answerMatches('truefalse', 'Salah', 'Benar'), isFalse);
    });
  });

  group('bank soal', () {
    test('setiap topik memiliki minimal 4 soal per tingkat', () {
      for (final t in kTopics) {
        for (final d in kDifficulties) {
          final n = kQuestionBank.where((q) => q.topicId == t.id && q.difficulty == d).length;
          expect(n, greaterThanOrEqualTo(4), reason: '${t.id} $d');
        }
      }
    });

    test('kunci jawaban valid untuk tipenya dan id unik', () {
      final ids = <String>{};
      for (final q in kQuestionBank) {
        expect(ids.add(q.id), isTrue, reason: 'id ganda ${q.id}');
        if (q.type == 'numeric') {
          expect(parseNumbers(q.expectedAnswer), isNotNull, reason: q.id);
        } else {
          expect(q.options, contains(q.expectedAnswer), reason: q.id);
        }
        expect(q.explanation, isNotEmpty);
      }
    });
  });

  group('mesin lokal dan sesi', () {
    final engine = LocalPracticeEngine(kQuestionBank, rng: Random(1));

    test('tidak mengulang soal selama masih ada yang belum muncul', () {
      final seen = <String>{};
      for (var i = 0; i < 4; i++) {
        final q = engine.pick('t3', 'sedang', seen)!;
        expect(seen.contains(q.id), isFalse);
        seen.add(q.id);
      }
    });

    test('XP hanya diberikan sekali per soal', () {
      final q = kQuestionBank.firstWhere((x) => x.difficulty == 'sulit');
      final first = engine.grade(q, q.expectedAnswer, alreadyCorrect: false);
      final again = engine.grade(q, q.expectedAnswer, alreadyCorrect: true);
      expect(first.xpEarned, 20);
      expect(again.xpEarned, 0);
    });

    test('skor dan syarat sertifikat', () {
      final s = PracticeSession(topicId: 't0', difficulty: 'mudah', length: 4);
      const ok = AnswerOutcome(correct: true, expectedAnswer: '', explanation: '', nextDifficulty: 'sedang', xpEarned: 5);
      const no = AnswerOutcome(correct: false, expectedAnswer: '', explanation: '', nextDifficulty: 'mudah', xpEarned: 0);
      s..record(ok)..record(ok)..record(ok)..record(no);
      expect(s.score, 75);
      expect(s.isComplete, isTrue);
      expect(s.eligibleForCertificate(), isTrue);
      expect(s.eligibleForCertificate(quit: true), isFalse);
      expect(s.bestStreak, 3);
    });
  });
}
