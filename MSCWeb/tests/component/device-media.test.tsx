import { act, fireEvent, render, screen, waitFor } from "@testing-library/react";
import userEvent from "@testing-library/user-event";
import { describe, expect, it, vi } from "vitest";

import { QrScannerDialog } from "@/features/device-media";
import type { QrDecoder } from "@/infrastructure/qr/browser-qr-decoder";

function decoder(overrides: Partial<QrDecoder> = {}): QrDecoder {
  return {
    createSession: async () => ({ destroy: vi.fn(), start: async () => undefined, stop: vi.fn() }),
    hasCamera: async () => true,
    scanImage: async () => `${window.location.origin}/gabung/coach/coach-test-1234`,
    ...overrides,
  };
}

describe("device media", () => {
  it("memulai kamera hanya ketika dialog dibuka dan menerima QR canonical", async () => {
    let emitScan: ((value: string) => void) | undefined;
    const onScan = vi.fn();
    const createSession = vi.fn(
      async (_video: HTMLVideoElement, callback: (value: string) => void) => {
        emitScan = callback;
        return { destroy: vi.fn(), start: async () => undefined, stop: vi.fn() };
      },
    );
    const qrDecoder = decoder({ createSession });
    const { rerender } = render(
      <QrScannerDialog decoder={qrDecoder} isOpen={false} onClose={vi.fn()} onScan={onScan} />,
    );
    expect(createSession).not.toHaveBeenCalled();
    rerender(<QrScannerDialog decoder={qrDecoder} isOpen onClose={vi.fn()} onScan={onScan} />);
    await waitFor(() => expect(createSession).toHaveBeenCalledOnce());
    act(() => emitScan?.(`${window.location.origin}/gabung/coach/coach-test-1234`));
    expect(onScan).toHaveBeenCalledWith("coach-test-1234");
  });

  it("menjelaskan permission denied dan tetap menawarkan scan gambar", async () => {
    const qrDecoder = decoder({
      createSession: async () => ({
        destroy: vi.fn(),
        start: async () => Promise.reject(new DOMException("Denied", "NotAllowedError")),
        stop: vi.fn(),
      }),
    });
    render(<QrScannerDialog decoder={qrDecoder} isOpen onClose={vi.fn()} onScan={vi.fn()} />);
    expect(await screen.findByText(/Akses kamera ditolak/)).toBeVisible();
    expect(screen.getByText("Pilih gambar QR")).toBeVisible();
    expect(screen.queryByRole("textbox", { name: /kode/i })).not.toBeInTheDocument();
  });

  it("mendekode file QR tanpa menyediakan input kode manual", async () => {
    const user = userEvent.setup();
    const onScan = vi.fn();
    render(
      <QrScannerDialog
        decoder={decoder({ hasCamera: async () => false })}
        isOpen
        onClose={vi.fn()}
        onScan={onScan}
      />,
    );
    const input =
      screen.getByLabelText("Pilih gambar QR").querySelector("input") ??
      document.querySelector<HTMLInputElement>(".qr-scanner__file-action input");
    expect(input).not.toBeNull();
    await user.upload(input as HTMLInputElement, new File(["qr"], "qr.png", { type: "image/png" }));
    await waitFor(() => expect(onScan).toHaveBeenCalledWith("coach-test-1234"));
  });

  it("menolak hasil scan dari origin lain", async () => {
    const onScan = vi.fn();
    let emitScan: ((value: string) => void) | undefined;
    render(
      <QrScannerDialog
        decoder={decoder({
          createSession: async (_video, callback) => {
            emitScan = callback;
            return { destroy: vi.fn(), start: async () => undefined, stop: vi.fn() };
          },
        })}
        isOpen
        onClose={vi.fn()}
        onScan={onScan}
      />,
    );
    await waitFor(() => expect(emitScan).toBeDefined());
    fireEvent.click(screen.getByRole("button", { name: "Tutup pemindai" }));
    act(() => emitScan?.("https://evil.example/gabung/coach/stolen-token"));
    expect(onScan).not.toHaveBeenCalled();
    expect(screen.getByRole("alert")).toHaveTextContent("bukan QR Coach MSC");
  });
});
