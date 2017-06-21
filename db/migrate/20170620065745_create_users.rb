class CreateUsers < ActiveRecord::Migration
  def change
    create_table :users do |t|
      t.string :name
      t.integer :partner_id
      t.integer :secret_santa_id
      t.integer :previous_secret_santa_id
      t.boolean :active, default: true

      t.timestamps null: false
    end

    add_index :users, :name, unique: true
    add_index :users, :secret_santa_id, unique: true
  end
end
