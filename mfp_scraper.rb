require 'open-uri'
require 'nokogiri'
require 'date'

def get_calories user, date
  doc = get_page user, date, 'food'
  totals = doc.css("tr.total")[0]
  calories_str = totals.children.text.split[1]
  calories = Integer calories_str.delete(",")
end

def get_exercise user, date
  doc = get_page user, date, 'exercise'
  exercise = Integer doc.css('span.soFar')[2].text
end

def get_water user, date
  doc = get_page user, date, 'food'
  raw_text = doc.css(".water-counter p").children.text
  water_count = Integer raw_text.gsub(/[up|down]/i, "").strip
end

def get_page user, date, page
  str_format = "%Y-%m-%d"
  date_str = date.strftime(str_format)
  url = "http://www.myfitnesspal.com/#{page}/diary/#{user}?date=#{date_str}"
  doc = Nokogiri::HTML(open(url))
end

def main
  user = "christoomey"
  today = Date.today
  puts sprintf "%10s%10s%10s%10s", "Date", "Calories", "Exercise", "Water"
  puts "-"*45
  (0..10).each do |i|
    date = (today - i)
    calories = get_calories user, date
    exercise = get_exercise user, date
    water = get_water user, date
    date_str = date.strftime("%Y-%m-%d")
    row_str = sprintf "%10s%10s%10s%10s", date_str, calories, exercise, water
    puts row_str
  end
end

main
