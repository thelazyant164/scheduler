require 'rubygems'
require 'gosu'
require 'csv'
require './timeslot'
require './scheduler'

module ZOrder
  BACKGROUND, MIDDLE, TOP = *0..2
end

class InputReader
  include Timeslot

  attr_reader :input, :subject_list

  def initialize(file_name)
    @input = read_timetable(file_name)
    self.list_subject()
  end

  def read_timetable(file_name)
    formatted_data = Array.new()
    # #Open info CSV files and read into arrays of rows
    raw_data = CSV.parse(File.read(file_name), headers: true)

    #Format data
    raw_data.each do |row|
      formatted_data << [row[0], row[1], row[2], toTime(row[3]), toTime(row[4]), row[5]]
    end

    return formatted_data
  end

  def read_input()
    compareMin = []
    compareMax = []
    @input.each do |a_class|
      compareMin << toDecimal(a_class[3])
      compareMax << toDecimal(a_class[4])
    end
    startTime = compareMin.min()
    endTime = compareMax.max()
    return startTime, endTime
  end

  def list_subject()
    @subject_list = []
    @input.each do |a_class|
      if @subject_list.include?(a_class[0])
        next
      else
        @subject_list << a_class[0]
      end
    end
  end
end

#Draw static timetable frame
def draw_static()
  # Draw background color
  Gosu.draw_rect(0, 0, WIN_WIDTH, WIN_HEIGHT, @background, ZOrder::BACKGROUND, mode=:default)

  #Draw grid for timetable
  #Draw horizontal bars
  Gosu.draw_quad(COL_WIDTH*1 - BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*1 + BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*1 + BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, COL_WIDTH*1 - BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(COL_WIDTH*2 - BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*2 + BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*2 + BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, COL_WIDTH*2 - BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(COL_WIDTH*3 - BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*3 + BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*3 + BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, COL_WIDTH*3 - BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(COL_WIDTH*4 - BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*4 + BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*4 + BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, COL_WIDTH*4 - BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(COL_WIDTH*5 - BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*5 + BORDER_WIDTH/2, 0, COLOR_THEME_PRIMARY, COL_WIDTH*5 + BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, COL_WIDTH*5 - BORDER_WIDTH/2, WIN_HEIGHT, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  #Draw vertical bars
  Gosu.draw_quad(0, ROW0_HEIGHT - BORDER_WIDTH/2, COLOR_THEME_PRIMARY, WIN_WIDTH, ROW0_HEIGHT - BORDER_WIDTH/2, COLOR_THEME_PRIMARY, WIN_WIDTH, ROW0_HEIGHT + BORDER_WIDTH/2, COLOR_THEME_PRIMARY, 0, ROW0_HEIGHT + BORDER_WIDTH/2, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  
  #Draw diagonal line
  #Gosu.draw_quad(0, 0, COLOR_THEME_PRIMARY, COL_WIDTH + BORDER_WIDTH/2, 0, COLOR_THEME_SECONDARY, COL_WIDTH + BORDER_WIDTH/2, ROW0_HEIGHT + BORDER_WIDTH/2, COLOR_THEME_TERTIARY, 0, ROW0_HEIGHT + BORDER_WIDTH/2, COLOR_THEME_QUATERNARY, ZOrder::MIDDLE, mode=:default)

  #Draw table headers
  #Draw column headers
  @font.draw_text("Monday", COL_WIDTH*1.28, (ROW0_HEIGHT-TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, COLOR_THEME_PRIMARY)
  @font.draw_text("Tuesday", COL_WIDTH*2.26, (ROW0_HEIGHT-TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, COLOR_THEME_PRIMARY)
  @font.draw_text("Wednesday", COL_WIDTH*3.16, (ROW0_HEIGHT-TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, COLOR_THEME_PRIMARY)
  @font.draw_text("Thursday", COL_WIDTH*4.24, (ROW0_HEIGHT-TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, COLOR_THEME_PRIMARY)
  @font.draw_text("Friday", COL_WIDTH*5.34, (ROW0_HEIGHT-TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, COLOR_THEME_PRIMARY)
end



class TimetableGUI < Gosu::Window
  attr_reader :input
  
  def initialize()
    super(WIN_WIDTH, WIN_HEIGHT, true)
    @background = Gosu::Color::WHITE
    @button_border = Gosu::Color::WHITE
    @font = Gosu::Font.new(TEXT_SIZE)
    @classes = []
    @locs = [60,60]
    #Only redraw when necessary
    @redraw = false
    @first_time = true
    #List containing currently selected class
    @show_info = []
    @stick_info = []
  end

  def draw()
    draw_static()

    FILE.input.each do |a_class|
      new_class = ClassBlock.new(*a_class)
      if @first_time
        @classes << new_class
      end
    end
    @first_time = false

    if @redraw
      @show_info.each do |a_class|
        a_class.show_info(a_class.font_color)
      end
    end

    @stick_info.each do |a_class|
        a_class.show_info_emphasis()
    end
  end

  def update()
    @classes.each do |a_class|
      if a_class.mouse_over(mouse_x, mouse_y)
        @show_info = []
        @redraw = true
        @show_info << a_class
        break
      else
        @show_info = []
        @redraw = false
      end
    end
  end

  def needs_cursor?()
    return true
  end

  def needs_redraw()
    return @redraw
  end

  #Show info for each class when selected
  def button_down(id)
    case id
    when Gosu::MsLeft
      @classes.each do |a_class|
        if a_class.mouse_over(mouse_x, mouse_y) && !@stick_info.include?(a_class)
          @stick_info << a_class
          break
        elsif a_class.mouse_over(mouse_x, mouse_y) && @stick_info.include?(a_class)
          @stick_info.delete(a_class)
        end
      end
    else
      super(id)
    end
  end
end

class ClassBlock
  attr_reader :x, :y, :width, :height, :timeStart, :timeEnd, :info_font, :font_color

  include Timeslot

  def assign_date()
    case @date
    when "mon"
      @x = COL_WIDTH*1
    when "tue"
      @x = COL_WIDTH*2
    when "wed"
      @x = COL_WIDTH*3
    when "thu"
      @x = COL_WIDTH*4
    else
      @x = COL_WIDTH*5
    end
  end

  def assign_color()
    for i in 0..(FILE.subject_list.length - 1)
      if FILE.subject_list[i] == @subject
        i %= 3
        @block_color = COLOR_PICKER[i]
        break
      end
    end
  end

  def initialize(subject, session, sessionID, timeStart, timeEnd, place)
    @time_font = Gosu::Font.new(TEXT_SIZE.to_i)
    @info_font = Gosu::Font.new(TEXT_SIZE/2.to_i)
    @font_color = COLOR_THEME_PRIMARY

    @date = timeStart["date"]
    self.assign_date()

    @subject = subject
    @session = session
    @sessionID = sessionID
    @place = place
    @timeStart = toDecimal(timeStart)
    @timeEnd = toDecimal(timeEnd)

    self.assign_color()

    @width = COL_WIDTH
    @y = @timeStart*ROW_HEIGHT - STARTTIME*ROW_HEIGHT + ROW0_HEIGHT
    @height = (@timeEnd - @timeStart)*ROW_HEIGHT

    self.draw_cell()
  end

  #Insert each class onto timetable
  def draw_cell()
    #draw_rect(startingX, startingY, width, height, color, ZOrder, mode):
    Gosu.draw_rect(@x, @y, @width, @height, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
    Gosu.draw_rect(@x + BORDER_WIDTH/2, @y + BORDER_WIDTH/2, @width - BORDER_WIDTH, @height - BORDER_WIDTH, @block_color, ZOrder::TOP, mode=:default)
  end

  def mouse_over(mouse_x, mouse_y)
    return (mouse_x >= @x && mouse_x <= @x + @width) && (mouse_y >= @y && mouse_y <= @y + @height)
  end

  def show_info(font_color)
    #Draw time
    @time_font.draw_text("#{toDisplay(@timeStart)} - #{toDisplay(@timeEnd)}", COL_WIDTH/8, @y + (@height-TEXT_SIZE/2)/2, ZOrder::TOP, 1.0, 1.0, font_color)
    #Draw info
    @info_font.draw_text("#{@subject} - #{@session}#{@sessionID}", @x + 10, @y + (@height-TEXT_SIZE/2)/2 - TEXT_SIZE/3, ZOrder::TOP, 1.0, 1.0, font_color)
    @info_font.draw_text("#{@place}", @x + 10, @y + (@height-TEXT_SIZE/2)/2 + TEXT_SIZE/3, ZOrder::TOP, 1.0, 1.0, font_color)
  end

  def show_info_emphasis()
    self.show_info(Gosu::Color::BLACK)
    Gosu.draw_rect(@x - BORDER_WIDTH/2, @y - BORDER_WIDTH/2, @width + BORDER_WIDTH, @height + BORDER_WIDTH, COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  end
end