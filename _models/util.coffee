@GetAdvertiserName = (nmb) ->
    a = Advertisers.findOne { nmb: nmb }
    if !!a
        return a.name
    else
        Meteor.call 'getAdvertiserName', nmb, (error, result) =>
            Advertisers.insert { nmb: nmb, name: result }
    return null