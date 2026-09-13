extension NullableExtensions<T> on T? {
  bool get isNull => this == null;
  bool get isNotNull => this != null;

  T orElse(T Function() defaultValue) => this ?? defaultValue();
  T orDefault(T defaultValue) => this ?? defaultValue;

  void ifNotNull(void Function(T value) action) {
    if (this != null) action(this as T);
  }

  T? ifNotNullElse(T? Function() defaultValue) => this ?? defaultValue();

  R? map<R>(R Function(T value) mapper) =>
      this == null ? null : mapper(this as T);

  R mapOrElse<R>(R Function(T value) mapper, R Function() defaultValue) =>
      this == null ? defaultValue() : mapper(this as T);
}

extension StringExtensions on String {
  String capitalize() =>
      isEmpty ? this : '${this[0].toUpperCase()}${substring(1).toLowerCase()}';

  String capitalizeWords() => split(' ').map((w) => w.capitalize()).join(' ');

  bool get isNotBlank => trim().isNotEmpty;

  String get trimmed => trim();

  String removeAllWhitespace() => replaceAll(RegExp(r'\s+'), '');

  String truncate(int maxLength, {String suffix = '...'}) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength - suffix.length)}$suffix';
  }
}

extension IterableExtensions<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
  T? get lastOrNull => isEmpty ? null : last;

  List<T> distinctBy<K>(K Function(T element) key) {
    final seen = <K>{};
    return where((element) => seen.add(key(element))).toList();
  }

  Map<K, List<T>> groupBy<K>(K Function(T element) key) {
    final map = <K, List<T>>{};
    for (final element in this) {
      map.putIfAbsent(key(element), () => []).add(element);
    }
    return map;
  }
}

extension MapExtensions<K, V> on Map<K, V> {
  V? getOrElse(K key, V Function() defaultValue) => this[key] ?? defaultValue();

  Map<K2, V2> mapKeys<K2, V2>(
    MapEntry<K2, V2> Function(MapEntry<K, V> entry) transform,
  ) {
    return Map.fromEntries(entries.map(transform));
  }

  Map<K, V2> mapValues<V2>(V2 Function(V value) transform) {
    return Map.fromEntries(
      entries.map((e) => MapEntry(e.key, transform(e.value))),
    );
  }

  void addAllIf(Map<K, V>? other) {
    if (other != null) addAll(other);
  }
}

extension IntExtensions on int {
  Duration get seconds => Duration(seconds: this);
  Duration get minutes => Duration(minutes: this);
  Duration get hours => Duration(hours: this);
  Duration get days => Duration(days: this);

  String get formattedDuration {
    final hours = this ~/ 3600;
    final minutes = (this % 3600) ~/ 60;
    final seconds = this % 60;
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension DateTimeExtensions on DateTime {
  String get formattedDate =>
      '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';

  String get formattedTime =>
      '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';

  String get timeAgo {
    final now = DateTime.now();
    final difference = now.difference(this);
    if (difference.inDays > 0) return '${difference.inDays}d ago';
    if (difference.inHours > 0) return '${difference.inHours}h ago';
    if (difference.inMinutes > 0) return '${difference.inMinutes}m ago';
    return 'Just now';
  }

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

extension DurationExtensions on Duration {
  String get formatted {
    final hours = inHours;
    final minutes = inMinutes.remainder(60);
    final seconds = inSeconds.remainder(60);
    if (hours > 0) {
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
    }
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}

extension BoolExtensions on bool {
  int get toInt => this ? 1 : 0;
}
