// An Apollo Link for using graphql-pro's Ably subscriptions
//
// @example Adding subscriptions to a HttpLink
//   // Load Pusher and create a client
//   var Ably = require('ably')
//   // Be sure to create an API key with "Subscribe" and "Presence" permissions only,
//   // and use that limited API key here:
//   var ablyClient = new Ably.Realtime("yourapp.key:secret")
//
//   // Build a combined link, initialize the client:
//   const ablyLink = new AblyLink({ably: ablyClient})
//   const link = ApolloLink.from([authLink, ablyLink, httpLink])
//   const client = new ApolloClient(link: link, ...)
//
// @example Building a subscription, then subscribing to it
//  subscription = client.subscribe({
//    variables: { room: roomName},
//    query: gql`
//      subscription MessageAdded($room: String!) {
//        messageWasAdded(room: $room) {
//          room {
//            messages {
//              id
//              body
//              author {
//                screenname
//              }
//            }
//          }
//        }
//      }
//       `
//   })
//
//   subscription.subscribe({ next: ({data, errors}) => {
//     // Do something with `data` and/or `errors`
//   }})
//
var ApolloLink = require("apollo-link").ApolloLink
var Observable = require("apollo-link").Observable

class AblyLink extends ApolloLink {
  constructor(options) {
    super()
    // Retain a handle to the Ably client
    this.ably = options.ably
  }

  request(operation, forward) {
    return new Observable((observer) => {
      // Check the result of the operation
      forward(operation).subscribe({ next: (data) => {
        // If the operation has the subscription header, it's a subscription
        const subscriptionChannel = this._getSubscriptionChannel(operation)
        if (subscriptionChannel) {
          // This will keep pushing to `.next`
          this._createSubscription(subscriptionChannel, observer)
        }
        else {
          // This isn't a subscription,
          // So pass the data along and close the observer.
          observer.next(data)
          observer.complete()
        }
      }})
    })
  }

  _getSubscriptionChannel(operation) {
    const response = operation.getContext().response
    // Check to see if the response has the header
    const subscriptionChannel = response.headers.get("X-Subscription-ID")
    return subscriptionChannel
  }

  _createSubscription(subscriptionChannel, observer) {
    const ablyChannel = this.ably.channels.get(subscriptionChannel)
    // Register presence, so that we can detect empty channels and clean them up server-side
    ablyChannel.presence.enterClient("graphql-subscriber", "subscribed")
    // Subscribe for more update
    ablyChannel.subscribe("update", function(message) {
      var payload = message.data
      if (!payload.more) {
        // This is the end, the server says to unsubscribe
        ablyChannel.presence.leaveClient()
        ablyChannel.unsubscribe()
        observer.complete()
      }
      const result = payload.result
      if (result) {
        // Send the new response to listeners
        observer.next(result)
      }
    })
  }
}

module.exports = AblyLink
