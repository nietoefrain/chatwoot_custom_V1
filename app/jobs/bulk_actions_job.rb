class BulkActionsJob < ApplicationJob
  include DateRangeHelper

  queue_as :medium
  attr_accessor :records

  MODEL_TYPE = ['Conversation'].freeze

  def perform(account:, params:, user:)
    @account = account
    Current.user = user
    @params = params
    @records = records_to_updated(params[:ids])
    bulk_update
  ensure
    Current.reset
  end

  def bulk_update
    bulk_remove_labels
    bulk_conversation_update
  end

  def bulk_conversation_update
    params = available_params(@params)
    records.each do |conversation|
      bulk_add_labels(conversation)
      bulk_snoozed_until(conversation)
      update_conversation(conversation, params) if params
    end
  end

  def bulk_remove_labels
    records.each do |conversation|
      remove_labels(conversation)
    end
  end

  def available_params(params)
    return unless params[:fields]

    params[:fields].delete_if { |key, value| value.nil? && key == 'status' }
  end

  def update_conversation(conversation, params)
    update_params = params.to_h.symbolize_keys
    assign_agent(conversation, update_params.delete(:assignee_id)) if update_params.key?(:assignee_id)
    conversation.update!(update_params) if update_params.present?
  end

  def assign_agent(conversation, assignee_id)
    ActionService.new(conversation).assign_agent([assignee_id])
  end

  def bulk_add_labels(conversation)
    conversation.add_labels(@params[:labels][:add]) if @params[:labels] && @params[:labels][:add]
  end

  def bulk_snoozed_until(conversation)
    conversation.snoozed_until = parse_date_time(@params[:snoozed_until].to_s) if @params[:snoozed_until]
  end

  def remove_labels(conversation)
    return unless @params[:labels] && @params[:labels][:remove]

    labels = conversation.label_list - @params[:labels][:remove]
    conversation.update(label_list: labels)
  end

  def records_to_updated(ids)
    current_model = @params[:type].camelcase
    return unless MODEL_TYPE.include?(current_model)

    current_model.constantize&.where(account_id: @account.id, display_id: ids)
  end
end
