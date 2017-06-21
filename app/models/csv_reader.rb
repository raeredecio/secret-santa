#for reading user input csv
class CsvReader

	def initialize(csv_text)
		begin
			@csv = CSV.parse(csv_text, :headers => true)
		rescue CSV::MalformedCSVError #check for malformed csv
			@error = true
		end
	end

	#CSV format is 2 columns (name, partner name)
	def process_names
		return false if @error
		User.delete_all #resets participants when you upload csv
		0.upto(@csv.count-1) do |row|
			user_name = @csv[row][0].presence
			next if user_name.nil? #skip bad csv input (no name)

			user = User.find_or_create_by(name: user_name.strip) #make user, prevent duplicate entry

			partner_name = @csv[row][1].presence
			next if partner_name.nil? 

			User.find_or_create_by(name: partner_name.strip, partner: user) #create partner
		end

		return true
	end
end