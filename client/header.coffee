Template.header.username = ->
    return Meteor.user()?.emails?[0].address

