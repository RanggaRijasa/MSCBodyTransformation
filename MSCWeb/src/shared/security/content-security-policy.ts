type CspInput = Readonly<{
  isDevelopment: boolean;
  nonce: string;
  requestOrigin: string;
  supabaseUrl?: string | undefined;
}>;

function providerSources(value?: string) {
  if (!value) return [];
  try {
    const url = new URL(value);
    const websocket = new URL(value);
    websocket.protocol = url.protocol === "https:" ? "wss:" : "ws:";
    return [url.origin, websocket.origin];
  } catch {
    return [];
  }
}

export function buildContentSecurityPolicy(input: CspInput) {
  const provider = providerSources(input.supabaseUrl);
  const directives = [
    "default-src 'self'",
    `script-src 'self' 'nonce-${input.nonce}' 'strict-dynamic'${input.isDevelopment ? " 'unsafe-eval'" : ""}`,
    "style-src 'self' 'unsafe-inline'",
    `connect-src 'self' ${input.requestOrigin} ${provider.join(" ")}`.trim(),
    `img-src 'self' blob: data: ${provider.filter((source) => !source.startsWith("ws")).join(" ")}`.trim(),
    `media-src 'self' blob: ${provider.filter((source) => !source.startsWith("ws")).join(" ")}`.trim(),
    "font-src 'self' data:",
    "worker-src 'self' blob:",
    "manifest-src 'self'",
    "object-src 'none'",
    "base-uri 'self'",
    "form-action 'self'",
    "frame-src 'none'",
    "frame-ancestors 'none'",
  ];
  if (!input.isDevelopment && input.requestOrigin.startsWith("https://"))
    directives.push("upgrade-insecure-requests");
  return directives.join("; ");
}
