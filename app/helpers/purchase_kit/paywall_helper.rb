module PurchaseKit
  module PaywallHelper
    # Renders a paywall form that triggers native in-app purchases
    #
    # @param customer_id [String, Integer] The identifier passed back in webhook
    #   events. With Pay, this must be `Pay::Customer.id` (the webhook handler
    #   does `Pay::Customer.find(customer_id)`). Without Pay, use your own user ID.
    # @param success_path [String] Where to redirect after successful purchase
    # @param proration_mode [String] Google Play replacement mode used when a base
    #   plan is swapped within one umbrella subscription (e.g. monthly to annual).
    #   One of "charge_prorated_price" (default), "with_time_proration",
    #   "charge_full_price", "without_proration", or "deferred". Ignored on Apple,
    #   which handles intra-group upgrades and downgrades automatically.
    # @yield [PaywallBuilder] Builder for plan options and buttons
    #
    # Example (with Pay):
    #   <% pay_customer = current_user.set_payment_processor(:purchasekit) %>
    #   <%= purchasekit_paywall customer_id: pay_customer.id, success_path: dashboard_path do |paywall| %>
    #     <%= paywall.plan_option product: @annual, selected: true do %>
    #       Annual - <%= paywall.price %>
    #     <% end %>
    #     <%= paywall.submit "Subscribe" %>
    #   <% end %>
    #
    def purchasekit_paywall(customer_id:, success_path: main_app.root_path, proration_mode: "charge_prorated_price", **options)
      raise ArgumentError, "customer_id is required" if customer_id.blank?

      builder = PaywallBuilder.new(self)

      form_data = (options.delete(:data) || {}).merge(
        controller: "purchasekit--paywall",
        purchasekit__paywall_customer_id_value: customer_id,
        purchasekit__paywall_proration_mode_value: proration_mode
      )

      form_with(url: purchase_kit.purchases_path, id: "purchasekit_paywall", data: form_data, **options) do |form|
        hidden = hidden_field_tag(:customer_id, customer_id)
        hidden += hidden_field_tag(:success_path, success_path)
        hidden += hidden_field_tag(:environment, "sandbox", data: {purchasekit__paywall_target: "environment"})
        hidden + capture { yield builder }
      end
    end
  end

  class PaywallBuilder
    def initialize(template)
      @template = template
      @current_product = nil
    end

    def plan_option(product:, selected: false, input_class: nil, **options, &block)
      input_id = "purchasekit_plan_#{product.id.to_s.parameterize.underscore}"

      radio = @template.radio_button_tag(
        :product_id,
        product.id,
        selected,
        id: input_id,
        class: input_class,
        required: true,
        autocomplete: "off",
        data: {
          purchasekit__paywall_target: "planRadio",
          apple_store_product_id: product.apple_product_id,
          google_store_product_id: product.google_product_id,
          google_store_base_plan_id: product.google_base_plan_id
        }
      )

      @current_product = product
      label = @template.label_tag(input_id, **options) { @template.capture(&block) }
      @current_product = nil

      radio + label
    end

    def price(**options, &block)
      raise "price must be called within a plan_option block" unless @current_product

      data = (options.delete(:data) || {}).merge(
        purchasekit__paywall_target: "price",
        apple_store_product_id: @current_product.apple_product_id,
        google_store_product_id: @current_product.google_product_id,
        google_store_base_plan_id: @current_product.google_base_plan_id
      )

      loading_content = block ? @template.capture(&block) : "Loading..."
      @template.content_tag(:span, loading_content, data: data, **options)
    end

    def submit(text = "Subscribe", **options)
      data = (options.delete(:data) || {}).merge(
        purchasekit__paywall_target: "submitButton",
        turbo_submits_with: text
      )

      @template.submit_tag(text, disabled: true, data: data, **options)
    end

    def restore(text = "Restore purchases", url: nil, **options)
      data = (options.delete(:data) || {}).merge(
        purchasekit__paywall_target: "restoreButton",
        action: "purchasekit--paywall#restore"
      )
      data[:restore_url] = url if url

      @template.content_tag(:button, text, type: "button", data: data, **options)
    end

  end
end
