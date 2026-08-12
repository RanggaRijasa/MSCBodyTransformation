(() => {
  const installActions = Array.from(document.querySelectorAll('[data-install-app]'));
  const installStatus = document.querySelector('[data-install-status]');
  let deferredInstallPrompt = null;

  const announce = (message) => {
    if (installStatus) installStatus.textContent = message;
  };

  window.addEventListener('beforeinstallprompt', (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
  });

  window.addEventListener('appinstalled', () => {
    deferredInstallPrompt = null;
    announce('MSC berhasil dipasang di perangkatmu.');
  });

  for (const action of installActions) {
    action.addEventListener('click', async (event) => {
      if (!deferredInstallPrompt) return;

      event.preventDefault();
      const prompt = deferredInstallPrompt;
      deferredInstallPrompt = null;

      try {
        await prompt.prompt();
        const choice = await prompt.userChoice;
        announce(
          choice.outcome === 'accepted'
            ? 'Permintaan pemasangan dikirim ke browser.'
            : 'Pemasangan dibatalkan. MSC tetap dapat digunakan di browser.',
        );
      } catch {
        window.location.assign(action.href);
      }
    });
  }
})();
