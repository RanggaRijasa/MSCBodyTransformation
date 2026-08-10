const defaultUpstreamTimeoutMilliseconds = 15_000;

export async function fetchWithTimeout(
  input: URL | string,
  init: RequestInit = {},
  timeoutMilliseconds = defaultUpstreamTimeoutMilliseconds,
): Promise<Response> {
  if (
    !Number.isSafeInteger(timeoutMilliseconds) ||
    timeoutMilliseconds < 1
  ) {
    throw new Error("server_configuration_invalid");
  }
  return await fetch(input, {
    ...init,
    signal: init.signal ?? AbortSignal.timeout(timeoutMilliseconds),
  });
}

export async function readLimitedText(
  request: Request,
  maximumBytes: number,
): Promise<string> {
  if (!Number.isSafeInteger(maximumBytes) || maximumBytes < 1) {
    throw new Error("server_configuration_invalid");
  }

  const declaredLength = request.headers.get("Content-Length");
  if (declaredLength !== null) {
    if (!/^\d+$/.test(declaredLength)) {
      throw new Error("request_invalid");
    }
    const bytes = Number(declaredLength);
    if (!Number.isSafeInteger(bytes) || bytes > maximumBytes) {
      throw new Error("request_invalid");
    }
  }

  if (!request.body) return "";

  const reader = request.body.getReader();
  const chunks: Uint8Array[] = [];
  let totalBytes = 0;
  while (true) {
    const { done, value } = await reader.read();
    if (done) break;
    totalBytes += value.byteLength;
    if (totalBytes > maximumBytes) {
      void reader.cancel("request_invalid").catch(() => undefined);
      throw new Error("request_invalid");
    }
    chunks.push(value);
  }

  const body = new Uint8Array(totalBytes);
  let offset = 0;
  for (const chunk of chunks) {
    body.set(chunk, offset);
    offset += chunk.byteLength;
  }
  try {
    return new TextDecoder("utf-8", { fatal: true }).decode(body);
  } catch {
    throw new Error("request_invalid");
  }
}

export async function readLimitedJSON(
  request: Request,
  maximumBytes: number,
): Promise<unknown> {
  const rawBody = await readLimitedText(request, maximumBytes);
  if (!rawBody) throw new Error("request_invalid");
  try {
    return JSON.parse(rawBody) as unknown;
  } catch {
    throw new Error("request_invalid");
  }
}
