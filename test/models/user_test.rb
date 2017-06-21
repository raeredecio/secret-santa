require 'test_helper'

class UserTest < ActiveSupport::TestCase
  	test "should always have a name" do
  		user = User.new
	  	assert_not user.save, "saved without a name"
	end

	test "previous secret santa cannot be same as previous secret santa" do
		user = User.new(name:"John Doe", previous_secret_santa_id:1, secret_santa_id:1)
		assert_not user.save, "saved with Santa same as last year"

		prev_santa = User.create(name:"John")
		user = User.create(name:"Jane", previous_secret_santa: prev_santa)
		User.assign_secret_santas
		assert_not_equal user.secret_santa_id, prev_santa.id, "prev Santa assigned to current again"
	end

	test "partner cannot be same as secret santa" do
		user = User.new(name:"John Doe", partner_id:1, secret_santa_id:1)
		assert_not user.save, "saved with Santa same as partner"

		partner = User.create(name:"John")
		user = User.create(name:"Jane", partner: partner)
		User.assign_secret_santas
		assert_not_equal user.secret_santa_id, partner.id, "partner became santa"		

	end

	test "non participants cannot join the game" do
		User.create(name:"John")
		User.create(name:"Jane")
		User.create(name:"Johnny")
		user = User.create(name:"Jack", active: false)
		User.assign_secret_santas
		assert_nil user.secret_santa_id, "Non participant was assigned a santa"
		assert_nil User.where(secret_santa_id:user.id).first, "Non participant was assigned as a santa"
	end




end
