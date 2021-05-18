import consumer from "./consumer"

export const createSubscription = (id) => {
  const actions = {
    received(data) {
      const scope = '[data-cable-broadcast="strategy:' + id + '"]'
      $(scope + '[data-cable-field="pretty_state"]')
      .html(JSON.stringify(data.state, null, 2));

      $(scope + '[data-cable-field="update_date"]')
      .html(new Date)
      .effect('highlight');
    },
  };
  consumer.subscriptions.create( { channel: "StrategyChannel", id: id }, actions );
}

window.subscribeToStrategy = createSubscription;
