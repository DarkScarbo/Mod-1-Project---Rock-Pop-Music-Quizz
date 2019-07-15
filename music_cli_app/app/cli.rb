class CLI

  def initialize
    @prompt = TTY::Prompt.new
    @font = TTY::Font.new(:standard)
  end


  def graphic_intro
    pastel = Pastel.new
    puts "-- WELCOME TO: --"
    puts ""
    sleep(1.seconds)
    puts pastel.bright_white.on_cyan.bold(@font.write('MUSIC  QUIZ'))
    puts ""
  end


  def find_or_create_user
    name = @prompt.ask("What's your name?: ")
    # binding.pry
    if name == nil
      puts "Enter your name, please"
      find_or_create_user
    else
      @user = User.find_or_create_by(name: name)
    end
  end


  def welcome
    puts "Welcome, #{@user.name.colorize(:color => :cyan)}. Ready to play?"
    rock = "Rock"
    pop = "Pop"
    genre_selection = @prompt.select("Choose your genre:", %w(Rock Pop))
    if genre_selection. == rock
      @genre = "Rock"
      puts "\u{1F91F}" + " " + "\u{1F3B8}" + "  #####   " +  "GODS OF ROCK !!!".colorize(:color => :red) + " #####  "
      # music
      system 'afplay ./app/sounds/rock_instrumental.mp3 &'
    else
      @genre = "Pop"
      puts "\u{1F478}" + " " + "\u{1F3A4}" + "  #####   " + "QUEENS OF POP !!!".colorize(:color => :yellow) + " #####  "
      system 'afplay ./app/sounds/pop_instrumental.mp3 &'
    end
  end

  def main_menu
    start = "START"
    help = "HELP"
    exit = "EXIT"
    answer = @prompt.select('Select ' + 'START'.colorize(:color => :green) + ' if you want to play a new game, ' + 'HELP'.colorize(:color => :green) + ' if you are not sure about how ' + 'MUSIC QUIZ'.colorize(:color => :cyan) + ' works ' + 'START'.colorize(:color => :green) + ' to quit', %w(START HELP EXIT))
    if answer == start
      find_or_create_user
    elsif answer == help
      instructions
    elsif answer == exit
      goodbye
      sleep(2.seconds)
      system 'killall afplay'
    end
  end


  def instructions
    puts ""
    puts "####### HELP #######".colorize(:color => :cyan)
    puts "Music Quiz is easy to play!"
    sleep(1.seconds)
    puts "You have to answer to ten simple questions:"
    sleep(1.seconds)
    puts "We will give a title of an album and you will need to guess who wrote it"
    sleep(1.seconds)
    puts "If you guess the correct answer you earn" + " ONE point".colorize(:color => :yellow) + "!"
    sleep(1.seconds)
    puts "####################".colorize(:color => :cyan)
    sleep(2.seconds)
    puts ""
    main_menu
  end


  def generate_question
    @user.points = 0
    i = 0
    while i < 10
      answered = UserQuestion.all.select{|uq| uq.user_id == @user.id}.map{|uq| uq.question}
      filtered = Question.all.select{|question| !answered.include?(question) && question.album.genre == @genre}
      question_album = filtered.sample.album
      right_answer = question_album.artist.name
      wrong_answers = filtered.select { |q| q.album.artist.name != right_answer }

      wrong_names = wrong_answers.map {|q| q.album.artist.name}.uniq
      alternatives = []

      while alternatives.length < 3
        sample_answer = wrong_names.sample
        wrong_names.delete(sample_answer)
        alternatives << sample_answer
      end

      user_answer = @prompt.select("Who wrote the album '#{question_album.title.colorize(:color => :yellow)}'?", (alternatives << right_answer).shuffle)

      if user_answer == right_answer
        UserQuestion.create(user_id: @user.id, question_id: question_album.id)
        puts "You got it right! " + "+ 1 point".colorize(:color => :yellow) + "!!!"
        @user.points += 1
        @user.save
        i += 1
      else
        puts "Wrong answer!".colorize(:color => :red) + " Sorry."
        i += 1
      end
    end
    @user.user_questions.destroy_all
    final_score
    puts ""
    generate_question if @prompt.yes?("Would you like to play again?".colorize(:color => :cyan))
  end


  def goodbye
    if @user
    puts "See you soon, #{@user.name}!"
    else
    puts "See you soon!"
    end
    # music
    system 'killall afplay'
  end


  def final_score
    if @user.points <= 3
      puts "Ops, your final score is just #{@user.points.to_s.colorize(:color => :yellow)} " + "points".colorize(:color => :yellow) + "!"
    elsif @user.points >= 4 && @user.points <= 7
      puts "Not too bad, #{@user.name}! Your final score is #{@user.points.to_s.colorize(:color => :yellow)} " + "points".colorize(:color => :yellow) + "!"
    else
      puts "YOU ARE A STAR, #{@user.name.colorize(:color => :cyan)}!!! Your final score is #{@user.points.to_s.colorize(:color => :yellow)} " + "points".colorize(:color => :yellow) + "!"
    end
  end


  def run
    graphic_intro
    sleep(2.seconds)
    main_menu
    welcome if @user
    generate_question if @user
    goodbye if @user
    system 'killall afplay'
  end


end
