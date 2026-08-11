"use client";

import { useState } from "react";

import { copy } from "@/shared/i18n/id";

export function FoundationStatus() {
  const [isDetailVisible, setIsDetailVisible] = useState(false);

  return (
    <div className="foundation-card">
      <h2>{copy.foundation.statusTitle}</h2>
      <p aria-live="polite">
        {isDetailVisible ? copy.foundation.statusDetail : copy.foundation.statusReady}
      </p>
      <button
        className="primary-button"
        type="button"
        aria-expanded={isDetailVisible}
        onClick={() => setIsDetailVisible((currentValue) => !currentValue)}
      >
        {isDetailVisible ? copy.foundation.hideDetail : copy.foundation.showDetail}
      </button>
    </div>
  );
}
