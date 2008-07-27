
require 'time'

module TumblogHelper

  DAYS = {}
  (1..31).each {|day| DAYS[day] = "%dth" % day}
  DAYS[1]  = "1st"
  DAYS[2]  = "2nd"
  DAYS[3]  = "3rd"
  DAYS[21] = "21st"
  DAYS[22] = "22nd"
  DAYS[23] = "23rd"
  DAYS[31] = "31st"

  def tumblog_date( time )
    <<-HTML
    <div class="date">
      <div class="date_brick">
        #{Time::RFC2822_MONTH_NAME.at(time.month-1)}<br />
        #{TumblogHelper::DAYS[time.day]}
      </div>
        #{Time::RFC2822_DAY_NAME.at(time.wday)}
    </div>
    HTML
  end

end  # module TumblogHelper

Webby::Helpers.register(TumblogHelper)

# EOF
