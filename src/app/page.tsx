import Link from "next/link";

export default function Home() {
  return (
    <div className="mx-auto max-w-2xl p-6">
      <h1 className="text-3xl font-bold">TradePlaybook</h1>
      <p className="mt-2 text-gray-600">
        Options journaling MVP (CSV import → Supabase).
      </p>

      <div className="mt-6 flex gap-3">
        <Link className="underline" href="/trades/import">
          Import trades
        </Link>
      </div>

      <p className="mt-8 text-sm text-gray-500">
        Note: You must be logged in for import to work.
      </p>
    </div>
  );
}
