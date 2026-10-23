pragma Singleton

import Quickshell

// a helper that runs as long as the shell does should go when it goes: a restart (yoru-watch)
// would otherwise leave it running with nobody reading it (skwd-helm watch then aborts on its
// next event) or still holding what it holds (wlsunset's colours, an idle inhibitor). setpriv's
// parent-death signal, which survives exec, has the kernel stop it as the shell goes
Singleton {
    function cmd(c, sig) {
        return ["sh", "-c", 'command -v setpriv >/dev/null && exec setpriv --pdeathsig "$0" "$@" || exec "$@"', sig || "TERM"].concat(c);
    }
}
