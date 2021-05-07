import consumer from "./consumer"

export const createSubscription = (id) => {
  const actions = {
    received(data) {
      console.log('received', data)
    },
    connected() {
      console.log(`Connected to ${id}`)
    }
  };
  consumer.subscriptions.create( { channel: "UniverseChannel", id: id }, actions );
}

window.subscribeToUniverse = createSubscription;
