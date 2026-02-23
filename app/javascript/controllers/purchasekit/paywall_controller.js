import { BridgeComponent } from "@hotwired/hotwire-native-bridge"

export default class extends BridgeComponent {
  static component = "paywall"
  static targets = ["planRadio", "price", "submitButton", "response", "environment", "restoreButton"]

  connect() {
    super.connect()
    this.#fetchPrices()
  }

  disconnect() {
    if (this.#fallbackTimeoutId) {
      clearTimeout(this.#fallbackTimeoutId)
    }
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
    this.#triggerNativePurchase(productIds, correlationId, xcodeCompletionUrl, successPath)
  }

  #triggerNativePurchase(productIds, correlationId, xcodeCompletionUrl, successPath) {
    this.send("purchase", { ...productIds, correlationId, xcodeCompletionUrl }, message => {
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

      // On success, Turbo Stream will broadcast redirect when webhook completes.
      // Fallback: redirect after 30 seconds in case ActionCable isn't connected.
      if (successPath) {
        this.#fallbackTimeoutId = setTimeout(() => {
          window.Turbo.visit(successPath)
        }, 30000)
      }
    })
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
      const { appleStoreProductId, googleStoreProductId } = this.#productIds(el)
      const price = prices[appleStoreProductId] || prices[googleStoreProductId]

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
      googleStoreProductId: element.dataset.googleStoreProductId
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
