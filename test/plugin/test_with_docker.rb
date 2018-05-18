return true unless ENV["WITH_DOCKER"]

require "json"
require "helper"
require "fluent/plugin/out_postgres_bulk.rb"
require 'fluent-logger'
require 'pg'

class WithDockerTest < Test::Unit::TestCase
  def connect_pg(count = 1, limit = 10)
    PG.connect(
      host: URI.parse(ENV["DOCKER_HOST"]).hostname,
      port: 5432,
      dbname: "test",
      user: "postgres",
      password: "password",
    ).tap { puts "connect_pg => ok" }
  rescue PG::ConnectionBad
    if count <= limit
      puts "connect_pg => retry"
      sleep 1
      connect_pg(count + 1, limit)
    else
      raise
    end
  end

  def connect_fluentd(count = 1, limit = 10)
    Fluent::Logger.open(
      Fluent::Logger::FluentLogger,
      "test",
      host: URI.parse(ENV["DOCKER_HOST"]).hostname,
      port: 24224
    )
    if Fluent::Logger.default.connect?
      puts "connect_fluentd => ok"
    elsif count <= limit
      puts "connect_fluentd => retry"
      sleep 1
      connect_fluentd(count + 1, limit)
    else
      raise "can not connect to fluent-logger"
    end
  end

  setup do
    system("cd #{__dir__}/docker; docker-compose up --build --detach")
    at_exit { system("cd #{__dir__}/docker; docker-compose down") }
    @client = connect_pg
    @client.exec("truncate bulk")
    connect_fluentd
  end

  teardown do
    at_exit { @client.close }
  end

  def test_write
    data = 3.times.map do |i|
      {
        "col1" => i,
        "col2" => "$$$aaa$$$",
        "col3" => nil,
        "col4" => JSON.dump({"hello" => "world's end --","value" => i}),
      }
    end
    data.each do |payload|
      ret = Fluent::Logger.post_with_time(
        "tag1",
        payload,
        Time.now.to_i
      )
      unless ret
        raise "can not post to fluentd"
      end
    end
    sleep 2 # wait flush
    @client.exec("select * from bulk") do |r|
      assert_equal(
        r.to_a,
        [
          {"col1"=>"0", "col2"=>"$$$aaa$$$", "col3"=>nil, "col4"=>"{\"hello\": \"world's end --\", \"value\": 0}"},
          {"col1"=>"1", "col2"=>"$$$aaa$$$", "col3"=>nil, "col4"=>"{\"hello\": \"world's end --\", \"value\": 1}"},
          {"col1"=>"2", "col2"=>"$$$aaa$$$", "col3"=>nil, "col4"=>"{\"hello\": \"world's end --\", \"value\": 2}"}
        ]
      )
    end
  end
end
