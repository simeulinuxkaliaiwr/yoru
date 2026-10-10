// Firefox runs this in its own (chrome) code at startup: mozilla.cfg loads it
// from ~/startpages/chrome.js, where `yoru` copies it. It makes the rice's
// start pages behave like Firefox's own new tab page:
//   · the address bar stays empty on them, instead of showing the file's path
//   · yoru's page gets the keyboard, so you type straight into its search
//     (Start page → "Typing goes to" in yoru's settings: search or address)
(function () {
  const home = Services.dirsvc.get("Home", Ci.nsIFile);
  const dir = Services.io.newFileURI(home).spec + "startpages/";
  const settings = home.path + "/.config/yoru/config.json";
  const spec = url => { try { return (url instanceof Ci.nsIURI ? url : Services.io.newURI(url)).spec; } catch (e) { return ""; } };
  const isStart = url => { const s = spec(url); return s.startsWith(dir) && /\.html$/.test(s.split(/[?#]/)[0]); };

  // the window's IOUtils: autoconfig's own scope may not have it
  async function typeInPage(win) {
    try {
      const c = await win.IOUtils.readJSON(settings);
      return (c.start?.focus ?? "search") === "search";
    } catch (e) {
      return true;
    }
  }

  function setup(win) {
    if (!win.gBrowser || win.__yoruStart) return;
    win.__yoruStart = true;

    // the start pages count as "initial" pages: an empty, ready address bar
    const initial = win.isInitialPage;
    win.isInitialPage = url => initial(url) || isStart(url);

    // once yoru's page has loaded in the tab you're on, hand it the keyboard,
    // unless you've already started typing in the address bar
    win.gBrowser.addTabsProgressListener({
      onStateChange(browser, progress, request, flags) {
        const done = Ci.nsIWebProgressListener.STATE_STOP | Ci.nsIWebProgressListener.STATE_IS_WINDOW;
        if ((flags & done) !== done || !progress.isTopLevel) return;
        if (browser !== win.gBrowser.selectedBrowser) return;
        if (!spec(browser.currentURI).startsWith(dir + "yoru-start.html")) return;
        typeInPage(win).then(yes => {
          if (!yes || browser !== win.gBrowser.selectedBrowser) return;
          const bar = win.gURLBar;
          if (bar.focused && bar.value !== "") return;
          browser.focus();
        });
      },
    });
  }

  for (const win of Services.wm.getEnumerator("navigator:browser")) setup(win);
  Services.obs.addObserver(win => setup(win), "browser-delayed-startup-finished");
})();
