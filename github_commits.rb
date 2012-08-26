require 'json'
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
  url += "?#{pagination}" if pagination
  resp = RestClient.get url, :accept => :json
  parsed = JSON.parse(resp)
  next_page = extract_pagination_link resp.headers[:link]
  parsed += commit_list(user, password, repo, next_page) if next_page
  return parsed
end

def main
  user = "christoomey"
  password = get_password
  repos = repo_names user, password
  repo = "weighted"
  commits = commit_list user, password, repo
  puts "seems there are #{commits.length} commits in #{repo}"
end

main
