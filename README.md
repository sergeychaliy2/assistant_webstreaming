# Ассистент Вебстриминг — Assistant Webstreaming

Кроссплатформенное (Windows / Android) Flutter-приложение: **интерактивный AI-аватар** в реальном
времени. Пользователь говорит (push-to-talk) или печатает → речь распознаётся → текст уходит в
«мозг» аватара → фотореалистичный аватар **отвечает голосом и видео** с живыми субтитрами.

Видео/аудио аватара стримится через **HeyGen LiveAvatar API поверх LiveKit (WebRTC)**.
Распознавание речи — **OpenAI Whisper**.

---

## Возможности

- **Живой видеоаватар** — HeyGen LiveAvatar, низколатентный стрим по LiveKit/WebRTC.
- **Голосовой ввод (push-to-talk)** — удержание кнопки микрофона записывает аудио (AAC),
  по отпусканию оно распознаётся и отправляется аватару.
- **Текстовый ввод** — чат-панель: вопрос можно напечатать; если аватар говорит — его ответ
  прерывается перед новым вопросом.
- **Живые субтитры** — ответ аватара отображается текстом по мере озвучивания (стримятся по
  data-каналу LiveKit, с накоплением частичных чанков и авто-затуханием по тишине).
- **Sandbox-режим** — бесплатный тестовый аватар HeyGen без списания минут (сессия ограничена 58 сек).
- **Таймер сессии** — обратный отсчёт; по истечении сессия автоматически завершается.
- **Качество стриминга** — High (всегда верхний simulcast-слой) или Auto (адаптивно под канал).
- **Локализация интерфейса** — English / Русский / العربية (RTL), легко расширяется.
- **Выбор аватара / голоса / языка ассистента** — пресеты + возможность вставить свой HeyGen ID.
- **Кастомное окно (desktop)** — `window_manager`: скрытый системный титлбар, свой контрол окна,
  подтверждение выхода.

---

## Технологический стек

| Слой | Решение |
|---|---|
| Framework | **Flutter** (Dart SDK ^3.11) — Windows + Android |
| Realtime media | **livekit_client** (WebRTC) — видео/аудио аватара + data-канал управления |
| AI-аватар | **HeyGen LiveAvatar API** (REST handshake: token → start → keep-alive → stop) |
| Распознавание речи | **OpenAI Whisper** (`/v1/audio/transcriptions`) |
| Запись аудио | `record` (AAC) |
| Разрешения | `permission_handler` (микрофон) |
| Хранилище | `shared_preferences` (настройки), `path_provider` (временные файлы записи) |
| Окно (desktop) | `window_manager` |
| Графика | `flutter_svg` |
| Сеть | `http` |

---

## Архитектура

Слоистая структура: **config → services → controller → presentation**. UI ничего не знает о
HeyGen/LiveKit/STT — он слушает `SessionController` (через `ChangeNotifier`) и реагирует.

```
lib/
├── main.dart                      # вход: desktop-окно (window_manager) + загрузка настроек + runApp
├── config/
│   ├── app_config.dart            # эндпоинты, тайминги, API-ключи (см. «Секреты»)
│   └── heygen_config.dart         # снимок настроек → конфиг сессии (avatar/voice/lang/sandbox/quality)
├── controllers/
│   └── session_controller.dart    # ★ конечный автомат сессии (lifecycle, мик, таймер, ошибки)
├── services/
│   ├── heygen_service.dart        # HeyGen REST + LiveKit room + data-канал + субтитры + детектор тишины
│   ├── mic_recorder_service.dart  # запись микрофона (AAC) + уровень сигнала
│   ├── transcription_service.dart # отправка аудио в OpenAI Whisper → текст
│   ├── settings_service.dart      # персистентность настроек (shared_preferences)
│   └── disposable.dart            # интерфейс AsyncDisposable
├── data/
│   └── presets.dart               # каталог аватаров / голосов / языков
├── screens/
│   ├── splash_screen.dart         # стартовая анимация
│   ├── session_screen.dart        # главный экран: видео аватара + HUD + мик + чат + субтитры
│   └── settings_screen.dart       # настройки (язык, аватар, голос, sandbox, качество, субтитры)
├── widgets/                       # HUD-компоненты: mic_button, chat_panel, subtitle_strip,
│   │                              #   timer_bar, connecting_view, window_controls, и atoms/
│   └── atoms/                     # glass_circle, level_ring, pulse_halo, circle_press_target
├── theme/app_theme.dart           # тёмная тема, палитра, типографика
├── l10n/                          # app_strings.dart (En/Ru/Ar) + app_localization.dart (InheritedWidget)
└── utils/logger.dart              # лёгкий тегированный логгер
```

### Конечный автомат сессии (`SessionController`)

```
SessionPhase:      idle ──start()──► connecting ──ok──► live ──end()/таймер──► ended
InteractionState (когда live):  idle ⇄ recording ⇄ sending ⇄ avatarSpeaking
```

- `start()` создаёт `HeyGenService` из текущих настроек, поднимает сессию, запускает тикер таймера.
- При `live` подписан на `HeyGenService`: `subtitle` (текст) и `avatarTalking` (говорит ли аватар) —
  когда аватар замолкает, мик возвращается в центр.

### Поток одного вопроса (голосом)

```
[удержание мик] ──► MicRecorderService.start()                 (interaction = recording)
[отпускание]    ──► MicRecorderService.stop() → путь к .aac    (interaction = sending)
                ──► TranscriptionService.transcribe(path)       → OpenAI Whisper → текст
                ──► HeyGenService.sendToBrain(text)              (interaction = avatarSpeaking)
                       │ publishData по data-каналу LiveKit (topic = agent-control)
                       ▼
HeyGen стримит видео+аудио ответа в LiveKit room → RemoteVideoTrack рендерится,
   текстовые partials по data-каналу → ValueNotifier<subtitle> → SubtitleStrip
   замолчал (стоп-событие ИЛИ детектор тишины через AudioVisualizer) → interaction = idle
```

### Подключение HeyGen (`HeyGenService`)

```
POST /v1/sessions/token   (X-API-KEY)        → session_id, session_token
POST /v1/sessions/start   (Bearer token)     → livekit_url, livekit_client_token
LiveKit room.connect(url, token)             → подписка на video/audio + data-канал
POST /v1/sessions/keep_alive  каждые 20 сек  (пока сессия жива)
POST /v1/sessions/stop                        (при завершении)
```

> **Нюанс реализации:** LiveKit-развёртывание HeyGen не публикует per-speaker audio level, поэтому
> «говорит ли аватар» определяется клиентским `AudioVisualizer` (читает PCM-сэмплы) + детектором
> тишины по таймеру, а субтитры собираются из частичных событий разного формата (несколько алиасов
> имён событий по версиям протокола).

---

## Запуск и сборка

**Требования:** Flutter 3.35+ (Dart ^3.11), для Windows — JDK/VS toolchain Flutter desktop; для
Android — SDK + JDK 17.

```bash
flutter pub get

# Desktop (Windows)
flutter run -d windows

# Android
flutter run -d <device-id>
```

Релизные сборки:
```bash
flutter build windows --release       # → build/windows/x64/runner/Release/
flutter build apk --release           # → build/app/outputs/flutter-apk/app-release.apk
```

### Секреты / API-ключи

Ключи HeyGen и OpenAI и ID аватаров/голоса живут в `lib/config/app_config.dart`. Этот файл
**намеренно в `.gitignore`** и не попадает в репозиторий. Версионируется только шаблон
[`app_config.example.dart`](lib/config/app_config.example.dart) с плейсхолдерами.

Перед первым запуском создайте свой конфиг из шаблона и подставьте ключи:

```powershell
Copy-Item lib/config/app_config.example.dart lib/config/app_config.dart
# затем впишите свои HEYGEN/OPENAI ключи и ID аватаров
```

Для боевого окружения лучше вообще убрать ключи из клиента и проксировать запросы к OpenAI/HeyGen
через свой бэкенд.

---

## Тесты

```bash
flutter test
```

Покрыто: `heygen_config` (снимок настроек), `settings_service`, `transcription_service`,
виджеты `mic_button` и `timer_bar`.
