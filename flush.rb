#!/usr/bin/env ruby

require 'csv'
require 'http'


BATCH_SIZE = 100


def prompt_for_api_key
  print "Please enter your Klaviyo API key: "
  $stdin.gets.chomp
end

def prompt_for_params
  print "What Klaviyo list ID should these be removed from? "
  list_id = $stdin.gets.chomp

  print "What's the name of the CSV file? "
  csv_file = $stdin.gets.chomp
  [list_id, csv_file]
end

def confirm_params(list_id, csv_file)
  puts
  puts "List ID: #{list_id}"
  puts "CSV file: #{csv_file}"
  puts "\e[31mYou are about to delete the emails from #{csv_file} from list #{list_id}.\e[0m"
  print "Is this correct? (type yes to continue, press enter to abort)  "

  answer = $stdin.gets.chomp
  if answer == "yes"
    puts "Here we go!"
  else
    puts "Changed your mind, eh? Until we meet again..."
    exit 1
  end
  puts
end

def get_email_batches(csv_file, batch_size)
  CSV.read(csv_file, headers: false)
     .map(&:first)
     .each_slice(batch_size)
     .to_a.map do |batch|
       # Don't keep anything that doesn't have an @ in it, like a CSV column header
       batch.compact
            .select {|email| email =~ /@/}
            .map(&:strip)
     end
end

def confirm_deletion(list_id, email_batches)
  puts
  puts "About to delete the following batches of users from list #{list_id}"
  email_batches.each { |batch| puts "= #{batch.to_s}" }
  puts
  puts "_" * 72

  # Get confirmation
  print "Are you SURE you want to continue? (type yes to continue, press enter to abort)  "

  answer = $stdin.gets.chomp
  if answer == "yes"
    puts "Hold onto yer butts!"
  else
    puts "I don't blame you. Until we meet again..."
    exit 1
  end
  puts
end

def fail(res)
  system('say "Houston, we have a problem, beep, beep, beep, poop, ack"')
  puts 
  puts "🔥" * 20
  puts "  Houston, we have a problem! 🚀💥"
  puts "🔥" * 20
  puts
  puts "Response code: #{res.code}"
  puts "Response: #{res.to_s}"
  puts
  exit 2
end

def delete_batches(email_batches, list_id, api_key)
  if ENV['TEST']
    puts "TEST MODE ENABLED"
    puts "WE'RE JUST DOING A DRY RUN, HERE!"
  end

  email_batches.each_with_index do |batch, i|
    next if batch.empty?

    print "- #{batch.to_s}"

    params = {
      :api_key => api_key,
      :emails => batch,
    }

    # Call Klaviyo
    klaviyo_uri = "https://a.klaviyo.com/api/v2/list/#{list_id}/members"
    
    if ENV['TEST']
      res = HTTP.get(klaviyo_uri, :params => params)
    else
      res = HTTP.delete(klaviyo_uri, :params => params)
    end

    puts "\e[36m [#{res.code}]\e[0m" 

    # Attempt to handle rate limiting responses from Klaviyo. Their docs don't spell
    # things out, so hopefully they're following standards.
    # https://www.klaviyo.com/docs/api/v2/lists
    # https://developer.mozilla.org/en-US/docs/Web/HTTP/Status/429
    if res.code == 429
      retry_delay = res.headers['Retry-After'] || 5
      puts
      puts "Klaviyo rate limit reached. Waiting for #{retry_delay} seconds before trying again."
      puts
      sleep retry_delay
      redo
    elsif res.code != 200
      fail(res)
    end
  end
end

def success!
  puts
  puts
  puts "\e[1m\e[36mIf you are reading this, I guess things went okay? ¯\_(ツ)_/¯\e[0m\e[0m"
end


api_key = prompt_for_api_key
list_id, csv_file = prompt_for_params
confirm_params(list_id, csv_file)
email_batches = get_email_batches(csv_file, BATCH_SIZE)
confirm_deletion(list_id, email_batches)
delete_batches(email_batches, list_id, api_key)
success!

