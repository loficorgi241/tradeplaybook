"use client";

import Papa from "papaparse";
import { useState } from "react";
import { supabase } from "@/lib/supabase/client";

type CsvRow = {
  trade_id?: string;
  open_date: string;
  close_date?: string;
  symbol: string;
  side: "LONG_CALL" | "LONG_PUT";
  expiry: string;
  strike: string;
  contracts: string;
  entry_price: string;
  exit_price?: string;
  fees?: string;
  thesis?: string;
  setup_tag?: string;
  outcome_tag?: string;
  notes?: string;
};

export default function ImportTradesPage() {
  const [status, setStatus] = useState<string>("");

  async function onFile(file: File) {
    setStatus("Parsing CSV...");

    const text = await file.text();
    const parsed = Papa.parse<CsvRow>(text, {
      header: true,
      skipEmptyLines: true,
    });

    if (parsed.errors?.length) {
      setStatus(`CSV parse error: ${parsed.errors[0].message}`);
      return;
    }

    const rows = (parsed.data || []).filter(
      (r) => r.open_date && r.symbol && r.side
    );

    setStatus(`Parsed ${rows.length} rows. Checking auth...`);
    const { data: auth } = await supabase.auth.getUser();
    if (!auth.user) {
      setStatus("You must be logged in first.");
      return;
    }

    setStatus("Uploading to Supabase...");
    const payload = rows.map((r) => ({
      user_id: auth.user!.id,
      open_date: r.open_date,
      close_date: r.close_date || null,
      symbol: r.symbol.trim().toUpperCase(),
      side: r.side,
      expiry: r.expiry,
      strike: Number(r.strike),
      contracts: Number(r.contracts),
      entry_price: Number(r.entry_price),
      exit_price: r.exit_price ? Number(r.exit_price) : null,
      fees: r.fees ? Number(r.fees) : 0,
      thesis: r.thesis || null,
      setup_tag: r.setup_tag || null,
      outcome_tag: r.outcome_tag || null,
      notes: r.notes || null,
    }));

    const { error } = await supabase.from("trades").insert(payload);
    if (error) {
      setStatus(`Insert failed: ${error.message}`);
      return;
    }

    setStatus(`Done. Imported ${payload.length} trades.`);
  }

  return (
    <div className="mx-auto max-w-2xl p-6">
      <h1 className="text-2xl font-bold">Import Trades (CSV)</h1>
      <p className="mt-2 text-sm text-gray-600">
        Upload a CSV using the TradePlaybook schema.
      </p>

      <div className="mt-6">
        <input
          type="file"
          accept=".csv,text/csv"
          onChange={(e) => {
            const f = e.target.files?.[0];
            if (f) void onFile(f);
          }}
        />
      </div>

      <pre className="mt-6 whitespace-pre-wrap rounded bg-black p-3 text-xs text-green-400">
        {status}
      </pre>
    </div>
  );
}
