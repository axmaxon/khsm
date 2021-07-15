# (c) goodprogrammer.ru

require 'rails_helper'
require 'support/my_spec_helper' # наш собственный класс с вспомогательными методами

# Тестовый сценарий для модели Игры
# В идеале - все методы должны быть покрыты тестами,
# в этом классе содержится ключевая логика игры и значит работы сайта.
RSpec.describe Game, type: :model do
  # пользователь для создания игр
  let(:user) { FactoryBot.create(:user) }

  # игра с прописанными игровыми вопросами
  let(:game_w_questions) { FactoryBot.create(:game_with_questions, user: user) }

  # Группа тестов на работу фабрики создания новых игр
  describe 'Game Factory' do
    it 'Game.create_game! new correct game' do
      # генерим 60 вопросов с 4х запасом по полю level,
      # чтобы проверить работу RANDOM при создании игры
      generate_questions(60)

      game = nil
      # создaли игру, обернули в блок, на который накладываем проверки
      expect {
        game = Game.create_game_for_user!(user)
      }.to change(Game, :count).by(1).and(# проверка: Game.count изменился на 1 (создали в базе 1 игру)
        change(GameQuestion, :count).by(15).and(# GameQuestion.count +15
          change(Question, :count).by(0) # Game.count не должен измениться
        )
      )
      # проверяем статус и поля
      expect(game.user).to eq(user)
      expect(game.status).to eq(:in_progress)
      # проверяем корректность массива игровых вопросов
      expect(game.game_questions.size).to eq(15)
      expect(game.game_questions.map(&:level)).to eq((0..14).to_a)
    end
  end

  # тесты на основную игровую логику
  describe 'game mechanics' do
    # правильный ответ должен продолжать игру
    it 'answer correct continues game' do
      # текущий уровень игры и статус
      level = game_w_questions.current_level
      q = game_w_questions.current_game_question
      expect(game_w_questions.status).to eq(:in_progress)

      game_w_questions.answer_current_question!(q.correct_answer_key)

      # перешли на след. уровень
      expect(game_w_questions.current_level).to eq(level + 1)
      # ранее текущий вопрос стал предыдущим
      expect(game_w_questions.previous_game_question).to eq(q)
      expect(game_w_questions.current_game_question).not_to eq(q)
      # игра продолжается
      expect(game_w_questions.status).to eq(:in_progress)
      expect(game_w_questions.finished?).to be_falsey
    end

    it '#take_money!' do
      # Состояние игры: в процессе, получаем очередной(текущий) вопрос
      next_question = game_w_questions.current_game_question

      # Получаем правильный ответ на текущий вопрос
      game_w_questions.answer_current_question!(next_question.correct_answer_key)

      # Игрок берёт деньги
      game_w_questions.take_money!

      # Проверяем наличие денежного приза в базе
      award = game_w_questions.prize
      expect(award).to be > 0

      # Проверка статуса игры (должен соответствовать :money)
      expect(game_w_questions.status).to eq :money

      # Проверка что игра завершена
      expect(game_w_questions.finished?).to be_truthy

      # Проверка баланса пользователя
      expect(user.balance).to eq award
    end
  end

  describe '#status' do

    # перед каждым тестом "завершаем игру"
    before(:each) do
      game_w_questions.finished_at = Time.now
      expect(game_w_questions.finished?).to be_truthy
    end

    it ':won' do
      game_w_questions.current_level = Question::QUESTION_LEVELS.max + 1
      expect(game_w_questions.status).to eq(:won)
    end

    it ':fail' do
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:fail)
    end

    it ':timeout' do
      game_w_questions.created_at = 1.hour.ago
      game_w_questions.is_failed = true
      expect(game_w_questions.status).to eq(:timeout)
    end

    it ':money' do
      expect(game_w_questions.status).to eq(:money)
    end
  end

  describe '#current_game_question' do
    it 'returns the current GameQuestion instance' do
      game_w_questions.current_level = 5
      expect(game_w_questions.current_game_question).to eq(game_w_questions.game_questions[5])
    end
  end

  describe '#previous_level' do
    it 'decrements the current level' do
      game_w_questions.current_level = 5
      expect(game_w_questions.previous_level).to eq(4)
    end
  end

  describe '#answer_current_question!' do
    before { game_w_questions.current_level = 5 }

    context 'when answer is correct ' do
      it 'continues the game' do
        expect(game_w_questions.answer_current_question!('d')).to be_truthy
        expect(game_w_questions.current_level).to eq(6)
        expect(game_w_questions.status).to eq(:in_progress)
      end
    end

    context 'when answer is wrong' do
      it 'level does not change' do
        expect(game_w_questions.answer_current_question!('a')).to be_falsey
        expect(game_w_questions.current_level).to eq(5)
        expect(game_w_questions.status).to eq(:fail)
      end
    end

    context 'when answer is last and correct' do
      it 'finishes the game with a win' do
        game_w_questions.current_level = 14
        expect(game_w_questions.answer_current_question!('d')).to be_truthy
        expect(game_w_questions.current_level).to eq(15)
        expect(game_w_questions.status).to eq(:won)
      end
    end

    context 'when time is over' do
      it 'finishes the game with a lose' do
        game_w_questions.created_at = (35).minutes.ago
        expect(game_w_questions.answer_current_question!('d')).to be_falsey
        expect(game_w_questions.status).to eq(:timeout)
      end
    end
  end
end
