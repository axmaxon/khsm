require 'rails_helper'

# Тест на шаблон users/show.html.erb
RSpec.describe 'users/show', type: :view do
  let(:user) { assign(:user, FactoryBot.create(:user, name: 'Johnny')) }
  let(:another_user) { assign(:user, FactoryBot.create(:user, name: 'Olaf')) }
  let(:profile_games) { assign(:games, [FactoryBot.build_stubbed(:game)]) }

  before do
    sign_in user
    stub_template "users/_game.html.erb" => "User games show here"
  end

  context 'when user is unauthorized' do
    before do
      another_user
      render
    end

    it 'does not render any links with text about to change the password' do
      expect(rendered).not_to match 'Сменить имя и пароль'
    end

    it 'renders user name' do
      expect(rendered).to match 'Olaf'
    end

    it 'renders user games' do
      profile_games
      render

      expect(rendered).to match 'User games show here'
    end
  end

  context 'when user is authorized' do
    before do
      user
      render
    end

    # Более специфичные ожидания, чем в контексте неавторизованного пользователя, т.к
    # проверяется наличие ссылки конкретно для владельца профиля
    it 'renders a link to change the password' do
      expect(rendered).to have_link('Сменить имя и пароль', href: edit_user_registration_path(user))
    end

    it 'renders user name' do
      expect(rendered).to match 'Johnny'
    end
  end
end
