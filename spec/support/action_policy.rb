RSpec::Matchers.define :permit do |action|
  match do |policy|
    policy.apply(action)
  end

  failure_message do |policy|
    "expected #{policy.class} to permit #{action}"
  end

  failure_message_when_negated do |policy|
    "expected #{policy.class} to forbid #{action}"
  end
end
