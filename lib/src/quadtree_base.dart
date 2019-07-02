// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';
import 'dart:math';

class QuadTreeIterator<K extends Point<double>, V>
    implements Iterator<MapEntry<K, V>> {
  QuadTreeIterator(this._qt);

  final QuadTreeMap<K, V> _qt;

  QuadTreeMap<K, V> _currentLeaf;
  Iterator<MapEntry<K, V>> _currentIterator;

  @override
  MapEntry<K, V> get current => _currentIterator?.current;

  @override
  bool moveNext() {
    if (_currentLeaf == null) {
      QuadTreeMap<K, V> node = _qt;
      while (node._points == null) {
        node = node._children[0];
      }
      _currentLeaf = node;
      _currentIterator = node._points.entries.iterator;
    }
    while (!_currentIterator.moveNext()) {
      QuadTreeMap<K, V> node = _currentLeaf;
      _currentLeaf = null;
      _currentIterator = null;
      while (_currentLeaf == null) {
        if (node._parent == null) {
          return false;
        }
        int nextChildIndex;
        for (int i = 0; i < 4; i++) {
          if (node._parent._children[i] == node) {
            nextChildIndex = i + 1;
            break;
          }
        }
        if (nextChildIndex == 4) {
          node = node._parent;
        } else {
          node = node._parent._children[nextChildIndex];
          while (node._points == null) {
            node = node._children[0];
          }
          _currentLeaf = node;
          _currentIterator = node._points.entries.iterator;
        }
      }
    }
    return true;
  }
}

class QuadTreeIterable<K extends Point<double>, V>
    extends IterableBase<MapEntry<K, V>> {
  QuadTreeIterable(this._qt);

  final QuadTreeMap<K, V> _qt;

  @override
  Iterator<MapEntry<K, V>> get iterator => QuadTreeIterator<K, V>(_qt);
}

class QuadTreeMap<K extends Point<double>, V> extends MapBase<K, V> {
  QuadTreeMap(
    this.minX,
    this.maxX,
    this.minY,
    this.maxY, {
    this.maxLeafSize = 10,
  })  : _points = <K, V>{},
        midX = ((maxX - minX) / 2) + minX,
        midY = ((maxY - minY) / 2) + minY;

  /// The least value in the 'x' dimension that a key under this node may have.
  final double minX;

  /// The greatest value in the 'x' dimension that a key under this node may
  /// have.
  final double maxX;

  /// The midpoint of the region in the 'x' dimension.
  final double midX;

  /// The least value in the 'y' dimension that a key under this node may have.
  final double minY;

  /// The greatest value in the 'y' dimension that a key under this node may
  /// have.
  final double maxY;

  /// The midpoint of the region in the 'y' dimension.
  final double midY;

  /// The maximum number of points that can populate a leaf node in the tree.
  final int maxLeafSize;

  QuadTreeMap<K, V> _parent;
  List<QuadTreeMap<K, V>> _children;

  /// The upper-left child when this node is not a leaf.
  QuadTreeMap<K, V> get ul => _children == null ? null : _children[0];

  /// The upper-right child when this node is not a leaf.
  QuadTreeMap<K, V> get ur => _children == null ? null : _children[1];

  /// The lower-left child when this node is not a leaf.
  QuadTreeMap<K, V> get ll => _children == null ? null : _children[2];

  /// The lower-right child when this node is not a leaf.
  QuadTreeMap<K, V> get lr => _children == null ? null : _children[3];

  /// In a leaf node, the points resident in the region.
  Map<K, V> get points => _points;
  Map<K, V> _points;

  // The index of the child quadrants in which the point lies.
  int _childIndex(K point) {
    final int leftRight = point.x < midX ? 0 : 1;
    final int upperLower = point.y < midY ? 0 : 2;
    return leftRight | upperLower;
  }

  static bool _inBounds<K extends Point<double>>(
      K point, double minX, double maxX, double minY, double maxY) {
    return point.x >= minX &&
        point.x <= maxX &&
        point.y >= minY &&
        point.y <= maxY;
  }

  // Helper for []=. Splits a node into four children.
  void _split() {
    // Create children.
    _children = List<QuadTreeMap<K, V>>(4);
    _children[0] =
        QuadTreeMap<K, V>(minX, midX, minY, midY, maxLeafSize: maxLeafSize);
    _children[1] =
        QuadTreeMap<K, V>(midX, maxX, minY, midY, maxLeafSize: maxLeafSize);
    _children[2] =
        QuadTreeMap<K, V>(minX, midX, midY, maxY, maxLeafSize: maxLeafSize);
    _children[3] =
        QuadTreeMap<K, V>(midX, maxX, midY, maxY, maxLeafSize: maxLeafSize);

    for (int i = 0; i < _children.length; i++) {
      _children[i]._parent = this;
    }

    // Populate children.
    final Map<K, V> tmpPoints = _points;
    _points = null;
    addAll(tmpPoints);
  }

  // TODO(zra): How to make these efficient? Does it matter?
  // int get length => keys.length;
  // bool get isEmpty => keys.isEmpty;
  // bool get isNotEmpty => keys.isNotEmpty;

  // Returns the leaf node of the QuadTree whose region contains the point
  // [point]. [point] need not be mapped by the quad tree.
  QuadTreeMap<K, V> findContainingLeaf(K point) {
    QuadTreeMap<K, V> node = this;
    while (node._points == null) {
      node = node._children[node._childIndex(point)];
    }
    return node;
  }

  @override
  operator []=(K key, V value) {
    final K point = key;
    if (!_inBounds<K>(key, minX, maxX, minY, maxY)) {
      throw ArgumentError('$key is out of bounds');
    }
    QuadTreeMap<K, V> node = findContainingLeaf(point);
    if (node._points != null && node._points.length < node.maxLeafSize) {
      node._points[point] = value;
      return;
    }
    while (node._points != null && node._points.length == maxLeafSize) {
      node._split();
      node = node._children[node._childIndex(point)];
    }
    node._points[point] = value;
  }

  @override
  V operator [](Object key) {
    final K point = key;
    if (!_inBounds<K>(point, minX, maxX, minY, maxY)) {
      throw ArgumentError('$key is out of bounds');
    }
    return findContainingLeaf(point)._points[point];
  }

  @override
  Iterable<MapEntry<K, V>> get entries => QuadTreeIterable<K, V>(this);

  @override
  Iterable<K> get keys => entries.map((MapEntry<K, V> e) => e.key);

  @override
  Iterable<V> get values => entries.map((MapEntry<K, V> e) => e.value);

  @override
  V remove(Object key) {
    final K point = key;
    return findContainingLeaf(point)._points.remove(point);
  }

  @override
  void clear() {
    _children = null;
    _points = <K, V>{};
  }

  @override
  bool containsKey(Object key) {
    final K point = key;
    return findContainingLeaf(point)._points.containsKey(point);
  }

  @override
  V putIfAbsent(K key, V ifAbsent()) {
    final K point = key;
    final QuadTreeMap<K, V> node = findContainingLeaf(point);
    if (node._points.containsKey(point)) {
      return node._points[point];
    }
    // NB: Not adding directly to node._points in case splitting is necessary.
    return node[key] = ifAbsent();
  }

  @override
  V update(K key, V update(V value), {V ifAbsent()}) {
    final K point = key;
    final QuadTreeMap<K, V> node = findContainingLeaf(point);
    if (node._points.containsKey(key)) {
      return node._points[key] = update(node._points[key]);
    }
    if (ifAbsent != null) {
      // NB: Not adding directly to node._points in case splitting is necessary.
      return node[key] = ifAbsent();
    }
    throw ArgumentError.value(key, 'key', 'Key not in map.');
  }

  void _visit(bool Function(QuadTreeMap<K, V> qt) fn) {
    final List<QuadTreeMap<K, V>> stack = <QuadTreeMap<K, V>>[this];
    while (stack.isNotEmpty) {
      final QuadTreeMap<K, V> current = stack.removeAt(0);
      final bool addChildren = fn(current);
      if (current._children != null && addChildren) {
        stack.insertAll(0, current._children);
      }
    }
  }

  /// Populates the [Map] [outResult] with all key-value pairs that lie within
  /// the rectangle defined by the provided dimensions.
  void findInRect(double minRectX, double maxRectX, double minRectY,
      double maxRectY, Map<K, V> outResult) {
    _visit((QuadTreeMap<K, V> node) {
      // QuadTreeMap node does not intersect rect.
      if (minRectX > node.maxX ||
          node.minX > maxRectX ||
          minRectY > node.maxY ||
          node.minY > maxRectY) {
        return false;
      }

      // Check every point in a leaf.
      if (node._points != null) {
        for (MapEntry<K, V> e in node._points.entries) {
          final K point = e.key;
          if (_inBounds<K>(point, minRectX, maxRectX, minRectY, maxRectY)) {
            outResult[point] = e.value;
          }
        }
        return false;
      }

      // Search children.
      return true;
    });
  }

  /// Populates the [Map] [outResult] with all key-value pairs that lie within
  /// the circle defined by the provided dimensions.
  void findInCircle(
      double centerX, double centerY, double radius, Map<K, V> outResult) {
    _visit((QuadTreeMap<K, V> node) {
      if (centerX - radius > node.maxX ||
          node.minX > centerX + radius ||
          centerY - radius > node.maxY ||
          node.minY > centerY + radius) {
        return false;
      }

      if (node._points != null) {
        final Point<double> center = Point<double>(centerX, centerY);
        final double rSquared = radius * radius;
        for (MapEntry<K, V> e in node._points.entries) {
          final K point = e.key;
          if (center.squaredDistanceTo(point) <= rSquared) {
            outResult[point] = e.value;
          }
        }
        return false;
      }

      return true;
    });
  }

  double _distSquared(double x1, double y1, double x2, double y2) {
    final double xdist = x1 - x2;
    final double ydist = y1 - y2;
    return xdist * xdist + ydist * ydist;
  }

  /// Populates the [Map] [outResult] with all key-value pairs that lie within
  /// the ring defined by [innerRadius] and [outerRadius].
  void findInRing(double centerX, double centerY, double innerRadius,
      double outerRadius, Map<K, V> outResult) {
    _visit((QuadTreeMap<K, V> node) {
      if (centerX - outerRadius > node.maxX ||
          node.minX > centerX + outerRadius ||
          centerY - outerRadius > node.maxY ||
          node.minY > centerY + outerRadius) {
        return false;
      }

      if (innerRadius > 0.0) {
        final double inRSquared = innerRadius * innerRadius;
        if (_distSquared(node.minX, node.minY, centerX, centerY) < inRSquared &&
            _distSquared(node.minX, node.maxY, centerX, centerY) < inRSquared &&
            _distSquared(node.maxX, node.minY, centerX, centerY) < inRSquared &&
            _distSquared(node.maxX, node.maxY, centerX, centerY) < inRSquared) {
          return false;
        }
      }

      if (node._points != null) {
        final Point<double> center = Point<double>(centerX, centerY);
        final double innerRSquared = innerRadius * innerRadius;
        final double outerRSquared = outerRadius * outerRadius;
        for (MapEntry<K, V> e in node._points.entries) {
          final K point = e.key;
          final double squaredDistance = center.squaredDistanceTo(point);
          if (squaredDistance <= outerRSquared &&
              squaredDistance > innerRSquared) {
            outResult[point] = e.value;
          }
        }
        return false;
      }

      return true;
    });
  }

  K _closestInLeaf(Map<K, V> leafPoints, K point) {
    if (leafPoints == null || leafPoints.isEmpty) {
      return null;
    }
    return leafPoints.keys.reduce((K c, K p) =>
        p.squaredDistanceTo(point) < c.squaredDistanceTo(point) ? p : c);
  }

  /// Returns the key of the map that is closest in euclidian distance to the
  /// given point [point].
  K findNearestPoint(K point) {
    final List<K> nearest = findNearestPoints(point, 1);
    return nearest.isEmpty ? null : nearest[0];
  }

  /// Returns up to k keys of the map that are the closest in euclidian
  /// distancce to [point], sorted in order of increasing distance.
  List<K> findNearestPoints(K point, int k) {
    if (!_inBounds<K>(point, minX, maxX, minY, maxY)) {
      throw ArgumentError('$point is not in bounds');
    }

    final double within = 2.0 * max(maxX - minX, maxY - minY);
    final QuadTreeMap<K, V> leaf = findContainingLeaf(point);
    final K closest = _closestInLeaf(leaf?.points, point);
    double outerRadius = closest != null
        ? closest.distanceTo(point)
        : max(leaf.maxX - leaf.minX, leaf.maxY - leaf.minY);
    double innerRadius = 0.0;
    final Map<K, V> searchPoints = <K, V>{};
    final List<K> result = <K>[];
    while (result.length < k && outerRadius < within) {
      findInRing(point.x, point.y, innerRadius, outerRadius, searchPoints);
      final List<K> sorted = searchPoints.keys.toList();
      sorted.sort((K a, K b) =>
          (a.squaredDistanceTo(point) - b.squaredDistanceTo(point)).round());
      result.addAll(sorted.take(k - result.length));
      innerRadius = outerRadius;
      outerRadius = 1.5 * innerRadius;
      searchPoints.clear();
    }
    return result;
  }
}

class QuadTreeSet<E extends Point<double>> extends SetBase<E> {
  QuadTreeSet(
    double minX,
    double maxX,
    double minY,
    double maxY, {
    int maxLeafSize = 10,
  }) : _map =
            QuadTreeMap<E, E>(minX, maxX, minY, maxY, maxLeafSize: maxLeafSize);

  final QuadTreeMap<E, E> _map;

  @override
  bool add(E value) {
    if (_map.containsKey(value)) {
      return false;
    }
    _map[value] = value;
    return true;
  }

  @override
  bool contains(Object element) {
    final E e = element;
    return _map.containsKey(e);
  }

  @override
  E lookup(Object element) {
    final E e = element;
    return _map[e];
  }

  @override
  bool remove(Object value) {
    final E e = value;
    if (_map.containsKey(e)) {
      _map.remove(e);
      return true;
    }
    return false;
  }

  @override
  void clear() {
    _map.clear();
  }

  Iterable<E> get _iterable => _map.keys;

  @override
  Iterator<E> get iterator => _iterable.iterator;

  @override
  int get length => _iterable.length;

  @override
  Set<E> toSet() => _iterable.toSet();

  /// Populates the [Set] [outResult] with all elements that lie within
  /// the rectangle defined by the provided dimensions.
  void findInRect(double minRectX, double maxRectX, double minRectY,
      double maxRectY, Set<E> outResult) {
    final Map<E, E> mapResult = <E, E>{};
    _map.findInRect(minRectX, maxRectX, minRectY, maxRectY, mapResult);
    outResult.addAll(mapResult.keys);
  }

  /// Populates the [Set] [outResult] with all elements that lie within
  /// the circle defined by the provided dimensions.
  void findInCircle(
      double centerX, double centerY, double radius, Set<E> outResult) {
    final Map<E, E> mapResult = <E, E>{};
    _map.findInCircle(centerX, centerY, radius, mapResult);
    outResult.addAll(mapResult.keys);
  }

  /// Populates the [Set] [outResult] with all elements that lie within
  /// the ring defined by [innerRadius] and [outerRadius].
  void findInRing(double centerX, double centerY, double innerRadius,
      double outerRadius, Set<E> outResult) {
    final Map<E, E> mapResult = <E, E>{};
    _map.findInRing(centerX, centerY, innerRadius, outerRadius, mapResult);
    outResult.addAll(mapResult.keys);
  }

  /// Returns the element of the set that is closest in euclidian distance to
  /// the given point [point].
  E findNearestPoint(E point) => _map.findNearestPoint(point);

  /// Returns up to k elements of the set that are the closest in euclidian
  /// distancce to [point], sorted in order of increasing distance.
  List<E> findNearestPoints(E point, int k) => _map.findNearestPoints(point, k);
}
