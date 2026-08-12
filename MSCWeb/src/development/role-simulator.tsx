import { useEffect, useState, type FormEvent } from "react";
import { usePathname } from "next/navigation";

import { AppShell } from "@/features/app-shell/components/app-shell";
import {
  AdminSimulatorScreen,
  CoachSimulatorScreen,
  ParticipantSimulatorScreen,
  type SimulatorRole,
} from "@/development/role-simulator-screens";
import { AppButton, AppIcon, type AppIconName } from "@/shared/ui";

const roleStorageKey = "msc.development.simulator-role";
const roleChoices: readonly Readonly<{
  description: string;
  icon: AppIconName;
  label: string;
  role: SimulatorRole;
  startPath: string;
}>[] = [
  {
    description: "Jelajahi area publik tanpa data pribadi.",
    icon: "home",
    label: "Guest",
    role: "guest",
    startPath: "/hari-ini",
  },
  {
    description: "Ikuti program, aktivitas, peringkat, dan profil.",
    icon: "person",
    label: "Peserta",
    role: "participant",
    startPath: "/hari-ini",
  },
  {
    description: "Pantau Peserta dan periksa aktivitas.",
    icon: "coach",
    label: "Coach",
    role: "coach",
    startPath: "/coach-area",
  },
  {
    description: "Kelola program, orang, konten, dan pembayaran.",
    icon: "dashboard",
    label: "Admin",
    role: "admin",
    startPath: "/admin",
  },
];

function navigate(path: string) {
  window.history.pushState({}, "", path);
  window.dispatchEvent(new Event("msc:navigation"));
  window.scrollTo({ top: 0 });
}

function inferredRole(pathname: string): SimulatorRole {
  if (pathname.startsWith("/admin")) return "admin";
  if (pathname.startsWith("/coach-area")) return "coach";
  return "guest";
}

export function RoleSimulator() {
  const pathname = usePathname();
  const [role, setRole] = useState<SimulatorRole>(() => {
    const stored = window.localStorage.getItem(roleStorageKey);
    return stored === "guest" ||
      stored === "participant" ||
      stored === "coach" ||
      stored === "admin"
      ? stored
      : inferredRole(window.location.pathname);
  });
  const [notice, setNotice] = useState("");

  useEffect(() => {
    document.documentElement.dataset.role = role;
    return () => {
      delete document.documentElement.dataset.role;
    };
  }, [role]);

  const selectRole = (nextRole: SimulatorRole, startPath: string) => {
    window.localStorage.setItem(roleStorageKey, nextRole);
    setRole(nextRole);
    setNotice(
      `Mode ${nextRole === "participant" ? "Peserta" : nextRole === "guest" ? "Guest" : nextRole === "coach" ? "Coach" : "Admin"} aktif.`,
    );
    navigate(startPath);
  };

  const preventServerMutation = (event: FormEvent) => {
    event.preventDefault();
    setNotice("Aksi server ditahan. Simulator hanya mengubah state lokal development.");
  };

  if (pathname === "/") {
    return <RoleChooser onSelect={selectRole} />;
  }

  const isAuthPath =
    pathname === "/masuk" ||
    pathname === "/daftar" ||
    pathname === "/lupa-password" ||
    (role === "guest" && pathname === "/profil");
  return (
    <div className="role-simulator" onSubmitCapture={preventServerMutation}>
      <SimulatorToolbar currentRole={role} notice={notice} onChoose={() => navigate("/")} />
      {isAuthPath ? (
        <DevelopmentAuth onSelect={selectRole} pathname={pathname} />
      ) : pathname.startsWith("/admin") ? (
        <AppShell kind="admin" label="Admin">
          <AdminSimulatorScreen pathname={pathname} />
        </AppShell>
      ) : pathname.startsWith("/coach-area") ? (
        <AppShell kind="coach" label="Coach">
          <CoachSimulatorScreen pathname={pathname} />
        </AppShell>
      ) : (
        <AppShell kind="participant" label={role === "guest" ? "Guest" : "Peserta"}>
          <ParticipantSimulatorScreen pathname={pathname} role={role} />
        </AppShell>
      )}
    </div>
  );
}

function RoleChooser({
  onSelect,
}: Readonly<{ onSelect: (role: SimulatorRole, startPath: string) => void }>) {
  return (
    <main className="role-chooser">
      <header className="role-chooser__header">
        <div className="role-chooser__mark" aria-hidden="true">
          MSC
        </div>
        <p>Mode development lokal</p>
        <h1>Pilih perjalanan aplikasi</h1>
        <span>
          Masuk ke halaman asli setiap role dengan data aman yang tidak dikirim ke server.
        </span>
      </header>
      <div className="role-chooser__grid">
        {roleChoices.map((choice) => (
          <button
            className={`role-choice role-choice--${choice.role}`}
            key={choice.role}
            onClick={() => onSelect(choice.role, choice.startPath)}
            type="button"
          >
            <span className="role-choice__icon">
              <AppIcon name={choice.icon} variant="outline" />
            </span>
            <span>
              <strong>{choice.label}</strong>
              <small>{choice.description}</small>
            </span>
            <AppIcon className="role-choice__chevron" name="chevron" />
          </button>
        ))}
      </div>
      <footer>
        <strong>Aman untuk development</strong>
        <span>Tidak mengubah database, role production, pembayaran, atau media privat.</span>
      </footer>
    </main>
  );
}

function SimulatorToolbar({
  currentRole,
  notice,
  onChoose,
}: Readonly<{ currentRole: SimulatorRole; notice: string; onChoose: () => void }>) {
  const label =
    currentRole === "participant"
      ? "Peserta"
      : currentRole === "guest"
        ? "Guest"
        : currentRole === "coach"
          ? "Coach"
          : "Admin";
  return (
    <div className="role-simulator-toolbar">
      <div>
        <span aria-hidden="true" className="role-simulator-toolbar__dot" />
        <strong>Simulator {label}</strong>
        <small>Data lokal</small>
      </div>
      {notice ? (
        <span className="role-simulator-toolbar__notice" role="status">
          {notice}
        </span>
      ) : null}
      <AppButton onClick={onChoose} variant="secondary">
        Ganti role
      </AppButton>
    </div>
  );
}

function DevelopmentAuth({
  onSelect,
  pathname,
}: Readonly<{ onSelect: (role: SimulatorRole, path: string) => void; pathname: string }>) {
  const isRegister = pathname === "/daftar";
  const isForgot = pathname === "/lupa-password";
  return (
    <main className="role-simulator-auth">
      <button
        className="role-simulator-auth__back"
        onClick={() => window.history.back()}
        type="button"
      >
        Tutup
      </button>
      <div className="role-simulator-auth__card">
        <AppIcon name="person" />
        <h1>
          {isForgot ? "Bantuan masuk" : isRegister ? "Buat akun Peserta" : "Selamat datang kembali"}
        </h1>
        <p>
          {isForgot
            ? "Pada simulator, pilih role untuk melanjutkan tanpa mengirim email."
            : "Pilih identitas development untuk membuka perjalanan aplikasi."}
        </p>
        <div className="role-simulator-auth__actions">
          <AppButton onClick={() => onSelect("participant", "/hari-ini")}>
            Masuk sebagai Peserta
          </AppButton>
          <AppButton onClick={() => onSelect("coach", "/coach-area")} variant="secondary">
            Masuk sebagai Coach
          </AppButton>
          <AppButton onClick={() => onSelect("admin", "/admin")} variant="secondary">
            Masuk sebagai Admin
          </AppButton>
        </div>
      </div>
    </main>
  );
}
