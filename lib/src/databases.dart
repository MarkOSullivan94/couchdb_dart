import 'dart:async';
import 'dart:convert';

import 'exceptions/couchdb_exception.dart';
import 'interfaces/client_interface.dart';
import 'interfaces/databases_interface.dart';
import 'responses/api_response.dart';
import 'responses/databases_response.dart';
import 'utils/includer_path.dart';

/// Class that implements methods for interacting with entire database
/// in CouchDB
class Databases implements DatabasesInterface {
  /// Instance of connected client
  final ClientInterface _client;

  /// Create Databases by accepting web-based or server-based client
  Databases(this._client);

  @override
  Future<DatabasesResponse> headDbInfo(String dbName) async {
    ApiResponse result;
    try {
      result = await _client.head(dbName);
    } on CouchDbException catch (e) {
      e.response = ApiResponse(<String, String>{
        'error': 'Not found',
        'reason': 'Database doesn\'t exist.'
      }).errorResponse()!;
      rethrow;
    }
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> query(
      String dbName, String dbDoc, String dbView, List<String> keys) async {
    final body = <String, List<String>>{'keys': keys};
    var result =
        await _client.post('$dbName/_design/$dbDoc/_view/$dbView', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> dbInfo(String dbName) async {
    var result = await _client.get(dbName);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> createDb(String dbName, {int q = 8}) async {
    final regexp = RegExp(r'^[a-z][a-z0-9_$()+/-]*$');

    if (!regexp.hasMatch(dbName)) {
      throw ArgumentError(r'''Incorrect db name!
      Name must be validating by this rules:
        - Name must begin with a lowercase letter (a-z)
        - Lowercase characters (a-z)
        - Digits (0-9)
        - Any of the characters _, $, (, ), +, -, and /.''');
    }

    final path = '$dbName?q=$q';
    final result = await _client.put(path);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> deleteDb(String dbName) async {
    final result = await _client.delete(dbName);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> createDocIn(String dbName, Map<String, Object> doc,
      {required String batch, Map<String, String> headers = const {}}) async {
    final path = '$dbName${includeNonNullParam('?batch', batch)}';

    final result = await _client.post(path, body: doc, reqHeaders: headers);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> allDocs(String dbName,
      {bool conflicts = false,
      bool descending = false,
      Object endKey = '',
      String endKeyDocId = '',
      bool group = false,
      int? groupLevel,
      bool includeDocs = false,
      bool attachments = false,
      bool altEncodingInfo = false,
      bool inclusiveEnd = true,
      Object? key,
      List<Object> keys = const [],
      int? limit,
      bool? reduce,
      int? skip,
      bool sorted = true,
      bool stable = false,
      String? stale,
      Object? startKey,
      String? startKeyDocId,
      String? update,
      bool updateSeq = false}) async {
    final result = await _client.get(
      '$dbName/_all_docs'
      '?conflicts=$conflicts'
      '&descending=$descending'
      '&endkey=$endKey'
      '&endkey_docid=$endKeyDocId'
      '&group=$group'
      '&group_level=${groupLevel ?? ''}'
      '&include_docs=$includeDocs'
      '&attachments=$attachments'
      '&alt_encoding_info=$altEncodingInfo'
      '&inclusive_end=$inclusiveEnd'
      '&key=${key ?? ''}'
      '&keys=$keys'
      '&limit=$limit'
      '&reduce=${reduce ?? ''}'
      '&skip=$skip'
      '&sorted=$sorted'
      '&stable=$stable'
      '&stale=${stale ?? ''}'
      '&startkey=${startKey ?? ''}'
      '&startkey_docid=${startKeyDocId ?? ''}'
      '&update=${update ?? ''}'
      '&update_seq=$updateSeq',
    );
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> docsByKeys(String dbName,
      {List<String>? keys}) async {
    final body = <String, List<String>?>{'keys': keys};

    final result = keys == null
        ? await _client.post('$dbName/_all_docs')
        : await _client.post('$dbName/_all_docs', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> allDesignDocs(String dbName,
      {bool conflicts = false,
      bool descending = false,
      String? endKey,
      String? endKeyDocId,
      bool includeDocs = false,
      bool inclusiveEnd = true,
      String? key,
      String? keys,
      int? limit,
      int skip = 0,
      String? startKey,
      String? startKeyDocId,
      bool updateSeq = false}) async {
    final path = '$dbName/_design_docs?'
        'conflicts=$conflicts'
        '&descending=$descending'
        '&endkey=${endKey ?? ''}'
        '&endkey_docid=${endKeyDocId ?? ''}'
        '&include_docs=$includeDocs'
        '&inclusive_end=$inclusiveEnd'
        '&key=${key ?? ''}'
        '&keys=${keys ?? ''}'
        '&limit=${limit ?? ''}'
        '&skip=$skip'
        '&startkey=${startKey ?? ''}'
        '&startkey_docid=${startKeyDocId ?? ''}'
        '&update_seq=$updateSeq';

    final result = await _client.get(path);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> designDocsByKeys(
      String dbName, List<String> keys) async {
    final body = <String, List<String>>{'keys': keys};
    final result = await _client.post('$dbName/_design_docs', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> queriesDocsFrom(
      String dbName, List<Map<String, Object>> queries) async {
    final body = <String, List<Map<String, Object>>>{'queries': queries};
    final result = await _client.post('$dbName/_all_docs/queries', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> bulkDocs(String dbName, List<Object> docs,
      {required bool revs}) async {
    final body = <String, List<Object>>{'docs': docs};
    final result = await _client.post('$dbName?revs=$revs', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> insertBulkDocs(String dbName, List<Object> docs,
      {bool newEdits = true, Map<String, String> headers = const {}}) async {
    final body = <String, Object>{'docs': docs, 'new_edits': newEdits};
    final result = await _client.post('$dbName/_bulk_docs',
        body: body, reqHeaders: headers);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> find(String dbName, Map<String, Object> selector,
      {int limit = 25,
      int? skip,
      List<Object>? sort,
      List<String>? fields,
      Object? useIndex,
      int r = 1,
      String bookmark = '',
      bool update = true,
      bool? stable,
      String stale = 'false',
      bool executionStats = false}) async {
    final body = <String, Object>{
      'selector': selector,
      'limit': limit,
      'r': r,
      'bookmark': bookmark,
      'update': update,
      'stale': stale,
      'execution_stats': executionStats
    };
    if (skip != null) {
      body['skip'] = skip;
    }
    if (sort != null) {
      body['sort'] = sort;
    }
    if (fields != null) {
      body['fields'] = fields;
    }
    if (useIndex != null) {
      body['use_index'] = useIndex;
    }
    if (stable != null) {
      body['stable'] = stable;
    }

    final result = await _client.post('$dbName/_find', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> createIndexIn(
    String dbName, {
    required List<String> indexFields,
    String? ddoc,
    String? name,
    String type = 'json',
    Map<String, Object>? partialFilterSelector,
  }) async {
    final body = <String, Object>{
      'index': <String, List<String>>{'fields': indexFields},
      'type': type
    };
    if (ddoc != null) {
      body['ddoc'] = ddoc;
    }
    if (name != null) {
      body['name'] = name;
    }
    if (partialFilterSelector != null) {
      body['partial_filter_selector'] = partialFilterSelector;
    }

    final result = await _client.post('$dbName/_index', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> indexesAt(String dbName) async {
    final result = await _client.get('$dbName/_index');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> deleteIndexIn(
      String dbName, String designDoc, String name) async {
    final result = await _client.delete('$dbName/_index/$designDoc/json/$name');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> explain(
    String dbName,
    Map<String, Object> selector, {
    int limit = 25,
    int? skip,
    List<Object>? sort,
    List<String>? fields,
    Object? useIndex,
    int r = 1,
    String bookmark = '',
    bool update = true,
    bool? stable,
    String stale = 'false',
    bool executionStats = false,
  }) async {
    final body = <String, Object>{
      'selector': selector,
      'limit': limit,
      'r': r,
      'bookmark': bookmark,
      'update': update,
      'stale': stale,
      'execution_stats': executionStats
    };
    if (skip != null) {
      body['skip'] = skip;
    }
    if (sort != null) {
      body['sort'] = sort;
    }
    if (fields != null) {
      body['fields'] = fields;
    }
    if (useIndex != null) {
      body['use_index'] = useIndex;
    }
    if (stable != null) {
      body['stable'] = stable;
    }

    final result = await _client.post('$dbName/_explain', body: body);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> shards(String dbName) async {
    final result = await _client.get('$dbName/_shards');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> shard(String dbName, String docId) async {
    final result = await _client.get('$dbName/_shards/$docId');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> synchronizeShards(String dbName) async {
    final result = await _client.post('$dbName/_sync_shards');
    return DatabasesResponse.from(result);
  }

  @override
  Future<Stream<DatabasesResponse>> changesIn(
    String dbName, {
    List<String>? docIds,
    bool conflicts = false,
    bool descending = false,
    String feed = 'normal',
    String? filter,
    int heartbeat = 60000,
    bool includeDocs = false,
    bool attachments = false,
    bool attEncodingInfo = false,
    int? lastEventId,
    int? limit,
    String since = '0',
    String style = 'main_only',
    int timeout = 60000,
    String? view,
    int? seqInterval,
  }) async {
    final docIdsJson = docIds != null ? json.encode(docIds) : null;
    final path = '$dbName/_changes?'
        'doc_ids=${docIdsJson ?? ''}'
        '&conflicts=$conflicts&'
        'descending=$descending'
        '&feed=$feed'
        '&filter=$filter'
        '&heartbeat=$heartbeat'
        '&include_docs=$includeDocs'
        '&attachments=$attachments'
        '&att_encoding_info=$attEncodingInfo'
        '&last-event-id=${lastEventId ?? ''}'
        '&limit=${limit ?? ''}'
        '&since=$since'
        '&style=$style'
        '&timeout=$timeout'
        '&view=${view ?? ''}'
        '&seq_interval=${seqInterval ?? ''}';

    final streamedRes = await _client.streamed('get', path);

    switch (feed) {
      case 'longpoll':
        var strRes = await streamedRes.join();
        strRes = '{"results": [$strRes';
        return Stream<DatabasesResponse>.fromFuture(
            Future<DatabasesResponse>.value(
                DatabasesResponse.from(ApiResponse(jsonDecode(strRes)))));

      case 'continuous':
        {
          late StreamSubscription sub;
          late StreamController<DatabasesResponse> controller;
          controller = StreamController<DatabasesResponse>(
            onListen: () {
              sub = streamedRes.listen((String data) {
                final hasData = data.trim().isNotEmpty;
                if (hasData) {
                  final result =
                      ApiResponse(jsonDecode('{"results": [$data]}'));
                  controller.add(DatabasesResponse.from(result));
                }
              }, onError: controller.addError, cancelOnError: true);
            },
            onCancel: () => sub.cancel(),
          );
          return controller.stream;
        }

      case 'eventsource':
        final mappedRes = streamedRes
            .map((v) => v.replaceAll(RegExp('\n+data'), '},\n{data'))
            .map((v) => v.replaceAll('data', '"data"'))
            .map((v) => v.replaceAll('\nid', ',\n"id"'));
        return mappedRes.map((v) => DatabasesResponse.from(
            ApiResponse(jsonDecode('{"results": [{$v}]}'))));

      default:
        var strRes = await streamedRes.join();
        strRes = '{"results": [$strRes';
        return Stream<DatabasesResponse>.fromFuture(
            Future<DatabasesResponse>.value(
                DatabasesResponse.from(ApiResponse(jsonDecode(strRes)))));
    }
  }

  @override
  Future<Stream<DatabasesResponse>> postChangesIn(
    String dbName, {
    List<String>? docIds,
    bool conflicts = false,
    bool descending = false,
    String feed = 'normal',
    String filter = '_doc_ids',
    int heartbeat = 60000,
    bool includeDocs = false,
    bool attachments = false,
    bool attEncodingInfo = false,
    int? lastEventId,
    int? limit,
    String since = '0',
    String style = 'main_only',
    int timeout = 60000,
    String? view,
    int? seqInterval,
  }) async {
    final path = '$dbName/_changes?'
        'conflicts=$conflicts'
        '&descending=$descending'
        '&feed=$feed'
        '&filter=$filter&heartbeat=$heartbeat&'
        'include_docs=$includeDocs'
        '&attachments=$attachments'
        '&att_encoding_info=$attEncodingInfo'
        '&last-event-id=${lastEventId ?? ''}'
        '&limit=${limit ?? ''}'
        '&since=$since'
        '&style=$style'
        '&timeout=$timeout'
        '&view=${view ?? ''}'
        '&seq_interval=${seqInterval ?? ''}';

    final body = <String, List<String>>{'doc_ids': docIds ?? []};

    final streamedRes = await _client.streamed('post', path, body: body);

    switch (feed) {
      case 'longpoll':
        var strRes = await streamedRes.join();
        strRes = '{"results": [$strRes';
        return Stream<DatabasesResponse>.fromFuture(
            Future<DatabasesResponse>.value(
                DatabasesResponse.from(ApiResponse(jsonDecode(strRes)))));

      case 'continuous':
        {
          late StreamSubscription sub;
          late StreamController<DatabasesResponse> controller;
          controller = StreamController<DatabasesResponse>(
            onListen: () {
              sub = streamedRes.listen((String data) {
                final hasData = data.trim().isNotEmpty;
                if (hasData) {
                  final result =
                      ApiResponse(jsonDecode('{"results": [$data]}'));
                  controller.add(DatabasesResponse.from(result));
                }
              }, onError: controller.addError, cancelOnError: true);
            },
            onCancel: () => sub.cancel(),
          );
          return controller.stream;
        }

      case 'eventsource':
        final mappedRes = streamedRes
            .map((v) => v.replaceAll(RegExp('\n+data'), '},\n{data'))
            .map((v) => v.replaceAll('data', '"data"'))
            .map((v) => v.replaceAll('\nid', ',\n"id"'));
        return mappedRes.map((v) => DatabasesResponse.from(
            ApiResponse(jsonDecode('{"results": [{$v}]}'))));

      default:
        var strRes = await streamedRes.join();
        strRes = '{"results": [$strRes';
        return Stream<DatabasesResponse>.fromFuture(
            Future<DatabasesResponse>.value(
                DatabasesResponse.from(ApiResponse(jsonDecode(strRes)))));
    }
  }

  @override
  Future<DatabasesResponse> compact(String dbName) async {
    final result = await _client.post('$dbName/_compact');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> compactViewIndexesWith(
      String dbName, String ddocName) async {
    final result = await _client.post('$dbName/_compact/$ddocName');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> ensureFullCommit(String dbName) async {
    final result = await _client.post('$dbName/_ensure_full_commit');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> viewCleanup(String dbName) async {
    final result = await _client.post('$dbName/_view_cleanup');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> securityOf(String dbName) async {
    final result = await _client.get('$dbName/_security');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> setSecurityFor(
      String dbName, Map<String, Map<String, List<String>>> security) async {
    final result = await _client.put('$dbName/_security', body: security);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> purge(
      String dbName, Map<String, List<String>> docs) async {
    final result = await _client.post('$dbName/_purge', body: docs);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> purgedInfosLimit(String dbName) async {
    final result = await _client.get('$dbName/_purged_infos_limit');
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> setPurgedInfosLimit(
      String dbName, int limit) async {
    final result =
        await _client.put('$dbName/_purged_infos_limit', body: limit);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> missingRevs(
      String dbName, Map<String, List<String>> revs) async {
    final result =
        await _client.post('$dbName/_missing_revs', body: revs);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> revsDiff(
      String dbName, Map<String, List<String>> revs) async {
    final result = await _client.post('$dbName/_revs_diff', body: revs);
    return DatabasesResponse.from(result);
  }

  @override
  Future<DatabasesResponse> revsLimitOf(String dbName) async {
    final result = await _client.get('$dbName/_revs_limit');
    return DatabasesResponse.from(result);
  }

  /// Sets the maximum number of document revisions that will be tracked by CouchDB,
  /// even after compaction has occurred
  @override
  Future<DatabasesResponse> setRevsLimit(String dbName, int limit) async {
    final result = await _client.put('$dbName/_revs_limit', body: limit);
    return DatabasesResponse.from(result);
  }
}
