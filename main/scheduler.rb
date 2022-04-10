require 'csv'
require './timeslot'

class Scheduler
    attr_reader :file_name

    #Takes in all file name for all units' csv files, properly formatted
    def initialize(*args)
        @all_units = Array.new()
        args.each do |arg|
            file_name = "./Timetable-data/" + arg
            csv_rows = CSV.parse(File.read(file_name), headers: true)

            # #Validate data integrity
            begin
                unit = process_unit_info(csv_rows)
                puts("Reading scheduling info for #{unit.subject.upcase()}...")
            rescue
                puts('Invalid input detected. Please verify content integrity of unit info.')
            else
                puts('Input verified. No corrupt data found.')
            end

            #Run over all combinations of enrolled classes
            @all_units << unit.shortlist()
        end

        #Shortlist into only clash-free combinations
        begin
            puts("Verifying possible timetable creation...")
            schedule = Timetable.new(@all_units)
        rescue
            puts("Clash-free registration of the available combinations is not plausible. Please contact the student help desk for further assistance.")
        else
            puts("Verified. There are #{schedule.all_enrolled.length} possible clash-free timetable registration from the available combinations.")
            user_choice = prompt()
            #Shortlist timetable registry to best fit user's preference
            schedule.score(user_choice)
            @file_name = schedule.file_name
        end
    end

    #Organize data
    def process_unit_info(data)
        classes = Array.new()
        for i in 0..(data.length - 1) do
            session = Class.new(data[i][0], data[i][1], data[i][2], data[i][3], data[i][4], data[i][5])
            classes << session
        end
        return Unit.new(data[0][0], classes)
    end

    #Prompt user for preference input
    def prompt()
        #Display set of preferences
        puts("Choose your preference presets:")
        puts("+ (m) for morning class-only (where applicable)")
        puts("+ (e) for evening class-only (where applicable)")
        puts("+ (l) for least days on campus (where applicable)")
        puts("+ (s) for spanning classes over the week (recommended)")

        user_choice = gets().chomp()
        #Validate user input
        while !['m', 'e', 'l', 's'].include?(user_choice) do
            puts("Invalid input detected. Please pick from the available options.")
            user_choice = gets().chomp()
        end

        return user_choice
    end
end

class Timetable
    include Timeslot

    attr_reader :all_enrolled, :selected, :file_name

    #Refactor to allow arbitrary num of units
    def initialize(unit_list)
        @unit_list = unit_list
        @all_enrolled = Array.new()
        @scoring_system = Array.new()
        @selected = Array.new()
        self.create_all_combinations()
        self.eliminate_clash()
    end

    #@unit_list = [[[class01, class02], [class01, class03], ...], [], [], [], ...]
    def create_all_combinations()
        @all_enrolled = @unit_list.shift.product(*@unit_list)
        for k in 0..(@all_enrolled.length - 1) do
            group = @all_enrolled[k]
            new_group = Array.new()
            group.each do |mini_group|
                mini_group.each do |a_class|
                    new_group << a_class
                end
            end
            @all_enrolled[k] = new_group
        end
    end

    #@all_enrolled = [[class01, class02, ...], [class03, class04, ...], ...]
    def eliminate_clash()
        def clash_check(set_of_classes)
            all_class_pairs = set_of_classes.combination(2)
            all_class_pairs.each do |pair|
                if pair[0].clash?(pair[1])
                    return true
                end
            end
            return false
        end

        @all_enrolled.delete_if { |current_combo| clash_check(current_combo)}

        if (@all_enrolled.length == 0)
            raise "Exception: conflicting timetable"
        end
    end
    
    def score(criteria)
        if criteria == "m"
            self.morning_only()
        elsif criteria == "e"
            self.evening_only()
        elsif criteria == "l"
            self.least_days()
        else
            puts("Specify your starting time in the morning (you are ready for class starting at and after this point, e.g, 8-30):")
            starting = gets().chomp()
            puts("Specify your lunch time (e.g, 12-30 13-00):")
            lunch_break = gets().split(' ')
            lunch_break_start = lunch_break[0].chomp()
            lunch_break_end = lunch_break[1].chomp()
            puts("Specify your ending time in the evening (you need to leave at this point every day, e.g, 17-30):")
            ending = gets().chomp()
            self.span(starting, ending, [lunch_break_start, lunch_break_end])
        end
        @file_name = write_timetable_to_file()
    end

    def morning_only()
        @all_enrolled.each do |current_combo|
            sum_hour = 0
            current_combo.each do |a_class|
                sum_hour += a_class.time_start["hour"]
            end
            @scoring_system << sum_hour
        end
        selected = @scoring_system.index(@scoring_system.min())
        @selected = @all_enrolled[selected]
    end

    def evening_only()
        @all_enrolled.each do |current_combo|
            sum_hour = 0
            current_combo.each do |a_class|
                sum_hour += a_class.time_start["hour"]
            end
            @scoring_system << sum_hour
        end
        selected = @scoring_system.index(@scoring_system.max())
        @selected = @all_enrolled[selected]
    end

    def least_days()
        @all_enrolled.each do |current_combo|
            days_at_school = 0
            hash = Hash.new()
            current_combo.each do |a_class|
                hash[a_class.time_start["date"]] = 1
            end
            days_at_school = hash.length()
            @scoring_system << days_at_school
        end
        selected = @scoring_system.index(@scoring_system.min())
        @selected = @all_enrolled[selected]
    end

    def span(starting, ending, lunch_break)
        def not_within_prefered_timeslot(a_class, starting, ending, lunch_break)
            before_class = Class.new('a', 'a', 'a', '0-0', starting, 'home')
            lunch = Class.new('b', 'b', 'b', lunch_break[0], lunch_break[1], 'bistro')
            after_class = Class.new('c', 'c', 'c', ending, '23-59', 'home')
            return_value = 0
            if a_class.clash?(before_class)
                return_value += 1
            end
            if a_class.clash?(lunch)
                return_value += 1
            end
            if a_class.clash?(after_class)
                return_value += 1
            end
            return return_value
        end

        @all_enrolled.each do |current_combo|
            noneligibility = 0
            current_combo.each do |a_class|
                noneligibility += not_within_prefered_timeslot(a_class, starting, ending, lunch_break)
            end
            @scoring_system << noneligibility
        end
        selected = @scoring_system.index(@scoring_system.min)
        @selected = @all_enrolled[selected]
    end

    def write_timetable_to_file()

        def sort()

            def same_day_sort(day)
                for i in 0..(day.length - 1)
                    for j in 0..(day.length - 2)
                        if day[j].time_start["hour"] > day[j + 1].time_start["hour"] || (day[j].time_start["hour"] == day[j + 1].time_start["hour"] && day[j].time_start["min"] > day[j + 1].time_start["min"])
                            temp = day[j]
                            day[j] = day[j + 1]
                            day[j + 1] = temp
                        end
                    end
                end
                return day
            end

            monday= Array.new()
            tuesday= Array.new()
            wednesday= Array.new()
            thursday= Array.new()
            friday= Array.new()
            @selected.each do |a_class|
                case a_class.time_start["date"]
                when "mon"
                    monday << a_class
                when "tue"
                    tuesday << a_class
                when "wed"
                    wednesday << a_class
                when "thu"
                    thursday << a_class
                else
                    friday << a_class
                end
            end
            monday = same_day_sort(monday)
            tuesday = same_day_sort(tuesday)
            wednesday = same_day_sort(wednesday)
            thursday = same_day_sort(thursday)
            friday = same_day_sort(friday)

            @selected = monday + tuesday + wednesday + thursday + friday
        end

        self.sort()
        puts("Name output file:")
        file_name = gets().chomp()
        file_name += ".csv"
        puts("Writing timetable to \"#{file_name}\"...")
        CSV.open(file_name, "w") do |csv|
            csv << ["subject", " session", " session_ID", " time-start", " time-end", " place"]
            @selected.each do |a_class|
                csv << [a_class.subject, a_class.session, a_class.session_ID, to_str(a_class.time_start), to_str(a_class.time_end), a_class.place]
            end
        end
        puts("Complete.")
        return file_name
    end
end

class Unit
    attr_reader :subject, :classes

    def initialize(subject, classes)
        @subject = subject
        @classes = classes
        @grouped_classes = Array.new()
        group_classes()
    end

    #@grouped_classes = [[lab01, lab02, lab03], [workshop01, workshop02], ...]
    #Group classes by sessions
    def group_classes()
        @classes.each do |a_class|
            job_done = false
            #First iteration, when @grouped_classes is empty, create first group with first class
            if @grouped_classes.empty?
                new_group = Array.new()
                new_group << a_class
                @grouped_classes << new_group
                next
            end

            #From second iteration onwards
            @grouped_classes.each do |group|
                if (group[0].session == a_class.session)
                    group << a_class
                    job_done = true
                    break
                end
            end

            #Check if class has been assigned to a previously-determined group already
            if job_done
                next
            end

            #Create new group to hold this class' learning method
            new_group = Array.new()
            new_group << a_class
            @grouped_classes << new_group
        end
    end

    #[[class01, class02], [class03, class04],...]
    def shortlist()
        return @grouped_classes.shift.product(*@grouped_classes)
    end

    def to_s()
        return ("Unit: " + @subject.to_s)
    end
end

class Class
    include Timeslot

    attr_reader :subject, :session, :session_ID, :time_start, :time_end, :place

    def initialize(subject, session, session_ID, time_start, time_end, place)
        @subject = subject
        @session = session
        @session_ID = session_ID
        @time_start = to_time(time_start) #Here
        @time_end = to_time(time_end) #Here
        @place = place
    end

    def clash?(class2)
        if (@time_start["date"] != class2.time_start["date"]) && !class2.time_start["date"].nil?
            return false
        elsif (@time_start["hour"] > class2.time_end["hour"])
            return false
        elsif (@time_end["hour"] < class2.time_start["hour"])
            return false
        elsif (@time_start["hour"] == class2.time_end["hour"]) && (@time_start["min"] >= class2.time_end["min"])
            return false
        elsif (@time_end["hour"] == class2.time_start["hour"]) && (@time_end["min"] <= class2.time_start["min"])
            return false
        else
            return true
        end
    end

    def to_s()
        return (@subject.to_s + " - " + @session.to_s + " - " + @time_start.to_s)
    end
end