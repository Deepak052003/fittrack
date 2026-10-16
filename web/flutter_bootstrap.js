{{flutter_js}}
{{flutter_build_config}}

// Offline caching is done by our own sw.js.
_flutter.loader.load({
  onEntrypointLoaded: async function (engineInitializer) {
    const appRunner = await engineInitializer.initializeEngine();
    await appRunner.runApp();
    requestAnimationFrame(function () {
      if (window.fitPwa) window.fitPwa.appStarted();
    });
  },
});
