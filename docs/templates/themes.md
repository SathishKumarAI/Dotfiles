# Theme System — Light (Square) + Dark (Catppuccin)

Reusable, framework-agnostic theme system for any project. Two themes on the same
CSS variables, toggled by a `data-theme` attribute on `<html>`. Drop `theme.css`
into any app, use the semantic vars everywhere, add the toggle snippet.

Proven in `~/coding/khanban-for-me`.

## The rule
- **Never hardcode colors in components.** Use the semantic vars (`--base`, `--text`, `--blue`, `--border`, …). Then a project supports both themes for free.
- Light is the default (`:root`). Dark overrides under `:root[data-theme="dark"]`.
- Buttons are **pills** (`border-radius: 999px`); display headings use a **serif** stack. That's the Square feel.

## Palette (drop into theme.css)
```css
/* Light — Square-inspired (default) */
:root {
  --base:#ffffff; --mantle:#f7f8fa; --crust:#eef0f4;
  --surface0:#f0f2f5; --surface1:#e4e7ec; --surface2:#d3d8e0; --overlay0:#8a909c;
  --text:#16161d; --subtext1:#3a3f4b; --subtext0:#6b7280;
  --blue:#2f6bff; --lavender:#5b7cfa; --sapphire:#0369a1; --green:#16a34a;
  --yellow:#ca8a04; --peach:#ea580c; --red:#dc2626; --mauve:#7c3aed; --teal:#0d9488;
  --border:#e4e7ec; --radius:10px; --ring:rgba(47,107,255,.35);
  --shadow-sm:0 1px 2px rgba(16,24,40,.06); --shadow-md:0 6px 20px rgba(16,24,40,.10);
}
/* Dark — Catppuccin Mocha */
:root[data-theme="dark"] {
  --base:#1e1e2e; --mantle:#181825; --crust:#11111b;
  --surface0:#313244; --surface1:#45475a; --surface2:#585b70; --overlay0:#6c7086;
  --text:#cdd6f4; --subtext1:#bac2de; --subtext0:#a6adc8;
  --blue:#89b4fa; --lavender:#b4befe; --sapphire:#74c7ec; --green:#a6e3a1;
  --yellow:#f9e2af; --peach:#fab387; --red:#f38ba8; --mauve:#cba6f7; --teal:#94e2d5;
  --border:#2a2b3c; --ring:rgba(137,180,250,.5);
  --shadow-sm:0 1px 2px rgba(0,0,0,.25); --shadow-md:0 4px 14px rgba(0,0,0,.3);
}
```

## Signature styles
```css
body { background:var(--base); color:var(--text);
  font:14px/1.5 ui-sans-serif, system-ui, -apple-system, "Segoe UI", Roboto, sans-serif; }
h1 { font-family: ui-serif, Georgia, Cambria, "Times New Roman", serif; font-weight:700; }
button { border-radius:999px; border:1px solid var(--border); background:var(--surface0);
  padding:7px 14px; font-weight:600; }
button.primary { background:var(--blue); color:#fff; border-color:var(--blue); box-shadow:var(--shadow-sm); }
button.ghost { background:transparent; }
.card, .panel { background:var(--mantle); border:1px solid var(--border);
  border-radius:var(--radius); box-shadow:var(--shadow-sm); }
```

## Toggle (React)
```tsx
const [theme, setTheme] = useState<"light"|"dark">(
  () => (localStorage.getItem("theme") as "light"|"dark") || "light");
useEffect(() => {
  document.documentElement.setAttribute("data-theme", theme);
  localStorage.setItem("theme", theme);
}, [theme]);
// <button onClick={() => setTheme(t => t==="light"?"dark":"light")}>{theme==="light"?"🌙":"☀️"}</button>
```

## Toggle (vanilla)
```js
const t = localStorage.getItem("theme") || "light";
document.documentElement.setAttribute("data-theme", t);
function toggleTheme(){ const n = (localStorage.getItem("theme")||"light")==="light"?"dark":"light";
  localStorage.setItem("theme", n); document.documentElement.setAttribute("data-theme", n); }
```

## Checklist for a new project
- [ ] Copy the palette + signature styles into `theme.css`; import it once.
- [ ] Use only semantic vars in components (grep for hex codes — there should be none outside theme.css).
- [ ] Add the toggle to the header; default light.
- [ ] Overlays/scrims can stay dark-translucent (`rgba(16,24,40,.5)`) in both themes.
