"use client";

import { useEffect, useRef, useState } from "react";

import {
  hasMetWatchThreshold,
  initialVideoWatchState,
  recordVideoSample,
  watchedPercentage,
  type VideoWatchState,
} from "@/domain/media/video-progress";
import { AppButton } from "@/shared/ui/controls/actions";

type PlaybackState = "loading" | "ready" | "waiting" | "offline" | "unsupported" | "error";

export function ProgramVideoPlayer({
  autoplay = false,
  captionsSrc,
  enrollmentId,
  onWatchProgress,
  requiredPercentage = 90,
  src,
  stepId,
  textAlternative,
}: Readonly<{
  autoplay?: boolean;
  captionsSrc: string;
  enrollmentId: string;
  onWatchProgress?: (progress: Readonly<{ completed: boolean; percentage: number }>) => void;
  requiredPercentage?: number;
  src: string;
  stepId: string;
  textAlternative: string;
}>) {
  const videoReference = useRef<HTMLVideoElement>(null);
  const watchStateReference = useRef<VideoWatchState>(initialVideoWatchState);
  const [autoplayBlocked, setAutoplayBlocked] = useState(false);
  const [playbackState, setPlaybackState] = useState<PlaybackState>("loading");
  const [percentage, setPercentage] = useState(0);
  const resumeKey = `msc.video.resume.${enrollmentId}.${stepId}`;

  function savePosition() {
    const video = videoReference.current;
    if (!video || !Number.isFinite(video.currentTime)) return;
    try {
      window.localStorage.setItem(resumeKey, String(video.currentTime));
    } catch {
      // Resume is a convenience. Playback remains usable when storage is blocked.
    }
  }

  function updateWatchProgress() {
    const video = videoReference.current;
    if (!video || !Number.isFinite(video.duration) || video.duration <= 0) return;
    watchStateReference.current = recordVideoSample(
      watchStateReference.current,
      video.currentTime,
      video.duration,
    );
    const nextPercentage = watchedPercentage(watchStateReference.current, video.duration);
    setPercentage(nextPercentage);
    onWatchProgress?.({
      completed: hasMetWatchThreshold(
        watchStateReference.current,
        video.duration,
        requiredPercentage,
      ),
      percentage: nextPercentage,
    });
    savePosition();
  }

  useEffect(() => {
    const handleVisibility = () => {
      if (document.visibilityState === "hidden") savePosition();
    };
    const handleOffline = () => setPlaybackState("offline");
    const handleOnline = () => setPlaybackState("ready");
    document.addEventListener("visibilitychange", handleVisibility);
    window.addEventListener("offline", handleOffline);
    window.addEventListener("online", handleOnline);
    return () => {
      savePosition();
      document.removeEventListener("visibilitychange", handleVisibility);
      window.removeEventListener("offline", handleOffline);
      window.removeEventListener("online", handleOnline);
    };
  });

  function restoreAndMaybePlay() {
    const video = videoReference.current;
    if (!video) return;
    try {
      const saved = Number(window.localStorage.getItem(resumeKey));
      if (Number.isFinite(saved) && saved > 0 && saved < video.duration - 1)
        video.currentTime = saved;
    } catch {
      // Resume remains optional when storage is unavailable.
    }
    setPlaybackState("ready");
    if (autoplay) {
      void video.play().catch(() => setAutoplayBlocked(true));
    }
  }

  function retry() {
    const video = videoReference.current;
    if (!video) return;
    setPlaybackState("loading");
    video.load();
  }

  return (
    <section aria-label="Video aktivitas" className="program-video">
      <video
        controls
        muted={autoplay}
        onCanPlay={() => setPlaybackState("ready")}
        onError={() =>
          setPlaybackState(videoReference.current?.error?.code === 4 ? "unsupported" : "error")
        }
        onLoadedMetadata={restoreAndMaybePlay}
        onPlaying={() => setPlaybackState("ready")}
        onTimeUpdate={updateWatchProgress}
        onWaiting={() => setPlaybackState(navigator.onLine ? "waiting" : "offline")}
        playsInline
        preload="metadata"
        ref={videoReference}
        src={src}
      >
        <track default kind="captions" label="Bahasa Indonesia" src={captionsSrc} srcLang="id" />
        Browser tidak mendukung pemutar video. Gunakan alternatif teks di bawah.
      </video>
      <p className="program-video__alternative">{textAlternative}</p>
      <div className="app-progress">
        <div className="app-progress__label">
          <span>Progres tontonan teramati</span>
          <strong>{percentage}%</strong>
        </div>
        <progress aria-label="Progres tontonan teramati" max={100} value={percentage} />
      </div>
      <p aria-live="polite" className="program-video__status">
        {playbackState === "loading" ? "Menyiapkan video…" : null}
        {playbackState === "waiting"
          ? "Koneksi melambat. Video akan dilanjutkan saat data tersedia."
          : null}
        {playbackState === "offline"
          ? "Koneksi terputus. Posisi tontonan disimpan di perangkat ini."
          : null}
        {playbackState === "unsupported" ? "Format video tidak didukung browser ini." : null}
        {playbackState === "error" ? "Video belum dapat diputar." : null}
        {autoplayBlocked ? "Pemutaran otomatis diblokir browser. Tekan Putar untuk memulai." : null}
      </p>
      {playbackState === "offline" ||
      playbackState === "unsupported" ||
      playbackState === "error" ? (
        <AppButton onClick={retry} variant="secondary">
          Coba lagi
        </AppButton>
      ) : null}
      <p className="program-video__authority">
        Progres ini hanya pratinjau perangkat. Penyelesaian dan poin tetap divalidasi server.
      </p>
    </section>
  );
}
