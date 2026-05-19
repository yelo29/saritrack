class SyncQueue {
  final int? id;
  final String method;
  final String endpoint;
  final String? payload;
  final String timestamp;
  final int retries;

  SyncQueue({
    this.id,
    required this.method,
    required this.endpoint,
    this.payload,
    required this.timestamp,
    this.retries = 0,
  });

  // Convert to map for database
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'method': method,
      'endpoint': endpoint,
      'payload': payload,
      'timestamp': timestamp,
      'retries': retries,
    };
  }

  // Create from map from database
  factory SyncQueue.fromMap(Map<String, dynamic> map) {
    return SyncQueue(
      id: map['id'] as int?,
      method: map['method'] as String,
      endpoint: map['endpoint'] as String,
      payload: map['payload'] as String?,
      timestamp: map['timestamp'] as String,
      retries: map['retries'] as int? ?? 0,
    );
  }

  // Copy with method for updates
  SyncQueue copyWith({
    int? id,
    String? method,
    String? endpoint,
    String? payload,
    String? timestamp,
    int? retries,
  }) {
    return SyncQueue(
      id: id ?? this.id,
      method: method ?? this.method,
      endpoint: endpoint ?? this.endpoint,
      payload: payload ?? this.payload,
      timestamp: timestamp ?? this.timestamp,
      retries: retries ?? this.retries,
    );
  }
}
