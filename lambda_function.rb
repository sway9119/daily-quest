require 'json'
require 'net/http'
require 'date'
require 'dotenv/load'


USERNAME = ENV['USERNAME']
ACCESS_TOKEN = ENV['ACCESS_TOKEN']
URL = 'https://api.github.com/graphql'

QUERY = <<~GRAPHQL
  query($login: String!, $fromDate: DateTime!, $toDate: DateTime!) {
    user(login: $login) {
      contributionsCollection(from: $fromDate, to: $toDate) {
        contributionCalendar {
          totalContributions
          weeks {
            contributionDays {
              contributionCount
              date
            }
          }
        }
      }
    }
  }
GRAPHQL

def get_today_contributions(username, access_token)
  # 取得したい日付を指定
  date = Date.today

  # fromとtoの日付をDateTime型に変換
  from_date = DateTime.new(date.year, date.month, date.day, 0, 0, 0)
  to_date = DateTime.new(date.year, date.month, date.day, 23, 59, 59)

  # リクエストボディを作成する
  variables = { login: USERNAME, fromDate: from_date, toDate: to_date }
  request_body = { query: QUERY, variables: variables }.to_json

  # リクエストを作成する
  uri = URI(URL)
  request = Net::HTTP::Post.new(uri)
  request['Authorization'] = "bearer #{ACCESS_TOKEN}"
  request['Content-Type'] = 'application/json'
  request.body = request_body

  # POSTを実行する
  response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    http.request(request)
  end

  # レスポンスをパースして本日のコントリビューション数を取得する
  github_response = JSON.parse(response.body)
  p github_response
  contribution_days = github_response.dig('data', 'user', 'contributionsCollection', 'contributionCalendar', 'weeks').flat_map { |week| week['contributionDays'] }
  today_contribution_count = contribution_days.find { |day| day['date'] == date.strftime('%Y-%m-%d') }['contributionCount']

  result = today_contribution_count
end

def lambda_handler(event:, context:)
  result = get_today_contributions(USERNAME, ACCESS_TOKEN)
end
