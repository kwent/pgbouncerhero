module PgBouncerHero
  module ApplicationHelper
    def is_active(action_name)
      params[:action] == action_name ? 'active' : nil
    end
    def alert_class_for(flash_type)
      case flash_type
      when 'success'
        'success'
      when 'error'
        'error'
      when 'notice'
        'info'
      when 'warning'
        'warning'
      else
        nil
      end
    end
    def humanize_ms(millis)
      [[1000, :ms], [60, :s], [60, :min], [24, :h], [1000, :d]].map{ |count, name|
        if millis > 0
          millis, n = millis.divmod(count)
          "#{n.to_i} #{name}"
        end
      }.compact.reverse.join(' ')
    end
  end
end
