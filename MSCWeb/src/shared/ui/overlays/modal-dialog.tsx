"use client";

import { useEffect, useId, useRef, type ReactNode } from "react";

import { IconButton } from "@/shared/ui/controls/actions";

type ModalDialogProperties = Readonly<{
  children: ReactNode;
  description?: string;
  isOpen: boolean;
  onClose: () => void;
  title: string;
  variant?: "dialog" | "sheet";
}>;

const historyMarker = "msc-modal";

export function ModalDialog({
  children,
  description,
  isOpen,
  onClose,
  title,
  variant = "dialog",
}: ModalDialogProperties) {
  const dialogReference = useRef<HTMLDialogElement>(null);
  const returnFocusReference = useRef<HTMLElement | null>(null);
  const titleId = useId();
  const descriptionId = useId();

  useEffect(() => {
    const dialog = dialogReference.current;
    if (!dialog) return;

    if (isOpen) {
      returnFocusReference.current = document.activeElement as HTMLElement | null;
      if (!dialog.open) {
        if (typeof dialog.showModal === "function") dialog.showModal();
        else dialog.setAttribute("open", "");
      }
      if (window.history.state?.modal !== historyMarker) {
        window.history.pushState({ ...window.history.state, modal: historyMarker }, "");
      }
      requestAnimationFrame(() =>
        dialog.querySelector<HTMLElement>("button, input, select, textarea, [tabindex]")?.focus(),
      );
    } else if (dialog.open) {
      if (typeof dialog.close === "function") dialog.close();
      else dialog.removeAttribute("open");
      if (window.history.state?.modal === historyMarker) window.history.back();
      requestAnimationFrame(() => {
        requestAnimationFrame(() => returnFocusReference.current?.focus());
      });
      window.setTimeout(() => returnFocusReference.current?.focus(), 100);
    }
  }, [isOpen]);

  useEffect(() => {
    const handlePopState = () => {
      if (isOpen) onClose();
    };
    window.addEventListener("popstate", handlePopState);
    return () => window.removeEventListener("popstate", handlePopState);
  }, [isOpen, onClose]);

  function closeDialog() {
    if (window.history.state?.modal === historyMarker) window.history.back();
    else onClose();
  }

  return (
    <dialog
      aria-describedby={description ? descriptionId : undefined}
      aria-labelledby={titleId}
      className={`modal-dialog modal-dialog--${variant}`}
      onCancel={(event) => {
        event.preventDefault();
        closeDialog();
      }}
      onClick={(event) => {
        if (event.target === event.currentTarget) closeDialog();
      }}
      ref={dialogReference}
    >
      <div className="modal-dialog__surface">
        <header>
          <div>
            <h2 id={titleId}>{title}</h2>
            {description ? <p id={descriptionId}>{description}</p> : null}
          </div>
          <IconButton icon="close" label="Tutup" onClick={closeDialog} />
        </header>
        <div className="modal-dialog__content">{children}</div>
      </div>
    </dialog>
  );
}

export function ToastLiveRegion({ message }: Readonly<{ message?: string | undefined }>) {
  return (
    <div aria-atomic="true" aria-live="polite" className="toast-live-region">
      {message ? <p>{message}</p> : null}
    </div>
  );
}
