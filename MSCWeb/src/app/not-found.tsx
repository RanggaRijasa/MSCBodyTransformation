import Link from "next/link";

import { copy } from "@/shared/i18n/id";

export default function NotFoundPage() {
  return (
    <main className="state-page">
      <h1>{copy.notFound.title}</h1>
      <p>{copy.notFound.message}</p>
      <Link className="primary-button" href="/">
        {copy.notFound.action}
      </Link>
    </main>
  );
}
