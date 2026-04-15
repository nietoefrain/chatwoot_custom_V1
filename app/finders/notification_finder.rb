class NotificationFinder
  attr_reader :current_user, :current_account, :params

  RESULTS_PER_PAGE = 15

  def initialize(current_user, current_account, params = {})
    @current_user = current_user
    @current_account = current_account
    @params = params
    set_up
  end

  def notifications
    @notifications.page(current_page).per(RESULTS_PER_PAGE).order(last_activity_at: sort_order)
  end

  def unread_count
    if type_included?('read')
      # If we're including read notifications, filter to unread
      @notifications.where(read_at: nil).count
    else
      # Already filtered to unread notifications, just count
      @notifications.count
    end
  end

  def count
    @notifications.count
  end

  private

  def set_up
    find_all_notifications
    filter_inaccessible_notifications
    filter_snoozed_notifications
    filter_read_notifications
  end

  def find_all_notifications
    @notifications = current_user.notifications.where(account_id: @current_account.id)
  end

  def filter_inaccessible_notifications
    conversation_ids = @notifications.where(primary_actor_type: 'Conversation').distinct.pluck(:primary_actor_id)
    return if conversation_ids.blank?

    conversations = Conversation.where(id: conversation_ids).index_by(&:id)
    visible_conversation_ids = conversation_ids.select do |conversation_id|
      conversation = conversations[conversation_id]
      conversation.present? && conversation_policy(conversation).show?
    end

    @notifications = @notifications.where(primary_actor_type: 'Conversation', primary_actor_id: visible_conversation_ids)
  end

  def filter_snoozed_notifications
    @notifications = @notifications.where(snoozed_until: nil) unless type_included?('snoozed')
  end

  def filter_read_notifications
    @notifications = @notifications.where(read_at: nil) unless type_included?('read')
  end

  def type_included?(type)
    (params[:includes] || []).include?(type)
  end

  def current_page
    params[:page] || 1
  end

  def conversation_policy(conversation)
    ConversationPolicy.new(
      {
        user: current_user,
        account: current_account,
        account_user: account_user
      },
      conversation
    )
  end

  def account_user
    @account_user ||= AccountUser.find_by(account_id: current_account.id, user_id: current_user.id)
  end

  def sort_order
    params[:sort_order] || :desc
  end
end
