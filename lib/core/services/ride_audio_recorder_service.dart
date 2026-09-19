import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';

import 'config.dart';
import 'http.dart';

class RideAudioRecorderService {
  RideAudioRecorderService._();

  static final RideAudioRecorderService instance = RideAudioRecorderService._();

  final AudioRecorder _recorder = AudioRecorder();
  final Set<String> _uploadedBookings = <String>{};
  String? _activeBookingId;
  String? _activePath;
  bool _isBusy = false;

  Future<bool> requestMicrophonePermissionOnStart() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<void> start({
    required String bookingId,
    required BuildContext context,
  }) async {
    if (bookingId.isEmpty || _isBusy) return;
    if (_activeBookingId == bookingId && await _recorder.isRecording()) return;

    _isBusy = true;
    try {
      final hasPermission =
          await _recorder.hasPermission() ||
          await requestMicrophonePermissionOnStart();
      if (!hasPermission) return;

      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }

      final dir = await getTemporaryDirectory();
      final path =
          '${dir.path}/ride_${bookingId}_rider_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 44100,
        ),
        path: path,
      );

      _activeBookingId = bookingId;
      _activePath = path;
    } catch (error) {
      debugPrint('[RideAudio] rider start failed: $error');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> stopAndUpload({
    required String bookingId,
    required BuildContext context,
  }) async {
    if (bookingId.isEmpty || _uploadedBookings.contains(bookingId) || _isBusy) {
      return;
    }

    _isBusy = true;
    try {
      var path = _activePath;
      if (await _recorder.isRecording()) {
        path = await _recorder.stop();
      }

      if (path == null || path.isEmpty) return;
      final file = File(path);
      if (!await file.exists() || await file.length() == 0) {
        _activeBookingId = null;
        _activePath = null;
        return;
      }

      final response = await httpMultipartPost(
        Config.rideAudioRecording,
        {
          'booking_id': bookingId,
          'role': 'rider',
          'recorded_at': DateTime.now().toIso8601String(),
        },
        // ignore: use_build_context_synchronously
        context: context,
        fileField: 'audio',
        file: file,
      );

      if (response is Map && response['status'] == 200) {
        _uploadedBookings.add(bookingId);
        _activeBookingId = null;
        _activePath = null;
        try {
          await file.delete();
        } catch (_) {}
      }
    } catch (error) {
      debugPrint('[RideAudio] rider upload failed: $error');
    } finally {
      _isBusy = false;
    }
  }

  Future<void> dispose() async {
    await _recorder.dispose();
  }
}
