import { cleanup, render, waitFor } from "@testing-library/react";
import { afterEach, describe, expect, it, vi } from "vitest";

import { SessionSynchronizer } from "@/features/auth/components/session-synchronizer";

const refresh = vi.fn();
const unsubscribe = vi.fn();
const subscribeToAuthClientEvents = vi.fn(() => unsubscribe);

vi.mock("next/navigation", () => ({
  useRouter: () => ({ refresh }),
}));

vi.mock("@/application/auth/client-auth-events", () => ({
  subscribeToAuthClientEvents: (...arguments_: Parameters<typeof subscribeToAuthClientEvents>) =>
    subscribeToAuthClientEvents(...arguments_),
}));

describe("SessionSynchronizer", () => {
  afterEach(() => {
    cleanup();
    refresh.mockReset();
    subscribeToAuthClientEvents.mockClear();
    unsubscribe.mockClear();
  });

  it("tidak membuka subscription yang selesai dimuat setelah komponen dilepas", async () => {
    const view = render(<SessionSynchronizer />);
    view.unmount();

    await Promise.resolve();
    await Promise.resolve();
    expect(subscribeToAuthClientEvents).not.toHaveBeenCalled();
  });

  it("memuat listener auth setelah hydration dan membersihkannya saat unmount", async () => {
    const view = render(<SessionSynchronizer />);

    await waitFor(() => expect(subscribeToAuthClientEvents).toHaveBeenCalledOnce());
    view.unmount();
    expect(unsubscribe).toHaveBeenCalledOnce();
  });
});
