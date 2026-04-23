class Conversations::PermissionFilterService
  attr_reader :conversations, :user, :account, :include_historical_team_conversations

  def initialize(conversations, user, account, include_historical_team_conversations: false)
    @conversations = conversations
    @user = user
    @account = account
    @include_historical_team_conversations = include_historical_team_conversations
  end

  def perform
    return conversations if user_role == 'administrator'

    accessible_conversations
  end

  private

  def accessible_conversations
    scope = conversations.where(inbox: user.inboxes.where(account_id: account.id))
    return scope unless account_user&.restricted_to_teams?

    team_scoped_conversations = scope.where(team_id: account_user.allowed_team_ids)
    return team_scoped_conversations unless include_historical_team_conversations

    historical_team_conversation_ids = scope.select do |conversation|
      conversation.associated_with_any_team?(account_user.allowed_team_ids)
    end.map(&:id)

    team_scoped_conversations.or(scope.where(id: historical_team_conversation_ids))
  end

  def account_user
    AccountUser.find_by(account_id: account.id, user_id: user.id)
  end

  def user_role
    account_user&.role
  end
end

Conversations::PermissionFilterService.prepend_mod_with('Conversations::PermissionFilterService')
