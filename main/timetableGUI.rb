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
      formatted_data << [row[0], row[1], row[2], to_time(row[3]), to_time(row[4]), row[5]]
    end

    return formatted_data
  end

  def read_input()
    compare_min = []
    compare_max = []
    @input.each do |a_class|
      compare_min << to_decimal(a_class[3])
      compare_max << to_decimal(a_class[4])
    end
    start_time = compare_min.min()
    end_time = compare_max.max()
    return start_time, end_time
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
  Gosu.draw_rect(0, 0, Dimension::WIN_WIDTH, Dimension::WIN_HEIGHT, @background, ZOrder::BACKGROUND, mode=:default)

  #Draw grid for timetable
  #Draw horizontal bars
  Gosu.draw_quad(Dimension::COL_WIDTH*1 - Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*1 + Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*1 + Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*1 - Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(Dimension::COL_WIDTH*2 - Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*2 + Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*2 + Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*2 - Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(Dimension::COL_WIDTH*3 - Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*3 + Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*3 + Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*3 - Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(Dimension::COL_WIDTH*4 - Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*4 + Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*4 + Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*4 - Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  Gosu.draw_quad(Dimension::COL_WIDTH*5 - Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*5 + Dimension::BORDER_WIDTH/2, 0, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*5 + Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, Dimension::COL_WIDTH*5 - Dimension::BORDER_WIDTH/2, Dimension::WIN_HEIGHT, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  #Draw vertical bars
  Gosu.draw_quad(0, Dimension::ROW0_HEIGHT - Dimension::BORDER_WIDTH/2, Color::COLOR_THEME_PRIMARY, Dimension::WIN_WIDTH, Dimension::ROW0_HEIGHT - Dimension::BORDER_WIDTH/2, Color::COLOR_THEME_PRIMARY, Dimension::WIN_WIDTH, Dimension::ROW0_HEIGHT + Dimension::BORDER_WIDTH/2, Color::COLOR_THEME_PRIMARY, 0, Dimension::ROW0_HEIGHT + Dimension::BORDER_WIDTH/2, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  
  #Draw diagonal line
  #Gosu.draw_quad(0, 0, COLOR_THEME_PRIMARY, COL_WIDTH + BORDER_WIDTH/2, 0, COLOR_THEME_SECONDARY, COL_WIDTH + BORDER_WIDTH/2, ROW0_HEIGHT + BORDER_WIDTH/2, COLOR_THEME_TERTIARY, 0, ROW0_HEIGHT + BORDER_WIDTH/2, COLOR_THEME_QUATERNARY, ZOrder::MIDDLE, mode=:default)

  #Draw table headers
  #Draw column headers
  @font.draw_text("Monday", Dimension::COL_WIDTH*1.28, (Dimension::ROW0_HEIGHT-Dimension::TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, Color::COLOR_THEME_PRIMARY)
  @font.draw_text("Tuesday", Dimension::COL_WIDTH*2.26, (Dimension::ROW0_HEIGHT-Dimension::TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, Color::COLOR_THEME_PRIMARY)
  @font.draw_text("Wednesday", Dimension::COL_WIDTH*3.16, (Dimension::ROW0_HEIGHT-Dimension::TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, Color::COLOR_THEME_PRIMARY)
  @font.draw_text("Thursday", Dimension::COL_WIDTH*4.24, (Dimension::ROW0_HEIGHT-Dimension::TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, Color::COLOR_THEME_PRIMARY)
  @font.draw_text("Friday", Dimension::COL_WIDTH*5.34, (Dimension::ROW0_HEIGHT-Dimension::TEXT_SIZE)/2, ZOrder::TOP, 1.0, 1.0, Color::COLOR_THEME_PRIMARY)
end



class TimetableGUI < Gosu::Window
  attr_reader :input
  
  def initialize()
    super(Dimension::WIN_WIDTH, Dimension::WIN_HEIGHT, true)
    @background = Gosu::Color::WHITE
    @button_border = Gosu::Color::WHITE
    @font = Gosu::Font.new(Dimension::TEXT_SIZE)
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

    Dimension::FILE.input.each do |a_class|
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
  attr_reader :x, :y, :width, :height, :time_start, :time_end, :info_font, :font_color

  include Timeslot

  def assign_date()
    case @date
    when "mon"
      @x = Dimension::COL_WIDTH*1
    when "tue"
      @x = Dimension::COL_WIDTH*2
    when "wed"
      @x = Dimension::COL_WIDTH*3
    when "thu"
      @x = Dimension::COL_WIDTH*4
    else
      @x = Dimension::COL_WIDTH*5
    end
  end

  def assign_color()
    for i in 0..(Dimension::FILE.subject_list.length - 1)
      if Dimension::FILE.subject_list[i] == @subject
        i %= 3
        @block_color = Color::COLOR_PICKER[i]
        break
      end
    end
  end

  def initialize(subject, session, session_ID, time_start, time_end, place)
    @time_font = Gosu::Font.new(Dimension::TEXT_SIZE.to_i)
    @info_font = Gosu::Font.new(Dimension::TEXT_SIZE/2.to_i)
    @font_color = Color::COLOR_THEME_PRIMARY

    @date = time_start["date"]
    self.assign_date()

    @subject = subject
    @session = session
    @session_ID = session_ID
    @place = place
    @time_start = to_decimal(time_start)
    @time_end = to_decimal(time_end)

    self.assign_color()

    @width = Dimension::COL_WIDTH
    @y = @time_start*Dimension::ROW_HEIGHT - Dimension::STARTTIME*Dimension::ROW_HEIGHT + Dimension::ROW0_HEIGHT
    @height = (@time_end - @time_start)*Dimension::ROW_HEIGHT

    self.draw_cell()
  end

  #Insert each class onto timetable
  def draw_cell()
    #draw_rect(startingX, startingY, width, height, color, ZOrder, mode):
    Gosu.draw_rect(@x, @y, @width, @height, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
    Gosu.draw_rect(@x + Dimension::BORDER_WIDTH/2, @y + Dimension::BORDER_WIDTH/2, @width - Dimension::BORDER_WIDTH, @height - Dimension::BORDER_WIDTH, @block_color, ZOrder::TOP, mode=:default)
  end

  def mouse_over(mouse_x, mouse_y)
    return (mouse_x >= @x && mouse_x <= @x + @width) && (mouse_y >= @y && mouse_y <= @y + @height)
  end

  def show_info(font_color)
    #Draw time
    @time_font.draw_text("#{to_display(@time_start)} - #{to_display(@time_end)}", Dimension::COL_WIDTH/8, @y + (@height-Dimension::TEXT_SIZE/2)/2, ZOrder::TOP, 1.0, 1.0, font_color)
    #Draw info
    @info_font.draw_text("#{@subject} - #{@session}#{@session_ID}", @x + 10, @y + (@height-Dimension::TEXT_SIZE/2)/2 - Dimension::TEXT_SIZE/3, ZOrder::TOP, 1.0, 1.0, font_color)
    @info_font.draw_text("#{@place}", @x + 10, @y + (@height-Dimension::TEXT_SIZE/2)/2 + Dimension::TEXT_SIZE/3, ZOrder::TOP, 1.0, 1.0, font_color)
  end

  def show_info_emphasis()
    self.show_info(Gosu::Color::BLACK)
    Gosu.draw_rect(@x - Dimension::BORDER_WIDTH/2, @y - Dimension::BORDER_WIDTH/2, @width + Dimension::BORDER_WIDTH, @height + Dimension::BORDER_WIDTH, Color::COLOR_THEME_PRIMARY, ZOrder::MIDDLE, mode=:default)
  end
end