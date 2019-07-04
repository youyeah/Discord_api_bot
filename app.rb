require "discordrb"
require "net/http"
require "uri"
require "json"
require "open-uri"

CLIENT_ID = ENV['CLIENT_ID']
TOKEN = ENV['TOKEN']

class Bot
    attr_accessor :bot

    def initialize
        @bot = Discordrb::Commands::CommandBot.new(client_id: CLIENT_ID, token: TOKEN, prefix: "?")
    end
    
    def start
        setting

        @bot.run
    end

    def setting

        @bot.ready do
            @bot.game = "うごけボイスチャンネル"
        end
    end
end

Bot.new.start