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

    def fleet_health(summary)
      return { status: "offline", severity: 3, waiting_clients: 0, max_utilization: 0 } unless summary

      pools = summary_details(summary, :pools_details)
      databases = summary_details(summary, :databases_details)
      waiting_clients = pools.sum { |pool| pool["cl_waiting"].to_i }
      max_utilization = databases.filter_map do |database|
        maximum = database["max_connections"].to_i
        (database["current_connections"].to_f / maximum * 100).round if maximum.positive?
      end.max.to_i

      status, severity = if waiting_clients.positive?
        [ "waiting", 2 ]
      elsif max_utilization >= 80
        [ "high_utilization", 1 ]
      else
        [ "healthy", 0 ]
      end

      { status: status, severity: severity, waiting_clients: waiting_clients, max_utilization: max_utilization }
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

    def summary_details(summary, key)
      row = summary.find { |item| item.key?(key) || item.key?(key.to_s) }
      Array(row && (row[key] || row[key.to_s]))
    end

    def monitoring_refresh_controls
      content_tag(:div, class: "flex items-center justify-between gap-2 mb-3") do
        safe_join([
          content_tag(:span, "Updated just now", class: "text-xs text-gray-500", data: { polling_target: "status" }, aria: { live: "polite" }),
          button_tag("Refresh", type: "button", class: "px-3 py-1.5 text-sm font-medium rounded-md border border-gray-300 text-gray-700 hover:bg-gray-50", data: { action: "polling#refresh" })
        ])
      end
    end
  end
end
