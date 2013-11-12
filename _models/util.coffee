@GetAdvertiserName = (nmb) ->
    a = Advertisers.findOne { Nmb: nmb }
    if !!a
        return a.Name
    else
        Meteor.call 'getAdvertiserName', nmb, (error, result) =>
            Advertisers.insert { Nmb: nmb, Name: result }
    return null