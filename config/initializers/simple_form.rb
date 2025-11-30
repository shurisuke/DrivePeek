# config/initializers/simple_form.rb

SimpleForm.setup do |config|
  # ★ 必須フィールドの "*" をカスタム表示
  config.label_text = lambda do |label, required, explicit_label|
    if required
      "#{label} <span>*</span>".html_safe
    else
      label
    end
  end

  config.wrappers :default, class: :input,
    hint_class: :field_with_hint, error_class: :field_with_errors, valid_class: :field_without_errors do |b|
    
    b.use :html5
    b.use :placeholder

    b.optional :maxlength
    b.optional :minlength
    b.optional :pattern
    b.optional :min_max
    b.optional :readonly

    b.use :label_input
    b.use :hint,  wrap_with: { tag: :span, class: :hint }
    b.use :error, wrap_with: { tag: :span, class: :error }
  end

  config.default_wrapper = :default
  config.boolean_style = :nested
  config.button_class = "btn"
  config.error_notification_tag = :div
  config.error_notification_class = "error_notification"
  config.browser_validations = false
  config.boolean_label_class = "checkbox"

end
