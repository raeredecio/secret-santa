class User < ActiveRecord::Base
	belongs_to :secret_santa, :class_name => 'User'
	belongs_to :previous_secret_santa, :class_name => 'User'
	belongs_to :partner, :class_name => 'User'

	validates_presence_of :name
	validates_uniqueness_of :name, :case_sensitive => false #name uniqueness is not case sensitive
	validates_uniqueness_of :secret_santa_id, :allow_nil => true #can only have 1 santa
	validate :new_santa_constraint, on: :create #custom validation is for on create only, user can only update "active" manually; secret santa assignment logic is in transaction so it's tricky

	accepts_nested_attributes_for :partner, :reject_if => lambda { |x| x[:name].blank? } #do not create if nest is not filled up

	scope :active, -> { where(active: true) } #active means people who want to participate in next secret santa
	scope :possible_santas, lambda { |user|  #all possible santas (not partner, not self, not previous)
		active.where('id not in (?)', [user.id, user.previous_secret_santa_id, user.partner_id].reject(&:nil?))
	}
	scope :available_possible_santas, lambda { |user| #all possible santas (not partner, not self, not previous), who are not yet taken by other people
		active.where('id not in (?)', (User.pluck(:secret_santa_id) + [user.id, user.previous_secret_santa_id, user.partner_id]).uniq.reject(&:nil?))
	}

	after_create :update_partner #callback so partner's partner_id is also updated

	#custom validation
	def new_santa_constraint
		#make sure new santa is not same as old santa
		if previous_secret_santa_id && previous_secret_santa_id == secret_santa_id
			errors.add(:secret_santa_id, "can't be same as previous")
		end

		#make sure santa is not same as partner
		if partner_id && partner_id == secret_santa_id
			errors.add(:secret_santa_id, "can't be same as partner")
		end

		#for creation on nested attribute; make sure name and partner name is not the same
		if partner && partner.try(:name) == name
			errors.add(:name, "cannot have the same name as partner")
		end
	end

	#callback so partner's partner_id is also updated
	def update_partner
		partner.update(partner_id: self.id) if partner
	end

	def partner_name
		partner.try(:name)
	end

	#giftee is the one you're supposed to give a gift to
	def previous_giftee
		User.find_by(previous_secret_santa_id: self.id).try(:name)
	end

	def current_giftee
		User.find_by(secret_santa_id: self.id).try(:name)
	end

	#assign a santa based on the 3 constraints
	def assign_santa
		#get random santa from available valid santa pool
		random_santa = User.available_possible_santas(self).order("RANDOM()").limit(1).first
		
		if random_santa
			self.update(secret_santa: random_santa) #take if found one
			return true
		#if no valid santa is found
		else
			#if there is only 3 or less people participating, no possible values can be made anymore
			if User.active.count > 3
				possible_santa = User.possible_santas(self).order("RANDOM()").limit(1).first #get possible santa, even if taken
				user = User.find_by(secret_santa: possible_santa) #get user who has that santa
				user.update(secret_santa_id: nil) #remove person's santa
				self.update(secret_santa: possible_santa) #put it in current user's santa
				user.assign_santa #newly "orphaned" user is assigned a santa

				return true #everyone has found a valid match
			else
				return false #finding a partner for all has failed
			end
		end
	end

	#every new round, transfer previous santa to other column and make secrent_santa column available
	def self.prepare_for_new_santas
		sql = "UPDATE users SET previous_secret_santa_id = secret_santa_id, secret_santa_id = NULL"
		ActiveRecord::Base.connection.execute(sql)
	end

	#method for assigning valid santa to everyone
	def self.assign_secret_santas
		#catch exception in transaction (when no valid combination is possible)
		begin
			User.transaction do #use transaction so rollback is possible for a failed round
				User.prepare_for_new_santas			
				User.active.order("RANDOM()").each do |user|
					success = user.assign_santa

					if !success
						raise("Cannot create any more valid combination.") #possible failure for <= 3 participants
					end
				end
			end
		rescue RuntimeError => e
			msg = {status: :error, message: e.message}
		else
			msg = {status: :success, message: "Success! Check out the participant list page to see your new giftee."}
		end

		return msg
	end

	#returns a summary of User table
	def self.get_summary_csv
		str = ["Name", "Partner Name", "Previous Secret Santa", "Current Secret Santa", "Previous Giftee", "Current Giftee"].join(",") + "\n" 
		#look by batch in case of high user volume
		User.find_each(batch_size: 1000) do |user| 
		  str << [user.name,user.partner_name, user.previous_secret_santa.try(:name), user.secret_santa.try(:name), user.previous_giftee, user.current_giftee].map{|x| "\"#{x}\""}.join(",")+"\n"  
		end

		return str
	end
end
