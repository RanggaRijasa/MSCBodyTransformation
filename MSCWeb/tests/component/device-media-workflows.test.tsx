import { fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { afterEach, describe, expect, it, vi } from "vitest";

import { ImageAcquisition } from "@/features/device-media/components/image-acquisition";
import { ProgramVideoPlayer } from "@/features/device-media/components/program-video-player";
import { SafeImageShareButton } from "@/features/device-media/components/safe-image-share-button";

afterEach(() => {
  vi.restoreAllMocks();
  window.localStorage.clear();
});

describe("alur media browser", () => {
  it("memproses pilihan galeri dan mencabut object URL ketika foto dihapus", async () => {
    const user = userEvent.setup();
    const thumbnail = new Blob(["thumbnail"], { type: "image/jpeg" });
    const processedImage = {
      descriptor: { byteSize: 4, height: 480, mimeType: "image/jpeg" as const, width: 640 },
      fullImage: new Blob(["full"], { type: "image/jpeg" }),
      thumbnail,
    };
    const process = vi.fn().mockResolvedValue(processedImage);
    const createObjectUrl = vi.fn().mockReturnValue("blob:msc-preview");
    const revokeObjectUrl = vi.fn();
    Object.defineProperty(URL, "createObjectURL", { configurable: true, value: createObjectUrl });
    Object.defineProperty(URL, "revokeObjectURL", { configurable: true, value: revokeObjectUrl });
    const onProcessed = vi.fn();

    render(<ImageAcquisition onProcessed={onProcessed} processor={{ process }} />);
    const input = screen.getByText("Pilih dari galeri").closest("label")?.querySelector("input");
    expect(input).not.toBeNull();
    await user.upload(
      input as HTMLInputElement,
      new File(["photo"], "photo.png", { type: "image/png" }),
    );

    await waitFor(() => expect(onProcessed).toHaveBeenCalledWith(processedImage));
    expect(createObjectUrl).toHaveBeenCalledWith(thumbnail);
    expect(screen.getByRole("img", { name: "Pratinjau foto yang dipilih" })).toBeVisible();
    expect(screen.queryByRole("button", { name: /foto demo/i })).not.toBeInTheDocument();

    await user.click(screen.getByRole("button", { name: "Hapus foto" }));
    expect(revokeObjectUrl).toHaveBeenCalledOnce();
    expect(screen.getByText("Belum ada foto dipilih.")).toBeVisible();
  });

  it("memakai Web Share untuk file ketika browser mendukungnya", async () => {
    const share = vi.fn().mockResolvedValue(undefined);
    Object.defineProperty(navigator, "canShare", {
      configurable: true,
      value: vi.fn().mockReturnValue(true),
    });
    Object.defineProperty(navigator, "share", { configurable: true, value: share });
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        .mockResolvedValue(
          new Response(new Blob(["qr"], { type: "image/svg+xml" }), { status: 200 }),
        ),
    );

    render(<SafeImageShareButton fileName="qr-coach.svg" sourceUrl="/api/coach/qr-image" />);
    await userEvent.click(screen.getByRole("button", { name: "Bagikan QR" }));

    await waitFor(() => expect(share).toHaveBeenCalledOnce());
    expect(screen.getByText("QR dibagikan.")).toBeVisible();
  });

  it("mengunduh lalu mencabut object URL jika Web Share tidak tersedia", async () => {
    Object.defineProperty(navigator, "canShare", { configurable: true, value: undefined });
    Object.defineProperty(navigator, "share", { configurable: true, value: undefined });
    vi.stubGlobal(
      "fetch",
      vi
        .fn()
        .mockResolvedValue(
          new Response(new Blob(["qr"], { type: "image/svg+xml" }), { status: 200 }),
        ),
    );
    const createObjectUrl = vi.fn().mockReturnValue("blob:qr-download");
    const revokeObjectUrl = vi.fn();
    Object.defineProperty(URL, "createObjectURL", { configurable: true, value: createObjectUrl });
    Object.defineProperty(URL, "revokeObjectURL", { configurable: true, value: revokeObjectUrl });
    vi.spyOn(HTMLAnchorElement.prototype, "click").mockImplementation(() => undefined);

    render(<SafeImageShareButton fileName="qr-coach.svg" sourceUrl="/api/coach/qr-image" />);
    await userEvent.click(screen.getByRole("button", { name: "Bagikan QR" }));

    expect(await screen.findByText(/diunduh karena fitur Bagikan tidak tersedia/)).toBeVisible();
    await waitFor(() => expect(revokeObjectUrl).toHaveBeenCalledWith("blob:qr-download"));
  });

  it("memulihkan posisi video, menghitung tontonan unik, dan menyimpan progres lokal", () => {
    const onWatchProgress = vi.fn();
    window.localStorage.setItem("msc.video.resume.enrollment-1.step-1", "4");
    render(
      <ProgramVideoPlayer
        captionsSrc="/captions/step-1.vtt"
        enrollmentId="enrollment-1"
        onWatchProgress={onWatchProgress}
        src="/video/step-1.mp4"
        stepId="step-1"
        textAlternative="Ikuti rangkaian gerakan sesuai kemampuan."
      />,
    );
    const video = document.querySelector("video") as HTMLVideoElement;
    Object.defineProperty(video, "duration", { configurable: true, value: 10 });
    Object.defineProperty(video, "currentTime", { configurable: true, writable: true, value: 0 });

    fireEvent.loadedMetadata(video);
    expect(video.currentTime).toBe(4);
    video.currentTime = 5;
    fireEvent.timeUpdate(video);
    video.currentTime = 7;
    fireEvent.timeUpdate(video);

    expect(onWatchProgress).toHaveBeenLastCalledWith({ completed: false, percentage: 20 });
    expect(window.localStorage.getItem("msc.video.resume.enrollment-1.step-1")).toBe("7");
    expect(screen.getByText(/hanya pratinjau perangkat/)).toBeVisible();
    expect(video).toHaveAttribute("controls");
    expect(video.querySelector('track[kind="captions"]')).toHaveAttribute("srcLang", "id");
  });

  it("menyimpan posisi saat offline dan menyediakan retry", async () => {
    const load = vi.spyOn(HTMLMediaElement.prototype, "load").mockImplementation(() => undefined);
    render(
      <ProgramVideoPlayer
        captionsSrc="/captions/step.vtt"
        enrollmentId="enrollment"
        src="/video/step.mp4"
        stepId="step"
        textAlternative="Alternatif teks."
      />,
    );
    const video = document.querySelector("video") as HTMLVideoElement;
    Object.defineProperty(video, "currentTime", { configurable: true, value: 3 });
    fireEvent(window, new Event("offline"));

    expect(screen.getByText(/Koneksi terputus/)).toBeVisible();
    await userEvent.click(screen.getByRole("button", { name: "Coba lagi" }));
    expect(load).toHaveBeenCalledOnce();
  });
});
