require 'json'
require 'date'
require 'pry'
require 'highline/import'
require 'rest_client'

def get_token
  begin
    raw_token = File.open('heroku.txt', 'r') {|f| f.read}
    token = raw_token.chomp
  rescue
    token = ask('Enter Heroku API token: ') {|q| q.echo=false}
  end
  return token
end

def request_releases app, token
  url = "https://:#{token}@api.heroku.com/apps/#{app}/releases"
  resp = RestClient.get url, {:accept => :json}
  JSON.parse(resp).reverse
end

def app_names token
  url = "https://:#{token}@api.heroku.com/apps"
  resp = RestClient.get url, {:accept => :json}
  app_datails = JSON.parse(resp)
  app_datails.collect {|a| a["name"]}
end

def formatted_weeknum date
  "#{date.year} - #{'%02i' % date.cweek}"
end

def weekly_total releases
  weekly = Hash.new(0)
  releases.sort_by! {|rel| Date.parse(rel['created_at'])}
  dates = releases.collect {|rel| Date.parse rel['created_at']}
  dates.each {|d| weekly[formatted_weeknum(d)] += 1}
  date = Date.parse releases.first['created_at']
  while true do
    weeknum_string = formatted_weeknum date
    puts "#{weeknum_string}, #{weekly[weeknum_string]}"
    date += 7
    break if date > Date.today
  end
end

def collect_releases apps, token
  apps.collect {|app| request_releases app, token}.flatten
end

def main
  token = get_token
  apps = app_names token
  releases = collect_releases apps, token
  weekly_total releases
end

main
