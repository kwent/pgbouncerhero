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
  end
end
