require 'httparty'
require 'date'

USERNAME = ENV['USERNAME']
ACCESS_TOKEN = ENV['ACCESS_TOKEN']

def get_today_contributions(username, access_token)
  # 今日の日付を取得
  today = Date.today.strftime('%Y-%m-%d')

  # GitHub APIのエンドポイント
  github_api_url = "https://api.github.com/users/#{username}/events"

  # GitHub APIにアクセスしてイベント情報を取得
  response = HTTParty.get(github_api_url, headers: { 'Authorization' => "token #{access_token}" })

  # レスポンスを確認して本日のコミット数を計算
  if response.code == 200
    events = JSON.parse(response.body)

    # 本日のPushEvent（コミット）の数をカウント
    today_commit_count = events.count do |event|
      event['type'] == 'PushEvent' && Date.parse(event['created_at']).strftime('%Y-%m-%d') == today
    end

    return { statusCode: 200, body: today_commit_count }
  else
    return { statusCode: response.code, body: 'GitHub APIにアクセスできませんでした' }
  end
end

def lambda_handler(event:, context:)
  # コントリビューションカレンダーを取得
  result = get_today_contributions(USERNAME, ACCESS_TOKEN)
end