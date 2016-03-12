namespace :elm do
  desc "TODO"
  task watch: :environment do
    Dir.chdir("frontend")

    FileWatcher.new(["*.elm"]).watch do |filename|
      system("elm make *.elm --yes --output ../app/assets/javascripts/elm.js")
    end
  end
end
