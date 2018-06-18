# frozen_string_literal: true
require 'fluent/plugin/output'
require 'benchmark'

module Fluent::Plugin
  class PostgresBulkOutput < Output
    # number of parameters must be between 0 and 65535
    N_PARAMETER_MAX = 65535
    Fluent::Plugin.register_output('postgres_bulk', self)

    helpers :inject

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

    def formatted_to_msgpack_binary
      true
    end

    def format(tag, time, record)
      record = inject_values_to_record(tag, time, record)
      [tag, time, record].to_msgpack
    end

    def write(chunk)
      handler = client()
      values = build_values(chunk)
      max_slice = N_PARAMETER_MAX / @column_names.length * @column_names.length
      values.each_slice(max_slice) do |slice|
        place_holders = build_place_holders(slice)
        query = "INSERT INTO #{@table} (#{@column_names.join(',')}) VALUES #{place_holders}"
        t = Benchmark.realtime {
          handler.exec_params(query, slice)
        }
        log.info("(table: #{table}) inserted #{slice.length / @column_names.length} records in #{(t * 1000).to_i} ms")
      end
    ensure
      handler&.close
    end

    private

    def build_values(chunk)
      values = []
      chunk.each do |_tag, _time, record|
        v = @column_names.map { |k|
          record[k]
        }
        values.push(*v)
      end
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
