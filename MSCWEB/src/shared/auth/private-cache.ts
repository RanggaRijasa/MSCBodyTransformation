import type { QueryClient } from '@tanstack/react-query';

const privateObjectUrls = new Set<string>();
const privateSignedUrls = new Set<string>();

export function registerPrivateObjectUrl(url: string): () => void {
  privateObjectUrls.add(url);
  return () => privateObjectUrls.delete(url);
}

export function registerPrivateSignedUrl(url: string): void {
  privateSignedUrls.add(url);
}

export function purgePrivateCaches(queryClient: QueryClient): void {
  queryClient.removeQueries({
    predicate: (query) => query.queryKey[0] === 'private',
  });
  for (const url of privateObjectUrls) {
    if (url.startsWith('blob:')) URL.revokeObjectURL(url);
  }
  privateObjectUrls.clear();
  privateSignedUrls.clear();
}

export function privateObjectUrlCountForTests(): number {
  return privateObjectUrls.size;
}

export function privateSignedUrlCountForTests(): number {
  return privateSignedUrls.size;
}
