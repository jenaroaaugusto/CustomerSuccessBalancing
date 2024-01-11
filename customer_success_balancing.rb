require 'minitest/autorun'
require 'timeout'

class CustomerSuccessBalancing
  def initialize(customer_success, customers, away_customer_success)
    @customer_success = customer_success
    @customers = customers
    @away_customer_success = away_customer_success
  end

  def remove_element_away(customer_success_list, away_customer_success_list)
    return customer_success_list if away_customer_success_list.empty?

    away_customer_success_list.map do |customer|
      customer_success_list.delete_if { |customer_in_list| customer_in_list[:id] == customer }
    end
    customer_success_list
  end

  def shuffle_order_list(list)
    return list if list.length <= 2

    list.shuffle.sort_by { |elements| elements[:score] }
  end

  def verifiy_size_customer_inner_customer_success(list, customer_success, customer_list)
    if list[customer_success].size == customer_list.size || list[customer_success].size >= (customer_list.size / 2) + 1
      customer_success
    end
  end

  # Returns the ID of the customer success with most customers
  def execute
    customer_success_list = shuffle_order_list(remove_element_away(@customer_success, @away_customer_success))
    order_customers = shuffle_order_list(@customers)
    split_customers_grups = Hash.new { |h, k| h[k] = [] }
    customer_success_id = nil
    current_score = 0
    position = 0

    customer_success_list.each do |customer_success|
      next if customer_success[:score] < order_customers[0][:score]

      order_customers.each.with_index(position) do |customer, index|
        if customer[:score] <= customer_success[:score] && customer[:score] > current_score
          split_customers_grups[customer_success[:id]].push(customer)
          position = index
        end
      end
      current_score = customer_success[:score]

      customer_success_id = verifiy_size_customer_inner_customer_success(split_customers_grups, customer_success[:id],
                                                                         order_customers)
      return customer_success_id unless customer_success_id.nil?
    end

    return 0 if split_customers_grups.empty?

    join_customer_and_customer_sucess = split_customers_grups.sort_by { |elements| elements.map(&:size) }.reverse

    if join_customer_and_customer_sucess[0][1].size == join_customer_and_customer_sucess[1][1].size
      0
    else
      join_customer_and_customer_sucess[0][0]
    end
  end
end

class CustomerSuccessBalancingTests < Minitest::Test
  def test_scenario_one
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 20, 95, 75]),
      build_scores([90, 20, 70, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_two
    balancer = CustomerSuccessBalancing.new(
      build_scores([11, 21, 31, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_three
    balancer = CustomerSuccessBalancing.new(
      build_scores(Array(1..999)),
      build_scores(Array.new(10_000, 998)),
      [999]
    )
    result = Timeout.timeout(1.0) { balancer.execute }
    assert_equal 998, result
  end

  def test_scenario_four
    balancer = CustomerSuccessBalancing.new(
      build_scores([1, 2, 3, 4, 5, 6]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_five
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 2, 3, 6, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      []
    )
    assert_equal 1, balancer.execute
  end

  def test_scenario_six
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [1, 3, 2]
    )
    assert_equal 0, balancer.execute
  end

  def test_scenario_seven
    balancer = CustomerSuccessBalancing.new(
      build_scores([100, 99, 88, 3, 4, 5]),
      build_scores([10, 10, 10, 20, 20, 30, 30, 30, 20, 60]),
      [4, 5, 6]
    )
    assert_equal 3, balancer.execute
  end

  def test_scenario_eight
    balancer = CustomerSuccessBalancing.new(
      build_scores([60, 40, 95, 75]),
      build_scores([90, 70, 20, 40, 60, 10]),
      [2, 4]
    )
    assert_equal 1, balancer.execute
  end

  private

  def build_scores(scores)
    scores.map.with_index do |score, index|
      { id: index + 1, score: score }
    end
  end
end
