// Custom Turbo Stream action for redirects after subscription events.
Turbo.StreamActions.redirect = function() {
  Turbo.visit(this.getAttribute("url"), {action: "replace"})
}
