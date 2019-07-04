require "discordrb"
require "net/http"
require "uri"
require "json"
require "open-uri"
require "dotenv"

Dotenv.load

CLIENT_ID = ENV['CLIENT_ID']
TOKEN = ENV['TOKEN']

LIVEDOOR_WEATHER_API_HOST = ENV['LIVEDOOR_API']
RIOT_GAMES_API_KEY = ENV['RIOT_GAMES_API_KEY']
TALK_API_HOST = ENV['TALK_API_HOST']
TALK_API_KEY = ENV['TALK_API_KEY']

class Sushi

    attr_accessor :bot
    
    def initialize
        @bot = Discordrb::Commands::CommandBot.new(client_id: CLIENT_ID, token: TOKEN, prefix: "?")
        @connect_state = false
    end

    def start
        puts "This bot's invite URL is #{@bot.invite_url}"

        setting

        @bot.run
    end

    def setting

        # 〜をプレイ中を設定
        @bot.ready do
            @bot.game = "?helpでコマンドを表示"
        end

        # メンションのメッセージにTalk APIを使って返事
        @bot.mention do |event|
            mention_users = event.message.mentions
            message = event.content
      
            # 不要な文字列を除去
            message.delete!("\s")
            mention_users.each{ |user|
              message.slice!("<@#{user.id}>")
            }
            message = "<@#{event.user.id}> " + mention_message(message)
            event.respond(message)
        end

        # 本当は応答速度を確認したかったけど、event.timestampがマイクロ秒を扱っていなかったので、断念
        @bot.command :gg do |event|
            timestamp = Time.now
            m = event.respond("ez!")
            m.edit "ez！ 応答の処理に #{(Time.now - timestamp)} 秒かかったよ！"
        end

        # ?weatherコマンド  引数なしでざっくりした天気、引数ありで場所の詳細を表示
        @bot.command [:weather, :city] do |event, city|
            city.nil? ? message = weather_message : message = custom_weather(city: city)
            if message.class == Array
                event.send_embed do |embed|
                    embed.colour = 0xBDFF7D
                    embed.title = message[0]
                    embed.description = "\n#{message[1]}\n"
                end
            else
                event.send_embed do |embed|
                    embed.colour = 0xBDFF7D
                    embed.title = "明日の天気一覧だyo"
                    embed.description = message
                end
            end
        end
        @bot.command [:w, :city] do |event, city|
            city.nil? ? message = weather_message : message = custom_weather(city: city)
            if message.class == Array
                event.send_embed do |embed|
                    embed.colour = 0xBDFF7D
                    embed.title = message[0]
                    embed.description = "\n#{message[1]}\n"
                end
            else
                event.send_embed do |embed|
                    embed.colour = 0xBDFF7D
                    embed.title = "明日の天気一覧だyo"
                    embed.description = message
                end
            end

            # event.respond(message)
        end

        # 現在時刻と、明朝６時までの時間を表示
        @bot.command :time do |event|
            event.send_embed do |embed|
                embed.colour = 0xBDFF7D
                embed.description = time_message
            end
        end
        @bot.command :t do |event|
            event.send_embed do |embed|
                embed.colour = 0xBDFF7D
                embed.description = time_message
            end
            # event.respond(time_message)
        end

        # Riot Games API を使って、サモナーネームからランクを表示
        @bot.command :lol do |event, *sn|
            chained_sn = ""
            sn.each { |s| chained_sn += s }
            chained_sn.delete!("　")
            event.send_embed do |embed|
                embed.colour = 0xBDFF7D
                embed.description = lol_message(chained_sn)
            end
            # event.respond(lol_message(chained_sn))
        end

        @bot.command :av do |event, *string|
            data = avgle_info(string.join)
            3.times do |t|
                event.send_embed do |embed|
                    embed.title = "見る"
                    embed.url = "#{data[t][0]}"
                    embed.colour = 0xFF5CAD
                    embed.description = "#{data[t][1]}"
                    embed.image = Discordrb::Webhooks::EmbedImage.new(url: "#{data[t][2]}")
                end
            end
            event.response("#{string.join}で検索したよ！")
        end

        # ヘルプを表示
        @bot.command :help do |event|
            message = help_message
            event.send_embed do |embed|
                message.length.times do |t|
                    embed.add_field(
                        name: message[t][0],
                        value: message[t][1],
                        inline: false
                      )
                end
                embed.colour = 0xBDFF7D
            end
        end
        @bot.command :h do |event|
            message = help_message
            event.send_embed do |embed|
                message.length.times do |t|
                    embed.add_field(
                        name: message[t][0],
                        value: message[t][1],
                        inline: false
                      )
                end
                embed.colour = 0xBDFF7D
            end
        end

        bot.command :connect do |event|
            channel = event.user.voice_channel
            unless channel
                event.send_embed do |embed|
                    embed.title = "ボイスチャンネルに接続してください！"
                    embed.colour = 0xFF0202
                end
                next
            end
            bot.voice_connect(channel)
            @connect_state = true
            event.send_embed do |embed|
                embed.title = "#{channel.name}に接続しました！"
                embed.colour = 0x02FF02
            end
          end
          
          bot.command :hiphop do |event|
            unless @connect_state
                channel = event.user.voice_channel
                next unless channel
                bot.voice_connect(channel)
                @connect_state = true
            end
            music = "media/hiphop#{rand(1..2)}.mp3"
            event.voice.play_file(music)
          end

          bot.command :play do |event|
            unless @connect_state
                event.send_embed do |embed|
                    embed.title = "botをボイスチャンネルに接続してください！"
                    embed.colour = 0xFF0202
                end
                next
            end
            music = 'media/a.mp3'
            event.voice.play_file(music)
          end

          bot.command :stop do |event|
            event.voice.stop_playing
          end

          bot.command :disconnect do |event|
            if @connect_state
                @bot.voices[event.server.id].destroy
                event.send_embed do |embed|
                    embed.title = "またね"
                    embed.colour = 0x02FF02
                end
                @connect_state = false
                next
            else
                event.send_embed do |embed|
                    embed.title = "ボイスチャンネルに接続してないよ"
                    embed.colour = 0xFF0202
                end
                next
            end
          end
        
    end

    def mention_message(message)
        uri = URI.parse(TALK_API_HOST)
        req = Net::HTTP::Post.new(uri)
        req.set_form_data({'apikey' => TALK_API_KEY, 'query' => message})
        req_options = {use_ssl: uri.scheme = "https"}
        response = Net::HTTP.start(uri.hostname, uri.port, req_options) do |http|
            http.request(req)
        end
        data = JSON.parse(response.body)
        return data["results"][0]["reply"]
    end

    def time_message
        Time.now.hour > 6 ? will = Time.new(Time.now.year,Time.now.mon,Time.now.day+1,6,00,00) : will = Time.new(Time.now.year,Time.now.mon,Time.now.day,6,00,00)
        remain  = will - Time.now
        return "現在時刻は#{Time.now.hour}時#{Time.now.min}分！\n明日の朝6時まであと  #{(remain/60/60).to_i}時間と#{(60*(remain/60/60%1)).to_i }分  だよ！"
    end

    def weather_message
        citys = [["sapporo","016010"],["tokyo","130010"],["saitama","110010"],["osaka","270000"]]
        message = ""
        citys.each do |city|
            response = open("http://weather.livedoor.com/forecast/webservice/json/v1?city=#{city[1]}")
            parse_text = JSON.parse(response.read)
            message += parse_text["location"]["city"] + "は" + parse_text["forecasts"][1]["telop"] + "！ "
        end
        message
    end

    def custom_weather(city: nil)

        city ||= "大阪"
        if city == "大阪"
            city = "270000"
        elsif city == "札幌"
            city = "016010"
        elsif city == "東京"
            city = "130010"
        elsif city == "埼玉"
            city = "110010"
        else
            return "札幌・東京・埼玉・大阪の中から選んでください"
        end
        response = open("http://weather.livedoor.com/forecast/webservice/json/v1?city=#{city}")
        parse_text = JSON.parse(response.read)
        message = parse_text["location"]["city"] + "の天気の詳細です！", parse_text["description"]["text"]
        return message
    end

    # Riot Games APIを使ったmessageの作成
    def lol_message(sn)
        sn ||= nil    
        return message = "サモナーネームを入力してください。\n例：?lol スタンミジャパン" if sn == nil
        # 日本語のサモナーネームを検索するために.encodeする
        sn_uri = URI.encode(sn)
        uri = URI.parse("https://jp1.api.riotgames.com/lol/summoner/v4/summoners/by-name/#{sn_uri}?api_key=#{RIOT_GAMES_API_KEY}")
        return_data = Net::HTTP.get(uri)
        data = JSON.parse(return_data)
        return "サモナーを見つけられません。" if data["id"] == nil

        sn_info_uri = "https://jp1.api.riotgames.com/lol/league/v4/entries/by-summoner/#{data["id"]}?api_key=#{RIOT_GAMES_API_KEY}"
        sn_info_json = open(sn_info_uri)
        sn_info = JSON.parse(sn_info_json.read)
        return "#{sn}さんは#{data["summonerLevel"]}レベルです！" if sn_info == []

        message = sn_info[0]["summonerName"] + "さんは、" + sn_info[0]["tier"] + sn_info[0]["rank"] + "です！"
    end

    # def avgle_message(string)
    #     string = URI.encode(string)
    #     response = open("https://api.avgle.com/v1/jav/#{string}/0?limit=3")
    #     data = JSON.parse(response.read)
        
    #     message = ""
    #     3.times do |t|
    #         message += data["response"]["videos"][t]["title"] + "\n" + data["response"]["videos"][t]["video_url"] + "\n"
    #     end
    #     return message
    #     # message += "#{data["response"]["videos"][2]["title"]}\n"
    # end

    def avgle_info(string)
        string = URI.encode(string)
        response = open("https://api.avgle.com/v1/jav/#{string}/0?limit=3")
        data = JSON.parse(response.read)
        return_data = [[],[],[]]
        # p data["response"]["total_videos"]
        3.times do |t|
            return_data[t].push(data["response"]["videos"][t]["video_url"]).push(data["response"]["videos"][t]["title"]).push(data["response"]["videos"][t]["preview_url"])
        end
        return_data[0][0] = "ビデオが見つかりません"  if return_data[0][0] == nil
        return return_data
        # message += "#{data["response"]["videos"][2]["title"]}\n"
    end

    def help_message
        message = [["メンション","このボットにメンションでメッセージを送ると、簡単な会話ができます。"],
            ["?av キーワード","avgleの検索結果３件を表示"],
            ["?time","現在の時刻を表示"],
            ["?gg","反応速度の表示"],
            ["?weather","明日の天気。さらに札幌・東京・埼玉・大阪を指定すると詳細を表示できます。"],
            ["?lol サモナーネーム","ランクを表示"],
            ["?connect","ユーザーがいるボイスチャンネルにbotを接続します。"],
            ["?play","I was Kingを流します。"],
            ["?disconnect","ボイスチャンネルから切断します。"],
            ["?help","コマンド一覧"]
            ]
    end
    
end

Sushi.new.start

# class Bot
#     attr_accessor :bot

#     def initialize
#         @bot = Discordrb::Commands::CommandBot.new(client_id: CLIENT_ID, token: TOKEN, prefix: "?")
#     end
    
#     def start
#         setting

#         @bot.run
#     end

#     def setting

#         @bot.ready do
#             @bot.game = "うごけボイスチャンネル"
#         end
#     end
# end

# Bot.new.start