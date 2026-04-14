class AddAllowedTeamIdsToAccountUsers < ActiveRecord::Migration[7.1]
  def change
    add_column :account_users, :allowed_team_ids, :bigint, array: true, default: [], null: false
  end
end
