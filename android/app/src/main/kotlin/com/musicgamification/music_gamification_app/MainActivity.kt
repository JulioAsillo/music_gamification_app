package com.musicgamification.music_gamification_app

import com.ryanheise.audioservice.AudioServiceActivity

// audio_service necesita que la Activity extienda AudioServiceActivity;
// con FlutterActivity el reproductor cae al modo de respaldo sin notificaciones.
class MainActivity : AudioServiceActivity()

