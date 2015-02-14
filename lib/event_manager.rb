require 'csv'
require 'sunlight/congress'
require 'erb'

Sunlight::Congress.api_key = "e179a6973728c4dd3fb1204283aaccb5"

def clean_zipcode(zipcode)
	zipcode.to_s.rjust(5, "0")[0..4]
end

def clean_phone_numbers(phone_number)
	number = phone_number.to_s.scan(/\w/).join('')
	if number.chr[0] == "1"
		number = number.chr[1..-1]
		if number.length != 10
			number = 'bad'
		end
	elsif number.length != 10
		number = 'bad'
	else 
		puts number
	end
end

def legislators_by_zipcode(zipcode)
	legislators = Sunlight::Congress::Legislator.by_zipcode(zipcode)	
end

def save_thank_you_letters(id, form_letter)
	Dir.mkdir('output') unless Dir.exists?('output')

	filename = 'output/thanks_#{id}.html'

	File.open(filename, 'w') do |file|
		file.puts form_letter
	end
end

def clean_phone_numbers(phone_number)
	number = phone_number.to_s.gsub(/\D/, '')
	if number.length == 10
		number
	elsif number.length == 11 && number[0] == "1"
		number = number[1..-1]
	else
		number = 'N/A'
	end
end

def time_targetting_hour(time)
	target_hour = time.select { |hour, reg| reg == time.values.max}
	target_hour.keys.join(", ")
end

def time_targetting_day(day)
	target_day = day.select { |day, reg| reg == day.values.max}
	days = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday']
	target_day = target_day.keys
	days[target_day[0]]
end


puts "EventManager Initialized!"

contents = CSV.open 'event_attendees.csv', headers: true, header_converters: :symbol

template_letter = File.read "form_letter.erb"
erb_template = ERB.new template_letter

hour_counter = Hash.new(0)
day_counter = Hash.new(0)
contents.each do |row|
	id = row[0]
	name = row[:first_name]

	phone_number = clean_phone_numbers(row[:homephone])

	zipcode = clean_zipcode(row[:zipcode])

	legislators = legislators_by_zipcode(zipcode)

	form_letter = erb_template.result(binding)

	save_thank_you_letters(id, form_letter)
	
	time = DateTime.strptime(row[:regdate], "%m/%d/%y %k:%M")
	hour_counter[time.hour] += 1
	day_counter[time.wday] += 1
end

puts "The peak registration hours are #{time_targetting_hour(hour_counter)}"
puts "The peak registration day is #{time_targetting_day(day_counter)}"