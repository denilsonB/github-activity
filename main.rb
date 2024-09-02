require 'net/http'
require 'json'
require 'uri'

username = gets.chomp

uri = URI("https://api.github.com/users/#{username}/events")


request = Net::HTTP::Get.new(uri)
request["Accept"] = "application/vnd.github.v3+json"
request["User-Agent"] = "github-activity"


response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
  http.request(request)
end

response_body = JSON.parse(response.body)

if response.code.to_i == 404 || response_body.is_a?(Hash) && response_body["message"] == "Not Found"
  puts "User '#{username}' not found."
elsif response.code.to_i != 200
  puts "Failed to retrieve events. HTTP Status Code: #{response.code}. Message: #{response_body['message']}"
else
  commit_counts = Hash.new(0)

  events = response_body
  events.each do |event|
    if event["type"] == "PushEvent"
      repo_name = event["repo"]["name"]
      commit_count = event["payload"]["commits"].size
      commit_counts[repo_name] += commit_count
    end
    if event['type'] == 'WatchEvent'
      p "Starred " + event["repo"]["name"]
    end
  end

  commit_counts.each do |repo_name, total_commits|
    puts "Pushed #{total_commits} commits to #{repo_name}"
  end

  puts "No push events found for '#{username}'." if commit_counts.empty?
end