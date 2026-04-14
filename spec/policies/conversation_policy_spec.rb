require 'rails_helper'

RSpec.describe ConversationPolicy, type: :policy do
  subject { described_class }

  let(:account) { create(:account) }
  let(:administrator) { create(:user, account: account, role: :administrator) }
  let(:agent) { create(:user, account: account, role: :agent) }
  let(:administrator_context) { { user: administrator, account: account, account_user: administrator.account_users.find_by(account: account) } }
  let(:agent_context) { { user: agent, account: account, account_user: agent.account_users.find_by(account: account) } }

  let(:conversation) { create(:conversation, account: account) }

  permissions :destroy? do
    context 'when user is an administrator' do
      it 'allows destroy' do
        expect(subject).to permit(administrator_context, conversation)
      end
    end

    context 'when user is an agent' do
      it 'denies destroy' do
        expect(subject).not_to permit(agent_context, conversation)
      end
    end
  end

  permissions :index? do
    context 'when user is authenticated' do
      it 'allows index' do
        expect(subject).to permit(agent_context, conversation)
      end
    end
  end

  permissions :show? do
    context 'when user is an administrator' do
      it 'allows access' do
        expect(subject).to permit(administrator_context, conversation)
      end
    end

    context 'when agent has inbox access' do
      let(:inbox) { create(:inbox, account: account) }
      let(:conversation) { create(:conversation, account: account, inbox: inbox) }

      before { create(:inbox_member, user: agent, inbox: inbox) }

      it 'allows access' do
        expect(subject).to permit(agent_context, conversation)
      end
    end

    context 'when agent has team access' do
      let(:team) { create(:team, account: account) }
      let(:conversation) { create(:conversation, :with_team, account: account, team: team) }

      before { create(:team_member, team: team, user: agent) }

      it 'allows access' do
        expect(subject).to permit(agent_context, conversation)
      end
    end

    context 'when agent lacks inbox and team access' do
      let(:conversation) { create(:conversation, account: account) }

      it 'denies access' do
        expect(subject).not_to permit(agent_context, conversation)
      end
    end

    context 'when agent is restricted to specific teams' do
      let(:inbox) { create(:inbox, account: account) }
      let(:allowed_team) { create(:team, account: account) }
      let(:blocked_team) { create(:team, account: account) }

      before do
        create(:inbox_member, user: agent, inbox: inbox)
        agent.account_users.find_by(account: account).update!(allowed_team_ids: [allowed_team.id])
      end

      it 'allows access to conversations in permitted teams' do
        conversation = create(:conversation, :with_team, account: account, inbox: inbox, team: allowed_team)

        expect(subject).to permit(agent_context, conversation)
      end

      it 'denies access to conversations in other teams' do
        conversation = create(:conversation, :with_team, account: account, inbox: inbox, team: blocked_team)

        expect(subject).not_to permit(agent_context, conversation)
      end

      it 'denies access to conversations without a team' do
        conversation = create(:conversation, account: account, inbox: inbox, team: nil)

        expect(subject).not_to permit(agent_context, conversation)
      end
    end

    context 'when restricted agent belongs to support team' do
      let(:inbox) { create(:inbox, account: account) }
      let(:support_team) { create(:team, account: account, name: 'soporte') }
      let(:other_team) { create(:team, account: account, name: 'administracion') }

      before do
        create(:inbox_member, user: agent, inbox: inbox)
        create(:team_member, team: support_team, user: agent)
        agent.account_users.find_by(account: account).update!(allowed_team_ids: [other_team.id])
      end

      it 'allows access to other team conversations in the inbox' do
        conversation = create(:conversation, :with_team, account: account, inbox: inbox, team: other_team)

        expect(subject).to permit(agent_context, conversation)
      end

      it 'allows access to unassigned conversations in the inbox' do
        conversation = create(:conversation, account: account, inbox: inbox, team: nil)

        expect(subject).to permit(agent_context, conversation)
      end
    end
  end
end
