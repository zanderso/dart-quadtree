// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math';

import 'package:quadtree/quadtree.dart';
import 'package:test/test.dart';

void main() {
  const double minX = -1.0;
  const double maxX = 1.0;
  const double minY = -1.0;
  const double maxY = 1.0;
  const double epsilon = 0.01;

  const Point<double> p1 = Point<double>(minX / 2.0, minY / 2.0);
  const Point<double> p2 = Point<double>(maxX / 2.0, minY / 2.0);
  const Point<double> p3 = Point<double>(minX / 2.0, maxY / 2.0);
  const Point<double> p4 = Point<double>(maxX / 2.0, maxY / 2.0);
  const Point<double> p5 = Point<double>(minX / 4.0, minY / 4.0);
  const Point<double> p6 = Point<double>(maxX / 4.0, minY / 4.0);
  const Point<double> p7 = Point<double>(minX / 4.0, maxY / 4.0);
  const Point<double> p8 = Point<double>(maxX / 4.0, maxY / 4.0);

  group('quad tree tests', () {
    QuadTreeMap<Point<double>, void> qt;

    setUp(() {
      qt = QuadTreeMap<Point<double>, void>(minX, maxX, minY, maxY,
          maxLeafSize: 1);
    });

    test('quad tree add one', () {
      qt[p1] = null;
      expect(qt.containsKey(p1), isTrue);
    });

    test('quad tree add/remove one', () {
      qt[p1] = null;
      qt.remove(p1);
      expect(qt.containsKey(p1), isFalse);
    });

    test('quad tree add/remove/add one', () {
      qt[p1] = null;
      qt.remove(p1);
      qt[p1] = null;
      expect(qt.containsKey(p1), isTrue);
    });

    test('quad tree add >maxLeafSize', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;
      expect(qt.containsKey(p1), isTrue);
      expect(qt.containsKey(p2), isTrue);
      expect(qt.containsKey(p3), isTrue);
      expect(qt.containsKey(p4), isTrue);
    });

    test('quad tree add >maxLeafSize in correct leaf', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;
      expect(qt.findContainingLeaf(p1), equals(qt.ul));
      expect(qt.findContainingLeaf(p2), equals(qt.ur));
      expect(qt.findContainingLeaf(p3), equals(qt.ll));
      expect(qt.findContainingLeaf(p4), equals(qt.lr));
    });

    test('quad tree add/remove >maxLeafSize', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;
      qt.remove(p1);
      qt.remove(p2);
      qt.remove(p3);
      qt.remove(p4);
      expect(qt.containsKey(p1), isFalse);
      expect(qt.containsKey(p2), isFalse);
      expect(qt.containsKey(p3), isFalse);
      expect(qt.containsKey(p4), isFalse);
    });

    test('quad tree add/remove/add >maxLeafSize', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;
      qt.remove(p1);
      qt.remove(p2);
      qt.remove(p3);
      qt.remove(p4);
      qt[p1] = null;
      expect(qt.containsKey(p1), isTrue);
      expect(qt.containsKey(p2), isFalse);
      expect(qt.containsKey(p3), isFalse);
      expect(qt.containsKey(p4), isFalse);
    });

    test('quad tree find one in rect', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;

      final Map<Point<double>, void> m = <Point<double>, void>{};
      qt.findInRect(
          p1.x - epsilon, p1.x + epsilon, p1.y - epsilon, p1.y + epsilon, m);
      expect(m.containsKey(p1), isTrue);
      expect(m.containsKey(p2), isFalse);
      expect(m.containsKey(p3), isFalse);
      expect(m.containsKey(p4), isFalse);
    });

    test('quad tree find two in rect', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;

      final Map<Point<double>, void> m = <Point<double>, void>{};
      qt.findInRect(min(p1.x, p2.x) - epsilon, max(p1.x, p2.x) + epsilon,
          min(p1.y, p2.y) - epsilon, max(p1.y, p2.y) + epsilon, m);
      expect(m.containsKey(p1), isTrue);
      expect(m.containsKey(p2), isTrue);
      expect(m.containsKey(p3), isFalse);
      expect(m.containsKey(p4), isFalse);
    });

    test('quad tree find all in rect', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;

      final Map<Point<double>, void> m = <Point<double>, void>{};
      qt.findInRect(
          minX - epsilon, maxX + epsilon, minY - epsilon, maxY + epsilon, m);
      expect(m.containsKey(p1), isTrue);
      expect(m.containsKey(p2), isTrue);
      expect(m.containsKey(p3), isTrue);
      expect(m.containsKey(p4), isTrue);
    });

    test('quad tree do not find one removed in rect', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;

      qt.remove(p1);

      final Map<Point<double>, void> m = <Point<double>, void>{};
      qt.findInRect(
          p1.x - epsilon, p1.x + epsilon, p1.y - epsilon, p1.y + epsilon, m);
      expect(m.containsKey(p1), isFalse);
      expect(m.containsKey(p2), isFalse);
      expect(m.containsKey(p3), isFalse);
      expect(m.containsKey(p4), isFalse);
    });

    test('quad tree find two one removed in rect', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;

      qt.remove(p1);

      final Map<Point<double>, void> m = <Point<double>, void>{};
      qt.findInRect(min(p1.x, p2.x) - epsilon, max(p1.x, p2.x) + epsilon,
          min(p1.y, p2.y) - epsilon, max(p1.y, p2.y) + epsilon, m);
      expect(m.containsKey(p1), isFalse);
      expect(m.containsKey(p2), isTrue);
      expect(m.containsKey(p3), isFalse);
      expect(m.containsKey(p4), isFalse);
    });

    test('quad tree find nearest point', () {
      qt[p1] = null;
      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y - epsilon)),
          equals(p1));
    });

    test('quad tree find nearest point removed', () {
      qt[p1] = null;
      qt.remove(p1);
      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y - epsilon)),
          isNull);
    });

    test('quad tree find nearest point >maxLeafSize', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;
      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y - epsilon)),
          equals(p1));
    });

    test('quad tree find nearest point removed >maxLeafSize', () {
      qt[p1] = null;
      qt[p2] = null;
      qt[p3] = null;
      qt[p4] = null;

      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y + epsilon)),
          equals(p1));
      qt.remove(p1);

      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y + epsilon)),
          equals(p3));
      qt.remove(p3);

      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y + epsilon)),
          equals(p2));
      qt.remove(p2);

      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y + epsilon)),
          equals(p4));
      qt.remove(p4);

      expect(qt.findNearestPoint(Point<double>(p1.x - epsilon, p1.y + epsilon)),
          isNull);
    });
  });

  group('map tests: ', () {
    QuadTreeMap<Point<double>, int> qt;

    setUp(() {
      qt = QuadTreeMap<Point<double>, int>(minX, maxX, minY, maxY,
          maxLeafSize: 1);
    });

    test('entries', () {
      qt[p1] = 1;
      qt[p2] = 2;
      qt[p3] = 3;
      qt[p4] = 4;
      qt[p5] = 5;
      qt[p6] = 6;
      qt[p7] = 7;
      qt[p8] = 8;

      final List<MapEntry<Point<double>, int>> entries = qt.entries.toList();
      expect(entries.length, equals(8));
      for (int i = 0; i < entries.length; i++) {
        expect(qt[entries[i].key], equals(entries[i].value));
      }
    });

    test('length, is(Not)Empty', () {
      expect(qt.length, equals(0));
      expect(qt.isEmpty, isTrue);
      expect(qt.isNotEmpty, isFalse);
      qt[p1] = 1;
      expect(qt.length, equals(1));
      expect(qt.isEmpty, isFalse);
      expect(qt.isNotEmpty, isTrue);
      qt.remove(p1);
      expect(qt.length, equals(0));
      expect(qt.isEmpty, isTrue);
      expect(qt.isNotEmpty, isFalse);
      qt[p1] = 1;
      qt[p2] = 2;
      qt[p3] = 3;
      qt[p4] = 4;
      qt[p5] = 5;
      qt[p6] = 6;
      qt[p7] = 7;
      qt[p8] = 8;
      expect(qt.length, equals(8));
      expect(qt.isEmpty, isFalse);
      expect(qt.isNotEmpty, isTrue);
    });

    test('keys', () {
      expect(qt.keys.length, equals(0));
      expect(qt.keys.isEmpty, isTrue);
      expect(qt.keys.isNotEmpty, isFalse);
      qt[p1] = 1;
      expect(qt.keys.length, equals(1));
      expect(qt.keys.isEmpty, isFalse);
      expect(qt.keys.isNotEmpty, isTrue);
      expect(qt.keys.contains(p1), isTrue);
      qt.remove(p1);
      expect(qt.keys.length, equals(0));
      expect(qt.keys.isEmpty, isTrue);
      expect(qt.keys.isNotEmpty, isFalse);
      expect(qt.keys.contains(p1), isFalse);

      qt[p1] = 1;
      qt[p2] = 2;
      qt[p3] = 3;
      qt[p4] = 4;
      qt[p5] = 5;
      qt[p6] = 6;
      qt[p7] = 7;
      qt[p8] = 8;
      final List<Point<double>> keys = qt.keys.toList();
      expect(keys.contains(p1), isTrue);
      expect(keys.contains(p2), isTrue);
      expect(keys.contains(p3), isTrue);
      expect(keys.contains(p4), isTrue);
      expect(keys.contains(p5), isTrue);
      expect(keys.contains(p6), isTrue);
      expect(keys.contains(p7), isTrue);
      expect(keys.contains(p8), isTrue);
    });

    test('values', () {
      expect(qt.values.length, equals(0));
      expect(qt.values.isEmpty, isTrue);
      expect(qt.values.isNotEmpty, isFalse);
      qt[p1] = 1;
      expect(qt.values.length, equals(1));
      expect(qt.values.isEmpty, isFalse);
      expect(qt.values.isNotEmpty, isTrue);
      expect(qt.values.contains(1), isTrue);
      qt.remove(p1);
      expect(qt.values.length, equals(0));
      expect(qt.values.isEmpty, isTrue);
      expect(qt.values.isNotEmpty, isFalse);
      expect(qt.values.contains(1), isFalse);

      qt[p1] = 1;
      qt[p2] = 2;
      qt[p3] = 3;
      qt[p4] = 4;
      qt[p5] = 5;
      qt[p6] = 6;
      qt[p7] = 7;
      qt[p8] = 8;
      final List<int> values = qt.values.toList();
      for (int i = 1; i <= 8; i++) {
        expect(values.contains(i), isTrue);
      }
    });
  });
}
