class AddIsSupportTeamToTeams < ActiveRecord::Migration[7.1]
  SUPPORT_TEAM_SLUGS = %w[soporte support].freeze

  def up
    add_column :teams, :is_support_team, :boolean, default: false, null: false

    Team.reset_column_information
    Team.find_each do |team|
      next unless SUPPORT_TEAM_SLUGS.include?(team.name.to_s.parameterize)

      team.update_columns(is_support_team: true)
    end
  end

  def down
    remove_column :teams, :is_support_team
  end
end
