// Verification scaffolding: records every window.alert message in
// window.__verifyAlerts, then calls the real alert so the native dialog still
// fires (agent-browser auto-accepts it). Loaded with --init-script before the
// first navigation of a verify-alsat browser session.
(() => {
  const nativeAlert = window.alert.bind(window);
  window.__verifyAlerts = [];
  window.alert = (message) => {
    window.__verifyAlerts.push(String(message));
    return nativeAlert(message);
  };
})();
