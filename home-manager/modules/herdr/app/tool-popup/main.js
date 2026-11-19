// A tool in a floating window over the panes, like the TUI's popup keys
// (tmux-prefix l, d, i, f; 95% x 90% of the window). Two roles:
// - Starter, props { title, argv, cwd?, on? }: a tiny overlay that starts the
//   program as a terminal with no pane (hc run --bg), opens the popup, then
//   closes itself. The prefix popup closes before hc answers, so it cannot
//   wait for it itself.
// - Title bar, props { title, terminal }: the popup's top block. The popup
//   is a modal dialog, so it takes the keyboard, and Esc goes to the
//   program. It closes by itself when the program ends (q in lazygit or
//   gh-dash). ✕ ends the program first.

import { View, div } from "gpui-kit";
import { h_flex } from "gpui-base";
import { closeOverlay, hc, openOverlay, props, theme } from "herdr";

const quote = (a) => `'${a.replace(/'/g, "'\\''")}'`;

export default class ToolPopup extends View {
  init(_props, cx) {
    const p = props() ?? {};
    if (p.terminal || !p.argv) return;
    cx.spawn(async () => {
      try {
        const r = await hc(["run", "--bg", "--json", "--no-parent", "--rm",
          ...(p.cwd ? ["--cwd", p.cwd] : []), ...(p.on ? ["--on", p.on] : []),
          "--", "/bin/zsh", "-lc", p.argv.map(quote).join(" ")]);
        if (r.code !== 0) throw new Error(r.stderr.trim() || "hc run failed");
        const id = JSON.parse(r.stdout).address;
        const terminal = p.on ? `${p.on}/${id}` : id;
        openOverlay({
          kind: "dialog", modal: true, width: 0.95, height: 0.9,
          layout: { type: "column", children: [
            { type: "block", size: { px: 28 }, content: { mod: "tool-popup", props: { title: p.title, terminal } } },
            { type: "block", content: { terminal } },
          ] },
        });
      } catch (e) {
        console.log(`tool-popup: ${e?.message ?? e}`);
      } finally {
        closeOverlay(p.overlay);
      }
    });
  }

  close(cx) {
    const { terminal, overlay } = props();
    cx.spawn(async () => {
      try { await hc(["kill", terminal]); } catch {}
      closeOverlay(overlay);
    });
  }

  render() {
    const p = props() ?? {};
    if (!p.terminal) return div();
    const t = theme();
    return h_flex().id("tool-popup").size_full().px(12).gap(8).items_center().bg(t.chrome)
      .border_b(1).border_color(t.border).text_size(12).text_color(t.muted)
      .child(div().flex_1().truncate().child(p.title ?? ""))
      .child(div().text_size(11).text_color(t.dim).child("q to quit"))
      .child(div().id("tool-popup-close").px(6).rounded(4).cursor_pointer()
        .hover((s) => s.bg(t.hover).text_color(t.foreground))
        .on_mouse_down("left", (_e, cx) => cx.stop_propagation())
        .on_click((_e, cx) => this.close(cx)).child("✕"));
  }
}
