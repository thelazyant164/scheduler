module Timeslot
    def to_time(str)
        hour = str.split('-')[0].strip().to_i()
        min = str.split('-')[1].strip().to_i()
        begin
            date = str.split('-')[2].strip()
        rescue
        end
        return {"date" => date, "hour" => hour, "min" => min}
    end

    def to_str(hash)
        str = " " + hash["hour"].to_s + "-" + hash["min"].to_s
        begin
            str += "-" + hash["date"]
        rescue
        end
        return str
    end

    def to_decimal(hash)
        return hash["hour"] + hash["min"]/60.to_f()
    end

    def to_display(fl)
        hour = fl.floor()
        min = (fl - hour)*60
        str = hour.to_s() + ":" + min.floor().to_s()
        return str
    end
end