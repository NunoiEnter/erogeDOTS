.pragma library

function inside(item, root) {
    for (let parent = item; parent; parent = parent.parent) if (parent === root) return true;
    return false;
}

function boundary(item) {
    for (let parent = item.parent; parent; parent = parent.parent)
        if (parent.keyboardBoundary === true) return parent;
    return null;
}

function controls(root) {
    let result = [];
    if (!root || !root.visible || !root.enabled) return result;
    if (root.activeFocusOnTab) return [root];
    for (const child of root.children || []) result = result.concat(controls(child));
    return result;
}

function first(root) {
    const items = controls(root);
    if (items.length) items[0].forceActiveFocus(Qt.TabFocusReason);
}

function move(item, forward) {
    const root = boundary(item);
    if (!root) { item.nextItemInFocusChain(forward).forceActiveFocus(Qt.TabFocusReason); return; }
    let next = item.nextItemInFocusChain(forward);
    // Native focus order handles editable controls; keep the pane's traversal local.
    for (let attempts = 0; next && attempts < 256; attempts++) {
        if (inside(next, root) && next.visible && next.enabled && next.activeFocusOnTab) {
            next.forceActiveFocus(Qt.TabFocusReason);
            return;
        }
        next = next.nextItemInFocusChain(forward);
        if (next === item) break;
    }
}
