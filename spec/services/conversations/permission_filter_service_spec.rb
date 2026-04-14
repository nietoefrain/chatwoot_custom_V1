require 'rails_helper'

RSpec.describe Conversations::PermissionFilterService do
  let(:account) { create(:account) }
  let!(:conversation) { create(:conversation, account: account, inbox: inbox) }
  let!(:another_conversation) { create(:conversation, account: account, inbox: inbox) }
  let(:admin) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let!(:inbox) { create(:inbox, account: account) }

  # This inbox_member is used to establish the agent's access to the inbox
  before { create(:inbox_member, user: agent, inbox: inbox) }

  describe '#perform' do
    context 'when user is an administrator' do
      it 'returns all conversations' do
        result = described_class.new(
          account.conversations,
          admin,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result.count).to eq(2)
      end
    end

    context 'when user is an agent' do
      it 'returns all conversations with no further filtering' do
        inbox_ids = agent.inboxes.where(account_id: account.id).pluck(:id)

        # The base implementation returns all conversations
        # expecting the caller to filter by assigned inboxes
        result = described_class.new(
          account.conversations.where(inbox_id: inbox_ids),
          agent,
          account
        ).perform

        expect(result).to include(conversation)
        expect(result).to include(another_conversation)
        expect(result.count).to eq(2)
      end
    end

    context 'when agent is restricted to specific teams' do
      let(:allowed_team) { create(:team, account: account) }
      let(:blocked_team) { create(:team, account: account) }
      let!(:allowed_conversation) { create(:conversation, :with_team, account: account, inbox: inbox, team: allowed_team) }
      let!(:blocked_conversation) { create(:conversation, :with_team, account: account, inbox: inbox, team: blocked_team) }
      let!(:unassigned_team_conversation) { create(:conversation, account: account, inbox: inbox, team: nil) }

      before do
        agent.account_users.find_by(account: account).update!(allowed_team_ids: [allowed_team.id])
      end

      it 'returns only conversations from permitted teams' do
        result = described_class.new(
          account.conversations.where(inbox_id: inbox.id),
          agent,
          account
        ).perform

        expect(result).to include(allowed_conversation)
        expect(result).not_to include(blocked_conversation)
        expect(result).not_to include(unassigned_team_conversation)
      end
    end

    context 'when restricted agent belongs to support team' do
      let(:support_team) { create(:team, account: account, name: 'soporte') }
      let(:other_team) { create(:team, account: account, name: 'administracion') }
      let!(:support_conversation) { create(:conversation, :with_team, account: account, inbox: inbox, team: support_team) }
      let!(:other_conversation) { create(:conversation, :with_team, account: account, inbox: inbox, team: other_team) }
      let!(:unassigned_team_conversation) { create(:conversation, account: account, inbox: inbox, team: nil) }

      before do
        create(:team_member, team: support_team, user: agent)
        agent.account_users.find_by(account: account).update!(allowed_team_ids: [other_team.id])
      end

      it 'bypasses the team restriction and returns all inbox conversations' do
        result = described_class.new(
          account.conversations.where(inbox_id: inbox.id),
          agent,
          account
        ).perform

        expect(result).to include(support_conversation)
        expect(result).to include(other_conversation)
        expect(result).to include(unassigned_team_conversation)
      end
    end
  end
end
