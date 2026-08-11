"use client";

import {
  createContext,
  useCallback,
  useContext,
  useEffect,
  useMemo,
  useReducer,
  useRef,
  useState,
  type ReactNode,
} from "react";

import {
  initialInstallState,
  transitionInstallState,
  type InstallState,
} from "@/features/pwa-install/model/install-state";
import { copy } from "@/shared/i18n/id";
import { ModalDialog, ToastLiveRegion } from "@/shared/ui";

type InstallChoice = Readonly<{ outcome: "accepted" | "dismissed"; platform: string }>;

export interface BeforeInstallPromptEvent extends Event {
  prompt(): Promise<void>;
  readonly userChoice: Promise<InstallChoice>;
}

type NavigatorWithStandalone = Navigator & Readonly<{ standalone?: boolean }>;

type PwaInstallContextValue = Readonly<{
  actorDestination: string;
  isInstructionOpen: boolean;
  openInstruction: (trigger?: HTMLElement) => void;
  requestInstall: () => Promise<void>;
  state: InstallState;
}>;

const PwaInstallContext = createContext<PwaInstallContextValue | undefined>(undefined);

function detectIOS(): boolean {
  const navigatorWithTouch = navigator as Navigator & Readonly<{ maxTouchPoints?: number }>;
  const platform = navigator.platform.toLowerCase();
  const userAgent = navigator.userAgent.toLowerCase();
  return (
    /iphone|ipad|ipod/.test(userAgent) ||
    (platform === "macintel" && (navigatorWithTouch.maxTouchPoints ?? 0) > 1)
  );
}

function detectStandalone(): boolean {
  return (
    window.matchMedia("(display-mode: standalone)").matches ||
    Boolean((navigator as NavigatorWithStandalone).standalone)
  );
}

type PwaInstallProviderProperties = Readonly<{
  actorDestination: string;
  children: ReactNode;
}>;

export function PwaInstallProvider({ actorDestination, children }: PwaInstallProviderProperties) {
  const [state, dispatch] = useReducer(transitionInstallState, initialInstallState);
  const [isInstructionOpen, setInstructionOpen] = useState(false);
  const [announcement, setAnnouncement] = useState<string>();
  const promptReference = useRef<BeforeInstallPromptEvent | undefined>(undefined);
  const instructionTriggerReference = useRef<HTMLElement | undefined>(undefined);

  useEffect(() => {
    document.documentElement.dataset.pwaInstallController = "ready";
    const displayMode = window.matchMedia("(display-mode: standalone)");
    const detectCapability = () =>
      dispatch({
        type: "capability-detected",
        capability: {
          hasCustomPrompt: Boolean(promptReference.current),
          isIOS: detectIOS(),
          isInstallReadinessGateOpen: document.documentElement.dataset.pwaServiceWorker === "ready",
          isStandalone: detectStandalone(),
          supportsManualInstall: "serviceWorker" in navigator,
        },
      });
    detectCapability();

    const handleBeforeInstallPrompt = (event: Event) => {
      event.preventDefault();
      promptReference.current = event as BeforeInstallPromptEvent;
      dispatch({ type: "custom-prompt-available" });
    };
    const handleInstalled = () => {
      promptReference.current = undefined;
      dispatch({ type: "standalone-detected" });
    };
    const handleDisplayMode = () => {
      if (detectStandalone()) dispatch({ type: "standalone-detected" });
    };
    const handlePwaReady = () => detectCapability();

    window.addEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
    window.addEventListener("appinstalled", handleInstalled);
    displayMode.addEventListener("change", handleDisplayMode);
    window.addEventListener("msc:pwa-ready", handlePwaReady);
    return () => {
      delete document.documentElement.dataset.pwaInstallController;
      window.removeEventListener("beforeinstallprompt", handleBeforeInstallPrompt);
      window.removeEventListener("appinstalled", handleInstalled);
      displayMode.removeEventListener("change", handleDisplayMode);
      window.removeEventListener("msc:pwa-ready", handlePwaReady);
    };
  }, []);

  const requestInstall = useCallback(async () => {
    const prompt = promptReference.current;
    if (!prompt) return;
    promptReference.current = undefined;
    await prompt.prompt();
    const choice = await prompt.userChoice;
    dispatch({ outcome: choice.outcome, type: "prompt-consumed" });
    setAnnouncement(copy.landing.install.consumed);
  }, []);

  const openInstruction = useCallback((trigger?: HTMLElement) => {
    instructionTriggerReference.current = trigger;
    setInstructionOpen(true);
  }, []);
  const closeInstruction = useCallback(() => {
    setInstructionOpen(false);
    window.setTimeout(() => instructionTriggerReference.current?.focus(), 150);
  }, []);
  const contextValue = useMemo<PwaInstallContextValue>(
    () => ({ actorDestination, isInstructionOpen, openInstruction, requestInstall, state }),
    [actorDestination, isInstructionOpen, openInstruction, requestInstall, state],
  );

  return (
    <PwaInstallContext.Provider value={contextValue}>
      {children}
      <ModalDialog
        description={
          state.kind === "ios-guidance"
            ? copy.landing.install.iosSteps
            : copy.landing.install.manualSteps
        }
        isOpen={isInstructionOpen}
        onClose={closeInstruction}
        title={copy.landing.install.sheetTitle}
        variant="sheet"
      >
        <p>
          {state.kind === "ios-guidance"
            ? copy.landing.install.iosSteps
            : copy.landing.install.manualSteps}
        </p>
      </ModalDialog>
      <ToastLiveRegion message={announcement} />
    </PwaInstallContext.Provider>
  );
}

export function usePwaInstall(): PwaInstallContextValue {
  const context = useContext(PwaInstallContext);
  if (!context) throw new Error("Install CTA harus berada di dalam PwaInstallProvider.");
  return context;
}
