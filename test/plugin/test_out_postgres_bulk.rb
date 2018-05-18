require "helper"
require "fluent/plugin/out_postgres_bulk.rb"

class PostgresBulkOutputTest < Test::Unit::TestCase
  setup do
    Fluent::Test.setup
  end

  def create_driver(conf)
    $execed_params = []
    Fluent::Test::Driver::Output.new(Fluent::Plugin::PostgresBulkOutput) do
      def client
        Object.new.tap do |o|
          def o.exec_params(*args)
            $execed_params << args
          end

          def o.close
          end
        end
      end
    end.configure(conf)
  end

  def test_write
    driver = create_driver %[
      database db
      username ksss
      table public.test
      column_names id,col1
    ]
    time = event_time
    driver.run do
      driver.feed("tag", time, {"id" => 1, "col1" => "foo"})
      driver.feed("tag", time, {"id" => 1, "col1" => "bar"})
      driver.feed("tag", time, {"id" => 1, "col1" => "baz"})
    end
    assert_equal($execed_params,
      [
        ["INSERT INTO public.test (id,col1) VALUES ($1,$2),($3,$4),($5,$6)",
          [1, "foo", 1, "bar", 1, "baz"]]
      ]
    )
  end

  def test_write_huge
    driver = create_driver %[
      database db
      username ksss
      table public.test
      column_names id,col1
    ]
    begin
      orig = Fluent::Plugin::PostgresBulkOutput::N_PARAMETER_MAX
      Fluent::Plugin::PostgresBulkOutput.__send__(:remove_const, :N_PARAMETER_MAX)
      Fluent::Plugin::PostgresBulkOutput.__send__(:const_set, :N_PARAMETER_MAX, 10)
      driver.run do
        7.times do |i|
          driver.feed("tag", Time.now.to_i, {"col1" => "foo", "id" => i})
        end
      end
    ensure
      Fluent::Plugin::PostgresBulkOutput.__send__(:remove_const, :N_PARAMETER_MAX)
      Fluent::Plugin::PostgresBulkOutput.__send__(:const_set, :N_PARAMETER_MAX, orig)
    end
    assert_equal($execed_params,
      [
        ["INSERT INTO public.test (id,col1) VALUES ($1,$2),($3,$4),($5,$6),($7,$8),($9,$10)",
          [0, "foo", 1, "foo", 2, "foo", 3, "foo", 4, "foo"]],
        ["INSERT INTO public.test (id,col1) VALUES ($1,$2),($3,$4)",
          [5, "foo", 6, "foo"]]
      ]
    )
  end
end
