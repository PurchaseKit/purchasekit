import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "paywall"
  static targets = ["planRadio", "price", "submitButton", "response", "environment", "restoreButton"]
  static values = { prorationMode: { type: String, default: "charge_prorated_price" } }

  connect() {
    super.connect()
    this.#fetchPrices()
  }

  disconnect() {
    if (this.#fallbackTimeoutId) {
      clearTimeout(this.#fallbackTimeoutId)
    }
    this.#stopWatchingForCompletion()
  }

  restore() {
    if (this.hasRestoreButtonTarget) {
      this.restoreButtonTarget.disabled = true
    }

    this.send("restore", {}, message => {
      if (this.hasRestoreButtonTarget) {
        this.restoreButtonTarget.disabled = false
      }

      const { subscriptionIds, error } = message.data
      this.dispatch("restore", { detail: { subscriptionIds, error } })

      const restoreUrl = this.hasRestoreButtonTarget && this.restoreButtonTarget.dataset.restoreUrl
      if (!error && restoreUrl) {
        this.#submitRestore(restoreUrl, subscriptionIds || [])
      }
    })
  }

  responseTargetConnected(element) {
    const error = element.dataset.error

    if (error) {
      element.remove()
      alert(error)
      this.#enableForm()
      return
    }

    const correlationId = element.dataset.correlationId
    const productIds = this.#productIds(element)
    const relativeUrl = element.dataset.xcodeCompletionUrl
    const xcodeCompletionUrl = relativeUrl ? `${window.location.origin}${relativeUrl}` : null
    const successPath = element.dataset.successPath

    element.remove()
    this.#disableForm()
    this.dispatch("initiated", { detail: { correlationId } })
    this.#triggerNativePurchase(productIds, correlationId, xcodeCompletionUrl, successPath)
  }

  #triggerNativePurchase(productIds, correlationId, xcodeCompletionUrl, successPath) {
    // googleStoreProrationMode only applies on Android plan swaps; iOS ignores it.
    const googleStoreProrationMode = this.prorationModeValue
    this.send("purchase", { ...productIds, correlationId, xcodeCompletionUrl, googleStoreProrationMode }, message => {
      const { status, error } = message.data

      if (error) {
        console.error(error)
        alert(`Purchase error: ${error}`)
        this.#enableForm()
        return
      }

      if (status == "cancelled") {
        this.#enableForm()
        return
      }

      // The store confirmed the purchase. The Pay::Subscription (and the redirect)
      // still depend on the server webhook, so move into the awaiting state.
      this.dispatch("store-confirmed", { detail: { status } })
      this.#awaitCompletion(successPath)
    })
  }

  // Waits for the webhook-driven redirect after the store confirms a purchase.
  // The redirect arrives as a Turbo Stream "redirect" action over ActionCable, with
  // a 30-second fallback for when ActionCable isn't connected.
  #awaitCompletion(successPath) {
    this.dispatch("awaiting-webhook", { detail: {} })

    this.#streamRenderListener = event => {
      if (event.target?.getAttribute("action") === "redirect") {
        this.#complete()
      }
    }
    document.addEventListener("turbo:before-stream-render", this.#streamRenderListener)

    if (successPath) {
      this.#fallbackTimeoutId = setTimeout(() => {
        this.#complete()
        window.Turbo.visit(successPath)
      }, 30000)
    }
  }

  #complete() {
    if (this.#completed) return
    this.#completed = true

    if (this.#fallbackTimeoutId) {
      clearTimeout(this.#fallbackTimeoutId)
      this.#fallbackTimeoutId = null
    }
    this.#stopWatchingForCompletion()
    this.dispatch("complete", { detail: {} })
  }

  #stopWatchingForCompletion() {
    if (this.#streamRenderListener) {
      document.removeEventListener("turbo:before-stream-render", this.#streamRenderListener)
      this.#streamRenderListener = null
    }
  }

  #submitRestore(url, subscriptionIds) {
    const csrfToken = document.querySelector("meta[name=csrf-token]")?.content

    fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(csrfToken && { "X-CSRF-Token": csrfToken })
      },
      body: JSON.stringify({ subscription_ids: subscriptionIds })
    }).then(response => {
      if (response.redirected) {
        window.Turbo.visit(response.url)
      }
    }).catch(error => {
      console.error("Restore request failed:", error)
      alert("Something went wrong restoring purchases. Please try again.")
    })
  }

  #fallbackTimeoutId = null
  #streamRenderListener = null
  #completed = false

  #fetchPrices() {
    const products = this.priceTargets.map(el => this.#productIds(el))

    this.send("prices", { products }, message => {
      const { prices, environment, error } = message.data

      if (error) {
        console.error(error)
        return
      }

      if (prices) {
        this.#setPrices(prices)
        this.#setEnvironment(environment)
        this.#enableForm()
      }
    })
  }

  #setEnvironment(environment) {
    if (this.hasEnvironmentTarget && environment) {
      this.environmentTarget.value = environment
    }
  }

  #setPrices(prices) {
    this.priceTargets.forEach(el => {
      const { appleStoreProductId, googleStoreProductId, googleStoreBasePlanId } = this.#productIds(el)
      const price = prices[appleStoreProductId] || prices[googleStoreBasePlanId] || prices[googleStoreProductId]

      if (price) {
        el.textContent = price
      } else {
        console.error(`No price found for product.`)
      }
    })
  }

  #productIds(element) {
    return {
      appleStoreProductId: element.dataset.appleStoreProductId,
      googleStoreProductId: element.dataset.googleStoreProductId,
      googleStoreBasePlanId: element.dataset.googleStoreBasePlanId
    }
  }

  #enableForm() {
    this.planRadioTargets.forEach(radio => radio.disabled = false)
    if (this.hasSubmitButtonTarget) {
      this.submitButtonTarget.disabled = false
      if (this.#originalButtonText) {
        this.submitButtonTarget.innerHTML = this.#originalButtonText
      }
    }
  }

  #disableForm() {
    this.planRadioTargets.forEach(radio => radio.disabled = true)
    if (this.hasSubmitButtonTarget) {
      this.#originalButtonText = this.submitButtonTarget.innerHTML
      this.submitButtonTarget.disabled = true
      const processingText = this.submitButtonTarget.dataset.processingText || "Processing..."
      this.submitButtonTarget.innerHTML = processingText
    }
  }

  #originalButtonText = null
}
