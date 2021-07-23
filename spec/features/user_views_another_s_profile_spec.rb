require 'rails_helper'

RSpec.feature "user views anothers game", type: :feature do
  let(:user) { FactoryBot.create :user, id: 1, name: 'Johnny'  }
  let!(:another_user) {FactoryBot.create :user, id: 2, name: 'Olaf' }

  let!(:game1) do
      FactoryBot.create(:game, user: another_user, created_at: '2021-07-06 08:07:30',
                        finished_at: '2021-07-06 08:07:45', current_level: 10,
                        prize: 500000, fifty_fifty_used: true )
  end

  let!(:game2) do
      FactoryBot.create(:game, user: another_user, created_at: '2021-05-01 08:07:30',
                        finished_at:'2021-05-01 08:07:50', current_level: 15,
                        prize: 1000000, friend_call_used: true )
      end

  let!(:game3) do
      FactoryBot.create(:game, user: another_user, created_at: '2021-06-01 08:07:30',
                        finished_at:'2021-06-01 08:08:07', is_failed: true,
                        current_level: 2, audience_help_used: true )
  end

  before do
    login_as user
  end

  scenario 'successfully' do
    visit '/'
    click_link 'Olaf'

    # Ожидаем, что попадем на нужный url
    expect(page).to have_current_path '/users/2'

    # Ожидаем осутствие ссылки на смену пароля
    expect(page).not_to have_content 'Сменить имя и пароль'

    # Порядковые номера игр
    expect(page).to have_content '1'
    expect(page).to have_content '2'
    expect(page).to have_content '3'

    # Статусы игр
    expect(page).to have_content 'победа'
    expect(page).to have_content 'проигрыш'
    expect(page).to have_content 'деньги'

    # Даты создания игр (локализованные)
    expect(page).to have_content '01 мая, 08:07'
    expect(page).to have_content '01 июня, 08:07'
    expect(page).to have_content '06 июля, 08:07'

    # Номера последних вопросов
    expect(page).to have_content '15'
    expect(page).to have_content '2'
    expect(page).to have_content '10'

    # Призовые суммы
    expect(page).to have_content '1 000 000 ₽'
    expect(page).to have_content '0 ₽'
    expect(page).to have_content '500 000 ₽'

    # Ожидается что использован каждый вид подсказок - по одному разу
    expect(page).to have_css("span.game-help-used .fa-phone", count: 1)
    expect(page).to have_css("span.game-help-used", :text => "50/50", count: 1)
    expect(page).to have_css("span.game-help-used .fa-users", count: 1)
  end
end
