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
                        cb && cb error, null
                        return
                    else
                        @logon = result
                        @logonObtainedAt = moment()
                        cb && cb null, @logon
                        return
        else
            cb && cb null, @logon
        return

    methodCall: (method, data, cb) ->
        async.waterfall [
            (callback) =>
                @createLogon callback
            , (logon, callback) =>
                @client.methodCall "BannerStore.#{method}", [logon, data], callback
        ], (err, res) ->
            if err
                console.log 'Error during XML-RPC method invocation:', err
                cb && cb err, null
            else
                cb && cb null, res

    dictMethodCall: (method, cb) ->
        async.waterfall [
            (callback) =>
                @client.methodCall "BannerStore.#{method}", null, callback
        ], (err, res) ->
            if err
                console.log 'Error during XML-RPC method invocation:', err
                cb && cb err, null
            else
                cb && cb null, res
