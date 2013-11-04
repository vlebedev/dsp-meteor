xmlrpc = Meteor.require 'xmlrpc'

class @BannerStore

    constructor: (options) ->
        {@host, @port, @login, @password} = options
        @logon = ''
        @logonObtainedAt = moment new Date(1970, 6, 2)
        @client = xmlrpc.createSecureClient
            host: @host
            port: @port
            path: '/'

    createLogon: (cb) ->
        time_passed = moment().diff @logonObtainedAt, 'minutes'
        if time_passed >= 3
            @client.methodCall 'BannerStore.CreateLogon',
                [{'name': @login, 'password': @password}],
                (error, result) ->
                    if !!error
                        if !!cb
                            cb error, null
                        return
                    else
                        @logon = result
                        @logonObtainedAt = moment()
                        if !!cb
                            cb null, @logon
                        return
        else
            cb null, @logon
        return

    createCreative: (data, cb) ->

        @createLogon (error, logon) =>
            if !!error
                cb error, null
                return
            else
                @client.methodCall 'BannerStore.CreateCreative',
                    [logon, data], (error, result) ->
                        if !!error
                            cb error, null
                            return
                        else
                            cb null, result
                            return
            return


