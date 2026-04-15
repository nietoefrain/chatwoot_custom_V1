class Conversations::AssignmentService
  def initialize(conversation:, assignee_id:, assignee_type: nil)
    @conversation = conversation
    @assignee_id = assignee_id
    @assignee_type = assignee_type
  end

  def perform
    agent_bot_assignment? ? assign_agent_bot : assign_agent
  end

  private

  attr_reader :conversation, :assignee_id, :assignee_type

  def assign_agent
    conversation.team = target_team_for_assignee if should_update_team_for_assignee?
    conversation.assignee = assignee
    conversation.assignee_agent_bot = nil
    conversation.save!
    assignee
  end

  def assign_agent_bot
    return unless agent_bot

    conversation.assignee = nil
    conversation.assignee_agent_bot = agent_bot
    conversation.save!
    agent_bot
  end

  def assignee
    @assignee ||= conversation.account.users.find_by(id: assignee_id)
  end

  def assignee_teams
    @assignee_teams ||= conversation.account.teams.joins(:team_members).where(team_members: { user_id: assignee.id })
  end

  def target_team_for_assignee
    return conversation.team if conversation.team.present? && assignee_teams.exists?(id: conversation.team_id)

    assignee_teams.first
  end

  def should_update_team_for_assignee?
    return false if assignee.blank?
    return false if assignee_teams.blank?

    target_team_for_assignee.present? && target_team_for_assignee != conversation.team
  end

  def agent_bot
    @agent_bot ||= AgentBot.accessible_to(conversation.account).find_by(id: assignee_id)
  end

  def agent_bot_assignment?
    assignee_type.to_s == 'AgentBot'
  end
end
