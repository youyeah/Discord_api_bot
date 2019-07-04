require "discordrb"
require "dotenv"

CLIEND_ID = ENV['CLIEND_ID']
TOKEN = ENV['TOKEN']
class Bot
    attr_accessor :bot

    def initialize
        @bot = Discordrb::Commands::CommandBot.new(client_id: CLIEND_ID, token: TOKEN, prefix: "?")
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