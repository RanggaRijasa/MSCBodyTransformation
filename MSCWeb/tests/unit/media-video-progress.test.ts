import { describe, expect, it } from "vitest";

import {
  hasMetWatchThreshold,
  initialVideoWatchState,
  recordVideoSample,
  watchedPercentage,
} from "@/domain/media/video-progress";

describe("progres video", () => {
  it("menghitung interval tontonan unik", () => {
    let state = recordVideoSample(initialVideoWatchState, 0, 10);
    state = recordVideoSample(state, 3, 10);
    state = recordVideoSample(state, 5, 10);
    expect(watchedPercentage(state, 10)).toBe(50);
    expect(hasMetWatchThreshold(state, 10, 50)).toBe(true);
  });

  it("mengabaikan forged jump dan event mundur", () => {
    let state = recordVideoSample(initialVideoWatchState, 0, 100);
    state = recordVideoSample(state, 80, 100);
    state = recordVideoSample(state, 79, 100);
    expect(watchedPercentage(state, 100)).toBe(0);
  });

  it("tidak menghitung event spam pada interval yang sama dua kali", () => {
    let state = recordVideoSample(initialVideoWatchState, 0, 10);
    state = recordVideoSample(state, 2, 10);
    state = recordVideoSample(state, 1, 10);
    state = recordVideoSample(state, 2, 10);
    expect(watchedPercentage(state, 10)).toBe(20);
  });
});
