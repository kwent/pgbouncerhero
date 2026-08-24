module PgBouncerHero
  module ApplicationHelper
    def is_active(action_name)
      params[:action] == action_name ? "active" : nil
    end

    def alert_class_for(flash_type)
      case flash_type
      when "success" then "success"
      when "error" then "error"
      when "notice" then "info"
      when "warning" then "warning"
      end
    end

    def alert_style_for(class_name)
      case class_name
      when "success" then "bg-green-50 text-green-800 border border-green-200"
      when "error" then "bg-red-50 text-red-800 border border-red-200"
      when "info" then "bg-blue-50 text-blue-800 border border-blue-200"
      when "warning" then "bg-yellow-50 text-yellow-800 border border-yellow-200"
      else "bg-gray-50 text-gray-800 border border-gray-200"
      end
    end

    def humanize_ms(millis)
      [ [ 1000, :ms ], [ 60, :s ], [ 60, :min ], [ 24, :h ], [ 1000, :d ] ].map { |count, name|
        if millis > 0
          millis, n = millis.divmod(count)
          "#{n.to_i} #{name}"
        end
      }.compact.reverse.join(" ")
    end

    def monitoring_panel(&block)
      frame_id = "monitoring_#{params[:action]}"

      content_tag(:div,
        data: {
          controller: "polling",
          polling_interval_value: 60_000,
          action: "turbo:frame-load->polling#refreshed"
        }) do
        safe_join([
          monitoring_refresh_controls,
          turbo_frame_tag(frame_id, data: { polling_refresh_url: request.path }, &block)
        ])
      end
    end

    private

    def monitoring_refresh_controls
      content_tag(:div, class: "flex items-center justify-end gap-3 mb-3") do
        safe_join([
          content_tag(:span, "Updated just now", class: "text-xs text-gray-500", data: { polling_target: "status" }, aria: { live: "polite" }),
          button_tag("Refresh", type: "button", class: "px-3 py-1.5 text-sm font-medium rounded-md border border-gray-300 text-gray-700 hover:bg-white", data: { action: "polling#refresh" })
        ])
      end
    end
  end
end
