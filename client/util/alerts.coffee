@CoffeeAlerts =

    # Local (client-only) collection
    collection: new Meteor.Collection(null)

    alert: (message, type) ->
        CoffeeAlerts.collection.insert
            message: message
            seen: false
            type: type


    error: (message) ->
        CoffeeAlerts.alert message, 'danger'

    info: (message) ->
        CoffeeAlerts.alert message, 'info'

    warning: (message) ->
        CoffeeAlerts.alert message, 'warning'

    success: (message) ->
        CoffeeAlerts.alert message, 'success'

    clearSeen: ->
        CoffeeAlerts.collection.remove seen: true

Template.coffeeAlerts.helpers alerts: ->
    CoffeeAlerts.collection.find {}

Template.coffeeAlert.rendered = ->
    alert = @data
    Meteor.defer ->
        if CoffeeAlerts.collection.find().count() > 0
            window.scroll(0,0)  # Scroll to top
        CoffeeAlerts.collection.update alert._id,
            $set:
                seen: true