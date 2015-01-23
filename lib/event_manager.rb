require "csv"
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
  zipcode.to_s.rjust(5,"0")[0..4]
end

def clean_phonenumber(homephone)
  clean_num = homephone.gsub(/-|\.|\(|\)|\s+/, '')
  if clean_num.length == 10
  	clean_num
  elsif clean_num.length == 11 && clean_num[0] == "1"
  	clean_num.slice!(0)
  else
  	clean_num = ""
  end
  # Converts phone num into standard format
  clean_num.sub(/(\d{3})(\d{3})(\d{4})/, "\\1-\\2-\\3")
end

def legislators_by_zipcode(zipcode)
  Sunlight::Congress::Legislator.by_zipcode(zipcode)
end

def save_thank_you_letter(id, form_letter)
  Dir.mkdir("output") unless Dir.exists? "output"

  filename = "output/thanks_#{id}.html"

  File.open(filename, 'w') do |file|
  	file.puts form_letter
  end
end

def hours_convert(hour)
	if hour > 12
		hour = "#{hour % 12}pm"
	else
		hour = "#{hour}am"
	end
end

def registration_analytics(hash)
  peak_array = ((hash.sort_by { |k, v| v}).reverse)

  puts ""
  puts "Peak registration hours:"
  puts "#{peak_array[0][1]} people signed up at #{hours_convert(peak_array[0][0])}"
  puts "#{peak_array[1][1]} people signed up at #{hours_convert(peak_array[1][0])}"
  puts "#{peak_array[2][1]} people signed up at #{hours_convert(peak_array[2][0])}"
end


puts "EventManager initialized."

contents = CSV.open "event_attendees.csv", headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

registration_hours = Hash.new(0) # Used for registration hours analytics

contents.each do |row|
  id = row[0]
  name = row[:first_name]
  
  phone_number = clean_phonenumber(row[:homephone])
  
  zipcode = clean_zipcode(row[:zipcode])

  legislators = legislators_by_zipcode(zipcode)

  form_letter = erb_template.result(binding)

  # save_thank_you_letter(id, form_letter)

  # Registration hours analytics
  date = row[:regdate]
  format = "%m/%d/%y %H:%M"
  date_time = DateTime.strptime(date, format)
  registration_hours[date_time.hour] += 1

end

registration_analytics(registration_hours)