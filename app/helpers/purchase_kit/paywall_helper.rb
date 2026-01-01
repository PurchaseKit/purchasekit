module PurchaseKit
  module PaywallHelper
    # Renders a paywall form that triggers native in-app purchases
    #
    # @param customer_id [String, Integer] Your user/customer identifier
    # @param success_path [String] Where to redirect after successful purchase
    # @yield [PaywallBuilder] Builder for plan options and buttons
    #
    # Example:
    #   <%= purchasekit_paywall customer_id: current_user.id, success_path: dashboard_path do |paywall| %>
    #     <%= paywall.plan_option product: @annual, selected: true do %>
    #       Annual - <%= paywall.price %>
    #     <% end %>
    #     <%= paywall.submit "Subscribe" %>
    #   <% end %>
    #
    def purchasekit_paywall(customer_id:, success_path: main_app.root_path, **options)
      raise ArgumentError, "customer_id is required" if customer_id.blank?

      builder = PaywallBuilder.new(self)

      form_data = (options.delete(:data) || {}).merge(
        controller: "purchasekit--paywall",
        purchasekit__paywall_customer_id_value: customer_id
      )

      form_with(url: purchasekit.purchases_path, id: "purchasekit_paywall", data: form_data, **options) do |form|
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
        autocomplete: "off",
        data: {
          purchasekit__paywall_target: "planRadio",
          apple_store_product_id: product.apple_product_id,
          google_store_product_id: product.google_product_id
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
        google_store_product_id: @current_product.google_product_id
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

    def restore_link(text: "Restore purchases", **options)
      data = (options.delete(:data) || {}).merge(
        action: "click->purchasekit--paywall#restore"
      )

      @template.link_to(text, "#", data: data, **options)
    end
  end
end
