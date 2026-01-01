pin "@hotwired/hotwire-native-bridge", to: "https://cdn.jsdelivr.net/npm/@hotwired/hotwire-native-bridge@1.2.2/dist/hotwire-native-bridge.js"
pin_all_from PurchaseKit::Engine.root.join("app/javascript/controllers/purchasekit"), under: "controllers/purchasekit"
pin_all_from PurchaseKit::Engine.root.join("app/javascript/purchasekit"), under: "purchasekit"
