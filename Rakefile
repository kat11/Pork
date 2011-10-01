require 'rake/testtask'
require 'rake/clean'

$:.unshift 'lib'
require 'pork'

WEB_PORT = 37880

task :default => :start

desc 'Run tests'
Rake::TestTask.new do |t|
  t.test_files = FileList['test/**/test*.rb']
  t.verbose = true
end

desc 'Start server'
task :start do
  ruby "-I lib lib/pork.rb"
end

def mongo cmd
  sh "mongo #{Pork::DB_NAME} --eval '#{cmd}'"
end

namespace :db do
  desc 'Wipe all data from database'
  task :wipe do
    mongo 'db.dropDatabase()'
  end

  desc 'Prep database'
  task :init do
    mongo 'db.createCollection("chats", {capped:true, size:10000000})'
    mongo 'db.chats.ensureIndex({_id: 1})'

    %w(Pork Ribs Ham Bacon Sausages).each do |name|
      mongo %{db.islands.insert({_id: "#{name}", price: 25})}
    end

    mongo 'db.characters.ensureIndex({arrival: 1})'
  end
end

namespace :web do
  desc 'serve web files'
  task :serve => :compile do
    exec "rackup --port #{WEB_PORT}"
  end

  desc 'compile web files'
  task :compile

  FileList['public/**/*.{less,coffee,jade}'].each do |src|
    ext = src.pathmap '%x'
    out = src.pathmap '%X' + {
      '.less' => '.css', '.coffee' => '.js', '.jade' => '.html'
    }[ext]

    case ext
    when '.less'
      file out => src do
        sh "lessc #{src} #{out}"
      end
    when '.coffee'
      file out => src do
        sh "coffee --compile #{src}"
      end
    when '.jade'
      file out => src do
        sh "jade #{src}"
      end
    end

    task :compile => out
    CLOBBER << out
  end
end

