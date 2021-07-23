require 'rails_helper'

# Тест на шаблон users/show.html.erb
RSpec.describe 'users/show', type: :view do
  let(:profile_owner) { assign(:user, FactoryBot.build_stubbed(:user, name: 'Johnny')) }
  let(:profile_games) { assign(:games, [FactoryBot.build_stubbed(:game)]) }

  context 'when user is unauthorized' do
    before do
      profile_owner
      render
    end

    it 'does not render a link to change the password' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'renders user name' do
      expect(rendered).to match 'Johnny'
    end

    it 'renders user games' do
      profile_games
      stub_template "users/_game.html.erb" => "User games show here"
      render

      expect(rendered).to match 'User games show here'
    end
  end

  context 'when user is authorized' do
    # current_user соответствует владельцу страницы (пользователь авторизован)
    before { allow(view).to receive(:current_user).and_return(profile_owner) }

    it 'renders a link to change the password' do
      render

      expect(rendered).to match 'Сменить имя и пароль'
    end
  end
end
