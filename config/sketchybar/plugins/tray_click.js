// clique la vraie icone de la barre de menus derriere un alias sketchybar.
// argument : le nom de l alias, « proprietaire,nom(rang) », rang 1 = la plus a droite.
// meme liste que sketchybar (alias.c) : fenetres du calque 25, triees de droite a gauche.
ObjC.import("CoreGraphics");

const MENUBAR_LAYER = 25;
const MOUSE_MOVED = 5;
const LEFT_DOWN = 1;
const LEFT_UP = 2;

function menuItems() {
  // kCGWindowListOptionAll, kCGNullWindowID
  const list = ObjC.deepUnwrap(ObjC.castRefToObject($.CGWindowListCopyWindowInfo(0, 0))) || [];
  return list
    .filter(
      (w) =>
        w.kCGWindowLayer === MENUBAR_LAYER &&
        w.kCGWindowName !== undefined &&
        w.kCGWindowOwnerName !== undefined &&
        w.kCGWindowOwnerName !== "Window Server",
    )
    .sort((a, b) => b.kCGWindowBounds.X - a.kCGWindowBounds.X);
}

function find(target) {
  const comma = target.indexOf(",");
  const owner = target.slice(0, comma);
  let name = target.slice(comma + 1);
  const ranked = name.match(/^(.*)\((\d+)\)$/);
  const items = menuItems();
  const same = (w, n) => w.kCGWindowOwnerName === owner && w.kCGWindowName === n;
  if (ranked) {
    const w = items[Number(ranked[2]) - 1];
    if (w && same(w, ranked[1])) return w;
    name = ranked[1];
  }
  return items.find((w) => same(w, name));
}

function post(type, x, y) {
  $.CGEventPost(0, $.CGEventCreateMouseEvent(null, type, { x: x, y: y }, 0));
}

function run(argv) {
  let w = find(argv[0]);
  if (!w) return;
  const x = w.kCGWindowBounds.X + w.kCGWindowBounds.Width / 2;
  // la souris en haut de l ecran fait sortir la barre masquee, par dessus sketchybar
  post(MOUSE_MOVED, x, 0);
  delay(0.4);
  w = find(argv[0]) || w;
  const b = w.kCGWindowBounds;
  const y = Math.max(b.Y + b.Height / 2, 2);
  post(MOUSE_MOVED, b.X + b.Width / 2, y);
  post(LEFT_DOWN, b.X + b.Width / 2, y);
  post(LEFT_UP, b.X + b.Width / 2, y);
}
