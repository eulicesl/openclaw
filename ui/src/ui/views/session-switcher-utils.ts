import {
  isCronSessionKey,
  resolveSessionDisplayName,
  CHANNEL_LABELS,
} from "../app-render.helpers.ts";
import type { GatewaySessionRow, SessionsListResult } from "../types.ts";

/* ── Session grouping ─────────────────────────────────── */

export type SessionGroup = {
  id: string;
  label: string;
  sessions: Array<{ key: string; row?: GatewaySessionRow; displayName: string }>;
};

/**
 * Categorise sessions into groups: Main, Channels, Cron Jobs, Subagents, Other.
 */
export function groupSessions(
  sessions: SessionsListResult | null,
  mainSessionKey: string | null,
  labels: Record<string, string>,
): SessionGroup[] {
  if (!sessions?.sessions?.length) {
    return [];
  }

  const main: SessionGroup = { id: "main", label: labels.main ?? "Main", sessions: [] };
  const channels: SessionGroup = {
    id: "channels",
    label: labels.channels ?? "Channels",
    sessions: [],
  };
  const cron: SessionGroup = { id: "cron", label: labels.cron ?? "Cron Jobs", sessions: [] };
  const subagent: SessionGroup = {
    id: "subagent",
    label: labels.subagent ?? "Subagents",
    sessions: [],
  };
  const other: SessionGroup = { id: "other", label: labels.other ?? "Other", sessions: [] };

  for (const row of sessions.sessions) {
    const entry = {
      key: row.key,
      row,
      displayName: resolveSessionDisplayName(row.key, row),
    };

    if (row.key === "main" || row.key === mainSessionKey) {
      main.sessions.push(entry);
    } else if (row.key.includes(":subagent:")) {
      subagent.sessions.push(entry);
    } else if (isCronSessionKey(row.key)) {
      cron.sessions.push(entry);
    } else if (isChannelSession(row.key)) {
      channels.sessions.push(entry);
    } else {
      other.sessions.push(entry);
    }
  }

  return [main, channels, cron, subagent, other].filter((g) => g.sessions.length > 0);
}

export function isChannelSession(key: string): boolean {
  const knownChannels = Object.keys(CHANNEL_LABELS);
  for (const ch of knownChannels) {
    if (key === ch || key.startsWith(`${ch}:`)) {
      return true;
    }
  }
  if (key.match(/^agent:[^:]+:[^:]+:(direct|group):/)) {
    return true;
  }
  return false;
}

/**
 * Filter sessions by search query (case-insensitive substring match on
 * display name and key).
 */
export function filterSessions(groups: SessionGroup[], query: string): SessionGroup[] {
  if (!query.trim()) {
    return groups;
  }
  const q = query.toLowerCase();
  return groups
    .map((group) => ({
      ...group,
      sessions: group.sessions.filter(
        (s) => s.displayName.toLowerCase().includes(q) || s.key.toLowerCase().includes(q),
      ),
    }))
    .filter((g) => g.sessions.length > 0);
}
