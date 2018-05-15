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
    config_param :column_names, :string,
      desc: "Bulk insert column."

    def initialize
      super
      require 'pg'
    end

    def configure(conf)
      super
      @column_names_ary = @column_names.split(',').map(&:strip).reject(&:empty?)
      @column_names_joined = @column_names_ary.join(',')
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
      handler = client
      values = []
      chunk.each { |time, record|
        v = @column_names_ary.map { |k|
          record[k]
        }
        values.push(*v)
      }
      place_holders = values.each_slice(@column_names_ary.length)
                            .map
                            .with_index { |cols, i|
                              params = cols.map.with_index { |c, j|
                                "$#{i * cols.length + j + 1}"
                              }
                              "(#{params.join(',')})"
                            }.join(',')
      query = "INSERT INTO #{@table} (#{@column_names_joined}) VALUES #{place_holders}"
      handler.prepare("write", query)
      handler.exec_prepared("write", values)
      handler.close
    end
  end
end
