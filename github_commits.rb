require 'json'
require 'pry'
require 'date'
require 'rest_client'
require 'highline/import'

def get_password
  begin
    raw_password = File.open('github.txt', 'r') {|f| f.read}
    password = raw_password.chomp
  rescue
    password = ask('Enter Github password: ') {|q| q.echo=false}
  end
  return password
end

def repo_names user, password
  url = "https://#{user}:#{password}@api.github.com/user/repos"
  resp = RestClient.get url, :accept => :json
  parsed = JSON.parse(resp)
  parsed.collect {|repo| repo['name']}
end

def extract_pagination_link link_text
  links = link_text.split
  next_link_text = links.each_slice(2).select{|l, r| r =~ /next/}.flatten.first
  next_link_text.scan(/\?([^>]*)>;/)[0][0] if next_link_text
end

def commit_list user, password, repo, pagination = nil
  url = "https://#{user}:#{password}@api.github.com/repos/#{user}/#{repo}/commits"
  url += "?per_page=100"
  url += "&#{pagination}" if pagination
  resp = RestClient.get url, :accept => :json
  parsed = JSON.parse(resp)
  link_header = resp.headers[:link]
  next_page = extract_pagination_link link_header if link_header
  parsed += commit_list(user, password, repo, next_page) if next_page
  parsed.reject! {|commit| commit['author'].nil? or commit['author']['login'] != user}
  return parsed
end

def formatted_weeknum date
  "#{date.year} - #{'%02i' % date.cweek}"
end

def weekly_total all_commits
  weekly = Hash.new(0)
  all_commits.sort_by! {|c| Date.parse c['commit']['author']['date']}
  dates = all_commits.collect {|c| Date.parse c['commit']['author']['date']}
  dates.each {|d| weekly[formatted_weeknum(d)] += 1}
  date = Date.parse all_commits.first['commit']['author']['date']
  while true do
    weeknum_string = formatted_weeknum date
    puts "#{weeknum_string}, #{weekly[weeknum_string]}"
    date += 7
    break if date > Date.today
  end
end

def all_commits repos, user, password
  collected = []
  repos.each {|repo| collected += commit_list user, password, repo}
  return collected
end

def main
  user = "christoomey"
  password = get_password
  repos = repo_names(user, password).reject! {|repo| repo == "all_your_base"}
  collected = all_commits repos, user, password
  weekly_total collected
end

main
