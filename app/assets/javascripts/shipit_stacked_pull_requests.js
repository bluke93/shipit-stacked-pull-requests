// Toggles any element with `data-accordion-toggle` and the panel named by its `aria-controls`.
// With `data-accordion-src="url"`, the panel content is loaded the first time it is expanded.
//
// Shipit's live updates replace the content of #layout-content, so panels the user toggled are restored
// whenever that happens.
(function ($) {
  var SLIDE_DURATION = 200;

  var toggledPanels = {};
  var loadedContent = {};
  var pendingRequests = {};

  function panel(panelId) {
    return $(document.getElementById(panelId));
  }

  function loadPanel($toggle, panelId) {
    var src = $toggle.data('accordion-src');
    if (!src) return;

    if (loadedContent[src] !== undefined) {
      panel(panelId).html(loadedContent[src]);
      return;
    }

    panel(panelId).html('<p class="accordion-message">Loading…</p>');
    if (pendingRequests[src]) return;

    pendingRequests[src] = $.get(src)
      .done(function (html) {
        loadedContent[src] = html;
        panel(panelId).html(html);
      })
      .fail(function () {
        panel(panelId).html('<p class="accordion-message">Could not load commits.</p>');
      })
      .always(function () {
        delete pendingRequests[src];
      });
  }

  function slideDuration() {
    var reduceMotion = window.matchMedia && window.matchMedia('(prefers-reduced-motion: reduce)').matches;
    return reduceMotion ? 0 : SLIDE_DURATION;
  }

  // The `hidden` attribute holds the state; the slide only animates the change and leaves no inline styles behind.
  function setExpanded($toggle, expanded, animate) {
    var panelId = $toggle.attr('aria-controls');
    var $panel = panel(panelId).stop(true, true);
    var duration = animate ? slideDuration() : 0;

    $toggle.attr('aria-expanded', String(expanded));
    if (expanded) loadPanel($toggle, panelId);

    if (expanded) {
      $panel.prop('hidden', false).css('display', '');
      if (duration) $panel.hide().slideDown(duration, function () { $panel.css('display', ''); });
    } else if (duration) {
      $panel.slideUp(duration, function () { $panel.prop('hidden', true).css('display', ''); });
    } else {
      $panel.prop('hidden', true).css('display', '');
    }
  }

  function restoreState() {
    $('[data-accordion-toggle]').each(function () {
      var $toggle = $(this);
      var expanded = toggledPanels[$toggle.attr('aria-controls')];
      if (expanded !== undefined) setExpanded($toggle, expanded, false);
    });
  }

  $(document).on('click', '[data-accordion-toggle]', function (event) {
    var $toggle = $(event.currentTarget);
    var expanded = $toggle.attr('aria-expanded') !== 'true';
    setExpanded($toggle, expanded, true);
    toggledPanels[$toggle.attr('aria-controls')] = expanded;
  });

  $(function () {
    restoreState();

    var content = document.getElementById('layout-content');
    if (content && window.MutationObserver) {
      new MutationObserver(restoreState).observe(content, { childList: true });
    }
  });
})(jQuery);
