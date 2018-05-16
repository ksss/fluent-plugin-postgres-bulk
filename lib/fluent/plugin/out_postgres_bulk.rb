# frozen_string_literal: true
require 'fluent/plugin/output'

module Fluent::Plugin
  class PostgresBulkOutput < Output
    Fluent::Plugin.register_output('postgres_bulk', self)

    config_param :host, :string, default: '127.0.0.1',
      desc: "Database host."
    config_param :port, :integer, default: 5432,
      desc: "Database port."
    config_param :database, :string,
      desc: "Database name."
    config_param :username, :string,
      desc: "Database user."
    config_param :password, :string, default: '', secret: true,
      desc: "Database password."
    config_param :table, :string,
      desc: "Bulk insert table."
    config_param :column_names, :array,
      desc: "Bulk insert column."

    def initialize
      super
      require 'pg'
    end

    def client
      PG.connect(
        host: @host,
        port: @port,
        dbname: @database,
        user: @username,
        password: @password,
      )
    end

    def multi_workers_ready?
      true
    end

    def write(chunk)
      handler = client()
      begin
        values = build_values(chunk)
        place_holders = build_place_holders(values)
        query = "INSERT INTO #{@table} (#{@column_names.join(',')}) VALUES #{place_holders}"
        handler.exec_params(query, values)
      ensure
        handler.close
      end
    end

    private

    def build_values(chunk)
      values = []
      chunk.each { |time, record|
        v = @column_names.map { |k|
          record[k]
        }
        values.push(*v)
      }
      values
    end

    def build_place_holders(values)
      values.each_slice(@column_names.length)
            .map
            .with_index { |cols, i|
              params = cols.map.with_index { |c, j|
                "$#{i * cols.length + j + 1}"
              }
              "(#{params.join(',')})"
            }.join(',')
    end
  end
end
