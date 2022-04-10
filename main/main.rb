require './scheduler'
require './timetableGUI'

#Screen dimensions
module Dimension
    WIN_WIDTH = 1920
    WIN_HEIGHT = 1080
    COL_WIDTH = WIN_WIDTH/6
    ROW0_HEIGHT = WIN_HEIGHT/8
    TEXT_SIZE = ROW0_HEIGHT/3
    BORDER_WIDTH = TEXT_SIZE/10
    #Modify below line to take in arbitrary subjects
    SCHEDULER = Scheduler.new("cos10009.csv", "cos10026.csv", "art10004.csv", "tne10006.csv")
    FILE = InputReader.new(SCHEDULER.file_name)
    STARTTIME, ENDTIME = FILE.read_input()
    ROW_HEIGHT = (WIN_HEIGHT - ROW0_HEIGHT)/(ENDTIME - STARTTIME)
end

#Color theme
module Color
    COLOR_THEME_PRIMARY = Gosu::Color.new(124, 99, 84)
    COLOR_THEME_SECONDARY = Gosu::Color.new(165, 171, 175)
    COLOR_THEME_TERTIARY = Gosu::Color.new(249, 251, 178)
    COLOR_THEME_QUATERNARY = Gosu::Color.new(227, 233, 194)
    COLOR_PICKER = [COLOR_THEME_SECONDARY, COLOR_THEME_TERTIARY, COLOR_THEME_QUATERNARY]
end

TimetableGUI.new.show()