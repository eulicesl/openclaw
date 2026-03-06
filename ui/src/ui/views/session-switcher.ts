import { html, nothing } from "lit";
import { t } from "../../i18n/index.ts";
import { parseSessionKey, resolveMainSessionKey, CHANNEL_LABELS } from "../app-render.helpers.ts";
import type { AppViewState } from "../app-view-state.ts";
import { formatRelativeTimestamp } from "../format.ts";
import { groupSessions, filterSessions } from "./session-switcher-utils.ts";

export type { SessionGroup } from "./session-switcher-utils.ts";
export { groupSessions, filterSessions } from "./session-switcher-utils.ts";

/* ── Channel badge extraction ─────────────────────────── */

function resolveChannelBadge(key: string): string | null {
  const { fallbackName } = parseSessionKey(key);
  for (const [, label] of Object.entries(CHANNEL_LABELS)) {
    if (fallbackName.startsWith(label)) {
      return label;
    }
  }
  return null;
}

/* ── Render ───────────────────────────────────────────── */

export type SessionSwitcherProps = {
  state: AppViewState;
  expandedGroups: Record<string, boolean>;
  searchQuery: string;
  onSelectSession: (key: string) => void;
  onSearchChange: (query: string) => void;
  onToggleGroup: (groupId: string) => void;
  onTogglePanel: () => void;
};

export function renderSessionSwitcher(props: SessionSwitcherProps) {
  const { state, expandedGroups, searchQuery } = props;

  const mainSessionKey = resolveMainSessionKey(state.hello, state.sessionsResult);
  const labels = {
    main: t("sessionSwitcher.groupMain"),
    channels: t("sessionSwitcher.groupChannels"),
    cron: t("sessionSwitcher.groupCron"),
    subagent: t("sessionSwitcher.groupSubagent"),
    other: t("sessionSwitcher.groupOther"),
  };
  const groups = groupSessions(state.sessionsResult, mainSessionKey, labels);
  const filtered = filterSessions(groups, searchQuery);

  if (!state.sessionsResult?.sessions?.length) {
    return nothing;
  }

  const panelOpen = state.settings.sessionSwitcherOpen;

  return html`
    <div class="session-switcher ${panelOpen ? "" : "session-switcher--collapsed"}">
      <div class="session-switcher__header">
        <span class="session-switcher__title">${t("sessionSwitcher.title")}</span>
        <button
          class="session-switcher__toggle"
          @click=${props.onTogglePanel}
          title=${t("sessionSwitcher.toggle")}
          aria-label=${t("sessionSwitcher.toggle")}
        >
          <svg width="14" height="14" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="6 9 12 15 18 9"></polyline>
          </svg>
        </button>
      </div>
      <div class="session-switcher__search">
        <input
          type="text"
          placeholder=${t("sessionSwitcher.search")}
          .value=${searchQuery}
          @input=${(e: InputEvent) => props.onSearchChange((e.target as HTMLInputElement).value)}
        />
      </div>
      <div class="session-switcher__list">
        ${filtered.map((group) => {
          const collapsed = !expandedGroups[group.id];
          return html`
            <div class="session-switcher__group">
              <button
                class="session-switcher__group-label ${collapsed ? "session-switcher__group-label--collapsed" : ""}"
                @click=${() => props.onToggleGroup(group.id)}
                aria-expanded=${!collapsed}
              >
                <span>${group.label}</span>
                <span class="session-switcher__group-chevron">${collapsed ? "+" : "−"}</span>
              </button>
              ${
                collapsed
                  ? nothing
                  : html`
                    <div class="session-switcher__group-items">
                      ${group.sessions.map((entry) => {
                        const active = entry.key === state.sessionKey;
                        const channelBadge = resolveChannelBadge(entry.key);
                        const updatedAt = entry.row?.updatedAt;
                        return html`
                          <button
                            class="session-switcher__item ${active ? "session-switcher__item--active" : ""}"
                            @click=${() => props.onSelectSession(entry.key)}
                            title=${entry.key}
                          >
                            <span class="session-switcher__item-name">${entry.displayName}</span>
                            <span class="session-switcher__item-meta">
                              ${
                                channelBadge
                                  ? html`<span class="session-switcher__badge">${channelBadge}</span>`
                                  : nothing
                              }
                              ${
                                updatedAt
                                  ? html`<span>${formatRelativeTimestamp(updatedAt)}</span>`
                                  : nothing
                              }
                            </span>
                          </button>
                        `;
                      })}
                    </div>
                  `
              }
            </div>
          `;
        })}
      </div>
    </div>
  `;
}
