ENV['RACK_ENV'] ||= 'development'

require 'rubygems'
require 'sinatra/base'
require 'json'

ID = ((ENV["VCAP_APPLICATION"] && JSON.parse(ENV["VCAP_APPLICATION"])["instance_id"]) || SecureRandom.uuid).freeze

require "instances"
require "stress_testers"
require "log_utils"
require 'bundler'
Bundler.require :default, ENV['RACK_ENV'].to_sym

$stdout.sync = true
$stderr.sync = true

class Dora < Sinatra::Base
  use Instances
  use StressTesters
  use LogUtils

  def puts_dora(count)
    t = Thread.new do
      1.upto(count) do |num|
        puts "#{num}! #{Time.now}"
      end
    end
  end

  get '/' do
     puts "Hi, I'm Dora! #{Time.now}"
    "Hi, I'm Dora!"
  end

  get '/puts/:count' do
    count = params[:count].to_i
    puts_dora(count)
    "Hi, I'm Dora! count = #{count}\n"
  end

  get '/find/:filename' do
    `find / -name #{params[:filename]}`
  end

  get '/sigterm' do
    "Available sigterms #{`man -k signal | grep list`}"
  end

  get '/delay/:seconds' do
    sleep params[:seconds].to_i
    "YAWN! Slept so well for #{params[:seconds].to_i} seconds"
  end

  get '/sigterm/:signal' do
    pid = Process.pid
    signal = params[:signal]
    puts "Killing process #{pid} with signal #{signal}"
    Process.kill(signal, pid)
  end

  get '/logspew/:bytes' do
    system "cat /dev/urandom | head -c #{params[:bytes].to_i}"
    "Just wrote #{params[:bytes]} random bytes to the log"
  end

  get '/echo/:destination/:output' do
    redirect =
        case params[:destination]
          when "stdout"
            ""
          when "stderr"
            " 1>&2"
          else
            " > #{params[:destination]}"
        end

    system "echo '#{params[:output]}'#{redirect}"

    "Printed '#{params[:output]}' to #{params[:destination]}!"
  end

  get '/env/:name' do
    ENV[params[:name]]
  end

  get '/env' do
    ENV.to_hash.to_s
  end

  run! if app_file == $0
end
