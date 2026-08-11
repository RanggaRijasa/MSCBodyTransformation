"use client";

import { useEffect, useState } from "react";

export function ProgramNetworkStatus() {
  const [isOffline, setOffline] = useState(false);
  useEffect(() => {
    const update = () => setOffline(!navigator.onLine);
    update();
    window.addEventListener("online", update);
    window.addEventListener("offline", update);
    return () => {
      window.removeEventListener("online", update);
      window.removeEventListener("offline", update);
    };
  }, []);
  return isOffline ? (
    <p className="program-network-status" role="status">
      Kamu sedang offline. Informasi program mungkin belum terbaru dan pendaftaran tidak dapat
      diproses.
    </p>
  ) : null;
}
