require 'csv' #for generating csv

class UsersController < ApplicationController
	before_action :set_user, only: [:show, :edit, :update]

	def index
	  @users = User.all
	end

	def new
	  @user = User.new
	end

	def create
		@user = User.new(user_params)

	  	if @user.save
	  		msg = "Participant #{@user.name} added."
	  		msg = "Participants #{@user.name} & #{@user.partner_name} added." if @user.partner
	  		flash[:success] = msg
	  		redirect_to user_path(@user)
	  	else
	  		render :new
	  	end
	end

	def update
	    if @user.update(user_params)
	  		flash[:success] = "Participant details updated."
	  		redirect_to user_path(@user)
	  	else
	  		render :edit
	  	end
	end

	#user input CSV. Format: 1st column is name, 2nd column is partner name, not case sensitive
	def upload_csv
		csv_text = open(params[:file].tempfile).read
		success = CsvReader.new(csv_text).process_names

		if success
			flash[:success] = "Successfully uploaded new list of participants."
			redirect_to users_path
		else
			flash[:error] = "Bad CSV uploaded. Please try another"
			redirect_to root_path
		end
	end

	def assign_santas
		result = User.assign_secret_santas
		flash[result[:status]] = result[:message]

		redirect_to get_santas_users_path
	end

	#for downloading user database summary
	def download_csv
		str = User.get_summary_csv

		send_data str, :filename => "participants_summary_#{Time.now.to_i}.csv", :type => "text/csv"
	end

	private 
	  	def set_user
	  		@user = User.find(params[:id])
	  	end

	  	def user_params
	  		params.require(:user).permit(:name, :active, partner_attributes: [:name])
	  	end
end