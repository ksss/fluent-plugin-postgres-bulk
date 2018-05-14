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
      column_names_ary = @column_names.split(',').map(&:strip).reject(&:empty?)
      @column_names_joined = column_names_ary.join(',')
      @column_names_map = column_names_ary.map { |c| [c, true] }.to_h
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
        cols = record.map { |k, v| @column_names_map.key?(k) ? v : nil }
                       .compact
                       .map { |v| "'#{v}'" }
                       .join(',')
        values << "(#{cols})"
      }
      sql = "INSERT INTO #{@table} (#{@column_names_joined}) VALUES #{values.join(',')}".dup
      handler.exec(sql)
      handler.close
    end
  end
end
