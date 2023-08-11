part of 'main.dart';

class MixdropApi {
  MixdropApi(this._email, this._apiKey, {bool enableLog = false}) {
    if (enableLog) {
      _dio.interceptors
          .add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }
  final String _email;
  final String _apiKey;
  final String _base = 'api.mixdrop.co';
  final String _postBase = 'ul.mixdrop.co';

  final _dio = Dio();

  Uri _apiUri(
    String unencodedPath, {
    bool? isNotNeedCredentials,
    Map<String, dynamic>? queryParameters,
    bool? isPost,
    bool? isOverride,
  }) {
    final params = (isNotNeedCredentials != null
        ? isNotNeedCredentials
            ? <String, dynamic>{}
            : <String, dynamic>{'email': _email, 'key': _apiKey}
        : <String, dynamic>{'email': _email, 'key': _apiKey})
      ..addAll(queryParameters ?? <String, dynamic>{})
      ..removeWhere((_, v) => v == null);

    final authority = isPost != null
        ? isPost
            ? _postBase
            : _base
        : _base;

    final uri = Uri.https(
      authority,
      '/$unencodedPath',
      params,
    );

    final parseDecode = Uri.parse(Uri.decodeFull(uri.toString()));

    final finalUri = isOverride != null
        ? isOverride
            ? parseDecode
            : uri
        : uri;

    return finalUri;
  }

  Future<LocalUpload> localUpload(File file) async {
    final id = await file.id;
    final name = file.fileNameAndExt;

    final form = FormData()
      ..files.add(MapEntry('file', await MultipartFile.fromFile(file.path)))
      ..fields.addAll([MapEntry('email', _email), MapEntry('key', _apiKey)]);

    final fetch = await _dio.postUri<String>(
      _apiUri(
        'api',
        isPost: true,
        isNotNeedCredentials: true,
      ),
      data: form,
      onSendProgress: (current, total) => fileTransferProgress.add(
        FileTransferProgress(
          'mixdrop_$id',
          name: name,
          current: current,
          total: total,
          isUpload: true,
        ),
      ),
    );

    return LocalUpload.fromJson(fetch.data!);
  }

  Future<RemoteUpload> remoteUpload(
    String url, {
    String? newName,
    int? folderId,
  }) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'remoteupload',
            queryParameters: {
              'url': Uri.encodeFull(url),
              'name': newName,
              'folder': '$folderId'
            },
          ),
        );

        return RemoteUpload.fromJson(fetch.data!);
      });

  Future<RemoteUploadStatus> remoteUploadStatus(
    int remoteUploadId,
  ) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'remotestatus',
            queryParameters: {
              'id': '$remoteUploadId',
            },
          ),
        );

        return RemoteUploadStatus.fromJson(fetch.data!);
      });

  Future<FileInfo> fileInfo(
    List<String> fileRefs,
  ) async =>
      Isolate.run(() async {
        final join = fileRefs
            .map(
              (value) => fileRefs.indexOf(value) == 0 ? value : 'ref[]=$value',
            )
            .join('&');

        final fetch = await _dio.getUri<String>(
          _apiUri(
            'fileinfo2',
            queryParameters: {'ref[]': join},
            isOverride: true,
          ),
        );

        return FileInfo.fromJson(fetch.data!);
      });

  Future<FileDuplicate> fileDuplicate(
    String fileRef,
  ) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'fileduplicate',
            queryParameters: {'ref': fileRef},
          ),
        );

        return FileDuplicate.fromJson(fetch.data!);
      });

  Future<FileRename> fileRename(
    String fileRef,
    String newName,
  ) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'filerename',
            queryParameters: {'ref': fileRef, 'title': newName},
          ),
        );

        return FileRename.fromJson(fetch.data!);
      });

  Future<FileRemoved> fileRemoved([int? page]) async => Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'removed',
            queryParameters: {'page': '$page'},
          ),
        );

        return FileRemoved.fromJson(fetch.data!);
      });

  Future<AddSubtitle> addSubtitle(
    String fileRef, {
    required File subtitleFile,
    required SubtitleLanguage language,
  }) async {
    if (subtitleFile.fileExt != 'srt' && subtitleFile.fileExt != 'vtt') {
      return AddSubtitle(success: false, result: 'Invalid file extension');
    } else {
      final form = FormData()
        ..fields.add(MapEntry('lang', '$language'))
        ..files.add(
          MapEntry('file', await MultipartFile.fromFile(subtitleFile.path)),
        );

      final fetch = await _dio.postUri<String>(
        _apiUri('addsubtitle', queryParameters: {'ref': fileRef}),
        data: form,
      );

      return AddSubtitle.fromJson(fetch.data!);
    }
  }

  Future<FolderList> folderList([int? folderId, int? page]) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'folderlist',
            queryParameters: {'id': '$folderId', 'page': '$page'},
          ),
        );

        return FolderList.fromJson(fetch.data!);
      });

  Future<FolderCreate> folderCreate(
    String folderName, [
    int? parentFolderId,
  ]) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'foldercreate',
            queryParameters: {'title': folderName, 'parent': '$parentFolderId'},
          ),
        );

        return FolderCreate.fromJson(fetch.data!);
      });

  Future<FolderRename> folderRename(
    String newFolderName,
    int folderId,
  ) async =>
      Isolate.run(() async {
        final fetch = await _dio.getUri<String>(
          _apiUri(
            'folderrename',
            queryParameters: {'id': '$folderId', 'title': newFolderName},
          ),
        );

        return FolderRename.fromJson(fetch.data!);
      });
}
