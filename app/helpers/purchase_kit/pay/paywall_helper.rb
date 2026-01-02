module PurchaseKit::Pay::PaywallHelper
  # Wrapper for paywall with bridge controller
  # Renders a form that posts to the purchases endpoint
  # Yields a builder for plan options and buttons
  # Requires a Pay::Customer - call user.set_payment_processor(:purchasekit) first
  def purchasekit_paywall(customer:, success_path: main_app.root_path, **options)
    raise ArgumentError, "Must provide customer: parameter. Call user.set_payment_processor(:purchasekit) first." unless customer

    builder = PurchaseKit::Pay::PaywallBuilder.new(self, customer)

    form_data = (options.delete(:data) || {}).merge(
      controller: "purchasekit--paywall",
      purchasekit__paywall_customer_id_value: customer.id
    )

    form_with(url: purchasekit_pay.purchases_path, id: "purchasekit_paywall", data: form_data, **options) do |form|
      hidden = hidden_field_tag(:customer_id, customer.id)
      hidden += hidden_field_tag(:success_path, success_path)
      hidden += hidden_field_tag(:environment, "sandbox", data: {purchasekit__paywall_target: "environment"})
      hidden + capture { yield builder }
    end
  end
end

class PurchaseKit::Pay::PaywallBuilder
  def initialize(template, customer)
    @template = template
    @customer = customer
    @current_product = nil
  end

  def plan_option(product:, selected: false, input_class: nil, **options, &block)
    input_id = "purchasekit_plan_#{product.id.parameterize.underscore}"

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

end
