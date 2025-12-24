# Download android apk at:
https://github.com/Kanishk-Goel-19/gdg-translator/releases/download/v1.0/app-release.apk

 # LectureLive 🎓

Event: Fresher's TechSprint — Organized by GDG on Campus IIT Mandi

LectureLive is a real-time translation application designed to bridge language barriers in educational environments. It enables instructors to broadcast audio that is instantly transcribed and translated into the student's preferred language on their local device.

 ## Key Features

Real-Time Transcription: Instant speech-to-text conversion for the broadcaster.

On-Device Translation: Utilizes Google ML Kit for private, offline-capable translation.

Low Latency Sync: Powered by Firebase Firestore for immediate subtitle delivery.

Regional Language Support: Specialized support for Indian languages (Hindi, Bengali, Tamil, Telugu, Marathi, etc.) alongside major international languages.

Dual Input Modes: Supports both voice broadcasting and manual text entry.

## Tech Stack

Frontend: Flutter (Dart)

Backend: Firebase Firestore (Real-time Database)

Machine Learning: Google ML Kit (On-Device Translation)

Audio Processing: speech_to_text package

## User Workflow

### Teacher (Broadcaster)

Select Teacher mode and grant microphone permissions.

Share the unique Lecture ID displayed on the screen.

Tap Start Speaking to begin the session.

### Student (Receiver)

Select Student mode.

Enter Name and the provided Lecture ID.

Select the Source Language (Teacher's) and Target Language (Student's).

Tap Join Class to receive live, translated subtitles.

