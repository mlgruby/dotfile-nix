// Bottom status bar for the Herdr app: Herdr's own facts on the left,
// the tmux status-right segments on the right. The segments come from the
// same script tmux runs (~/.config/tmux/status/status-right.sh), so both
// bars show the same data. The script prints tmux style markup
// (#[fg=..,bg=..]text); parse() turns it into coloured runs.
import { View, div, svg } from "gpui-kit";
import { h_flex } from "gpui-base";
import { agents, theme, exec, home, checking, props, setBadge } from "herdr";

const SEPARATOR = "\u{e0b2}"; // powerline left-pointing solid arrow
const REFRESH_MS = 10000; // same as tmux status-interval
const FONT = "JetBrainsMono NFM"; // Nerd Font glyphs used by the script
// The status-left.sh segments that belong in this bar: the next meeting
// and PRs waiting on your review. The session name and the herdr TUI count
// are left out (the app shows its own agents on the left).
const LEFT_EXTRAS = `
d="$HOME/.config/tmux/status"
source "$d/lib.sh"; source "$d/calendar.sh"; source "$d/reviews.sh"
tmux_status_collect_calendar; tmux_status_collect_reviews
status_output=""; status_prev_bg="#1d2021"
append_segment "$calendar_bg" "$calendar_fg" "$calendar_status"
append_segment "$reviews_bg" "$reviews_fg" "$reviews_status"
printf '%s' "$status_output"
`;
// tmux bar background in status-right.sh; drawn as the app bar colour instead.
const TMUX_BAR_BG = "#1d2021";
// The AWS profile that aws.sh shows (for Copy on click).
const AWS_PROFILE = `
d="$HOME/.config/tmux/status"
source "$d/lib.sh"; source "$d/aws.sh"; tmux_status_collect_aws
printf '%s' "$aws_profile"
`;
// Clickable segments, found by their text: what a click does and its tooltip.
const ACTIONS = [
  { test: /\breviews?\b/, tip: "Open PRs waiting on your review", run: () => exec("open", ["https://github.com/pulls/review-requested"]) },
  { test: /NOW:|in \d+m:/, tip: "Open Calendar", run: () => exec("open", ["-a", "Calendar"]) },
  {
    test: /\u{f0e0f}/u, tip: "Copy the AWS profile name",
    run: async (cx) => {
      const r = await exec("bash", ["-c", AWS_PROFILE], { timeout: 5000 });
      if (r.code === 0 && r.stdout) cx.write_to_clipboard(r.stdout);
    },
  },
];

// Split tmux markup into runs of { fg, bg, text }.
export function parse(markup) {
  const runs = [];
  let fg = null;
  let bg = null;
  const re = /#\[([^\]]*)\]|([^#]+|#(?!\[))/g;
  for (const m of markup.matchAll(re)) {
    if (m[1] !== undefined) {
      for (const attr of m[1].split(",")) {
        const [k, v] = attr.split("=");
        if (k === "fg") fg = v === "default" ? null : v;
        else if (k === "bg") bg = v === "default" ? null : v;
        else if (k === "default") { fg = null; bg = null; }
      }
    } else if (m[2]) {
      const last = runs[runs.length - 1];
      if (last && last.fg === fg && last.bg === bg && m[2] !== SEPARATOR && last.text !== SEPARATOR) last.text += m[2];
      else runs.push({ fg, bg, text: m[2] });
    }
  }
  return runs;
}

export default class DevStatus extends View {
  init(_props, cx) {
    this.runs = [];
    this.error = null;
    if (checking()) return;
    this.script = `${home()}/.config/tmux/status/status-right.sh`;
    this.refresh(cx);
    cx.timer.every(REFRESH_MS, (cx) => this.refresh(cx));
  }

  refresh(cx) {
    if (this.busy) return;
    this.busy = true;
    cx.spawn(async (cx) => {
      try {
        const [extra, r] = await Promise.all([
          exec("bash", ["-c", LEFT_EXTRAS], { timeout: 20000 }).catch(() => null),
          exec("bash", [this.script], { timeout: 20000 }),
        ]);
        if (r.code === 0) {
          const extraRuns = extra?.code === 0 ? parse(extra.stdout.replace(/\n+$/, "")) : [];
          const rightRuns = parse(r.stdout.replace(/\n+$/, ""));
          // Join the two groups: the first status-right arrow starts on the
          // last extra segment's colour, not on the bar background.
          const lastBg = extraRuns.filter((x) => x.bg && x.bg.toLowerCase() !== TMUX_BAR_BG).pop()?.bg;
          if (lastBg && rightRuns[0]?.text === SEPARATOR) rightRuns[0] = { ...rightRuns[0], bg: lastBg };
          this.runs = [...extraRuns, ...rightRuns];
          this.error = null;
        } else {
          this.error = (r.stderr || "status-right.sh failed").trim().split("\n")[0];
        }
      } catch (e) {
        this.error = String(e?.message ?? e);
      } finally {
        this.busy = false;
        cx.notify();
      }
    });
  }

  left(t) {
    const list = agents();
    const count = (status) => list.filter((a) => a.status === status).length;
    // One icon and count per state that has agents (Nerd Font glyphs; the
    // robot matches the tmux herdr segment). Hover shows the state name.
    const states = [
      ["working", "\u{f06a9}", t.working],
      ["blocked", "\u{f009e}", t.blocked],
      ["done", "\u{f012c}", t.done],
      ["idle", "\u{f04b2}", t.idle ?? t.muted],
      ["unknown", "\u{f0625}", t.dim],
    ].map(([name, icon, color]) => ({ name, icon, color, n: count(name) })).filter((st) => st.n > 0);
    return h_flex().items_center().px(12).overflow_hidden().flex_1()
      .child(h_flex().gap(12).items_center().flex_none()
        .when(list.length === 0, (el) => el.child(div().text_color(t.dim).child("no agents")))
        .children(states.map((st) => div().id(`agents-${st.name}`).text_color(st.color).tooltip(`${st.n} ${st.name}`).child(`${st.icon} ${st.n}`))));
  }

  right(t) {
    const bg = (c) => (c && c.toLowerCase() !== TMUX_BAR_BG ? c : null);
    if (this.error) {
      return h_flex().px(12).items_center().text_color(t.blocked).child(this.error);
    }
    return h_flex().h_full().flex_none().items_center().children(
      this.runs.map((r, i) => {
        if (r.text === SEPARATOR) {
          return div().id(`sep-${i}`).h_full().w(12).flex_none().when(Boolean(bg(r.bg)), (el) => el.bg(bg(r.bg)))
            .child(svg("mods/dev-status/sep.svg").w(12).h_full().text_color(r.fg ?? t.chrome));
        }
        const action = ACTIONS.find((a) => a.test.test(r.text));
        return div().id(`run-${i}`).h_full().flex_none().flex().items_center().whitespace_nowrap()
          .when(Boolean(action), (el) => el.cursor_pointer().tooltip(action.tip)
            .on_click((_e, cx) => cx.spawn(async (cx) => { try { await action.run(cx); } catch {} })))
          .when(Boolean(bg(r.bg)), (el) => el.bg(bg(r.bg)))
          .text_color(r.fg ?? t.foreground)
          .child(r.text);
      }));
  }

  // Dock badge: how many agents need you. Set only when the number changes.
  badge(list) {
    const n = list.filter((a) => a.status === "blocked").length;
    if (n === this.badged) return;
    this.badged = n;
    setBadge(n ? String(n) : null);
  }

  render() {
    const t = theme();
    if (!checking()) this.badge(agents());
    // props.edge "top": the bar sits above the tabs, so the border goes below it.
    const top = props()?.edge === "top";
    return h_flex().id("root").size_full().items_center().bg(t.chrome)
      .when(top, (el) => el.border_b(1)).when(!top, (el) => el.border_t(1)).border_color(t.border)
      .font_family(FONT).text_size(14)
      .child(this.left(t))
      .child(this.right(t));
  }
}
