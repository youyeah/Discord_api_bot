require "discordrb"
require "dotenv"

CLIEND_ID = ENV['CLIEND_ID']
TOKEN = ENV['TOKEN']
class Bot
    attr_accessor :bot

    def initialize
        @bot = Discordrb::Commands::CommandBot.new(client_id: 590183973179621416, token: "NTkwMTgzOTczMTc5NjIxNDE2.XRzGuA.W-ARcsPUKZXwLvl-g-sN1FOm9CE", prefix: "?")
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