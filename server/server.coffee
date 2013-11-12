fs = Meteor.require 'fs'
path = Meteor.require 'path'
constants = Meteor.require 'constants'
Buffer = Meteor.require('buffer').Buffer

## BannerStore client handler

Store = new BannerStore
    host: process.env.YANDEX_BANNERSTORE_HOST
    port: process.env.YANDEX_BANNERSTORE_PORT
    login: process.env.YANDEX_BANNERSTORE_LOGIN
    password: process.env.YANDEX_BANNERSTORE_PASSWORD

## Dictionaries

BS_Advertisers  = new Meteor.Collection 'bs.advertisers'
BS_Articles     = new Meteor.Collection 'bs.articles'
BS_Brands       = new Meteor.Collection 'bs.brands'
BS_GeoLocs      = new Meteor.Collection 'bs.geolocs'
BS_Sites        = new Meteor.Collection 'bs.sites'

Dictionaries =
    'advertisers':
        coll: BS_Advertisers
        method: 'GetTnsAdvertiser'
    'articles':
        coll: BS_Articles
        method: 'GetTnsArticle'
    'brands':
        coll: BS_Brands
        method: 'GetTnsBrand'
    'geolocs':
        coll: BS_GeoLocs
        method: 'GetGeo'
    'macros':
        coll: BS_Macros
        method: 'GetMacros'
    'sites':
        coll: BS_Sites
        method: 'GetSite'
    'templates':
        coll: BS_Templates
        method: 'GetTemplate'

## GridFS

FilesFS.allow
    insert: ->
        return true

    update: ->
        return true

    remove: ->
        return false

FilesFS.filter
    allow:
        contentTypes: ['image/*']

FilesFSHandler =
  'default1': (options) ->
        # console.log("default 1 options: ", options);
        return {
                blob: options.blob,
                fileRecord: options.fileRecord
        }

FilesFS.fileHandlers FilesFSHandler

Creatives.allow

    update: ->
        return true

    insert: ->
        return true

    remove: ->
        return false

Meteor.publish 'rtbfiles', ->
    return Files.find {}

Meteor.publish 'files', ->
    return FilesFS.find { complete: filter.completed }, { _id: 1, filename: 1, handledAt: 1, metadata: 1 }

Meteor.publish 'bs.templates', ->
    return BS_Templates.find {}

Meteor.publish 'creatives', ->
    return Creatives.find {}

## Helper functions, wrapped in Fibers
######################################

## Sync dict method call

dictMethodCallSync = Meteor._wrapAsync (m, cb) ->
    Store.dictMethodCall m, cb

## Sync method call with logon

methodCallSync = Meteor._wrapAsync (m, d, cb) ->
    Store.methodCall m, d, cb

## Creatives

createCreative = Meteor._wrapAsync (c, cb) ->
    Store.methodCall "CreateCreative", c, cb

getCreative = Meteor._wrapAsync (x, cb) ->
    switch typeof x
        when "number"
            Store.methodCall "GetCreativeByNmb", x, cb
        when "string"
            Store.methodCall "GetCreativeByTag", x, cb
        else
            cb null

getCreativeMacros = Meteor._wrapAsync (nmb, cb) ->
    Store.methodCall "GetCreativeMacros", nmb, cb

## Files

# Upload file from GridFS to Yandex BannerStore
# The file is assumed to be already uploaded from
# client to GridFS
uploadFileToBS = Meteor._wrapAsync (id, cb) ->
    file = FilesFS.findOne(id)

    if file

        while !buffer # very dirty, but who cares?
            buffer = FilesFS.retrieveBuffer(file._id)

        data =
            CdnNmb: 2
            FileName: file.filename
            Bytes: buffer
            Tag: file.metadata.tag

        Store.methodCall 'UploadFile', data, cb
    else
        cb null

# MimeTypeNmb decoder
getContentType = (t) ->
    switch t
        when 1 then 'image/jpeg'
        when 2 then 'image/gif'
        when 3 then 'image/swf'
        when 4 then 'image/png'
        when 5 then 'video/x-flv'
        when 6 then 'audio/x-mp3'
        else 'text/plain'


## Meteor methods

Meteor.methods

    'dictSearch': (dict, query) ->
        num = new RegExp "^\\d+$"

        console.log dict, query

        return [] unless !!Dictionaries[dict]

        if num.test(query)
            res = Dictionaries[dict].coll.findOne({ Nmb: parseInt(query) })
            if res
                return ["#{res.Name} (#{res.Nmb})"]
            else
                return []
        else
            total_found = Dictionaries[dict].coll.find({ Name: { $regex: ".*#{query}.*", $options: 'ui' } }).count()
            if !!total_found
                res = Dictionaries[dict].coll.find({ Name: { $regex: ".*#{query}.*", $options: 'ui' } }, { limit: 10 })?.fetch()
                if res
                    res = _.map(res, (x) -> "#{x.Name} (#{x.Nmb})")
                    if total_found > 10
                        res.push "<i>...и еще <strong>#{total_found-10}</strong> результатов</i>", ""
                    return res
            return []

    'getAdvertiserName': (nmb) ->
        BS_Advertisers.findOne({ Nmb: nmb })?.Name

    # Form support methods

    'newCreative': (id) ->
        c = Creatives.findOne { id }
        nmb = 0

        if c
            nmb = createCreative c
            nc = getCreative nmb
            Creatives._collection.update id, { $set: nc }

        return nmb

    'updateCreative': (nmb) ->
        c = Creatives.findOne { CreativeNmb: nmb }
        u =
            CreativeNmb: c.CreativeNmb
            CreativeName: c.CreativeName
            TnsAdvertiserNmb: c.TnsAdvertiserNmb
            TemplateNmb: c.TemplateNmb
            ExpireDate: c.ExpireDate
            Tag: c.Tag
            Note: c.Note
        Store.methodCall 'UpdateCreative', u
        return

    # Retrieve all CreativeInfo objects from Yandex BannerStore for all creatives
    # in Creatives collection and upsert them into Creatives collection
    'refreshCreatives': ->
        # Scan Creatives collection, get list of CreativeNmb
        creativeNmbs = _.pluck(Creatives.find({}, { fields: { CreativeNmb: 1 } }).fetch(), 'CreativeNmb')

        # For each number retrieve CreativeInfo object from Yandex BannerStore
        # and upsert it into Creatives collection using $set (to keep 'TemplateNmb' property)
        _.each creativeNmbs, (n) ->
            c = getCreative n
            Creatives._collection.upsert { CreativeNmb: c.CreativeNmb }, { $set: c }
        return

    # Retrieve all CreativeInfo objects from Yandex BannerStore by tag
    # and upsert them into Creatives collection
    'refreshCreativesByTag': (tag) ->
        # Retrieve array of CreativeInfo objects from Yandex BannerStore
        cArray = getCreative tag

        # Upsert each CreativeInfo object into Creatives collection
        _.each cArray, (c) ->
            Creatives._collection.upsert { CreativeNmb: c.CreativeNmb }, { $set : c }

        return

    # Upload file to Yandex BannerStore, get its number,
    # retrieve FileInfo object and store it into Files collection
    'uploadToBSAndRefreshFile': (fileId) ->
        fileNmb = uploadFileToBS fileId
        FilesFS.update fileId, { $set: { "metadata.BannerStoreNmb": fileNmb } }
        file = getFileFromBS fileNmb
        delete file.Data # do not store base64 file Data in mongo
        Files._collection.upsert { FileNmb: file.FileNmb }, file

        return

    # Retrieve all FileInfo objects from Yandex BannerStore for all files in GridFS
    # and store them into Files collection
    'refreshFiles': ->

        # Scan GridFS and extract BannerStoreNmb from metadata properties
        fileNmbs = _.map FilesFS.find({}, { fields: { "metadata.FileNmb": 1 } }).fetch(), (f) ->
            if f.metadata?.FileNmb then f.metadata.FileNmb else null
        fileNmbs = _.filter fileNmbs, (n) -> !!n

        # Retrieve FileInfo object for each file number and store it into Files collection
        _.each fileNmbs, (n) ->
            file = methodCallSync 'GetFileByNmb', n
            Files._collection.upsert { FileNmb: file.FileNmb }, file

        return

    'refreshFilesByTag': (tag) ->
        console.log "Refreshing Files from Yandex BannerStore By Tag: #{tag}"

        console.log '  downloading...'
        list = methodCallSync 'GetFileByTag', tag

        console.log '  upserting and storing content into GridFS...'
        _.each list, (file) ->
            Files.upsert { FileNmb: file.FileNmb }, file
            if !FilesFS.find({ "metadata.FileNmb": file.FileNmb }).count()
                FilesFS.storeBuffer file.FileName, file.Data,
                    contentType: getContentType file.MimeTypeNmb
                    noProgress: true
                    metadata:
                        FileNmb: file.FileNmb

        console.log 'Done'

    'getCreativeMacros': (nmb) ->
        m = getCreativeMacros nmb
        console.log m
        return m

    # Absolutely non-multiuser safe. Use with care!!!
    'recreateDictionaries': ->
        console.log 'Recreating Yandex BannerStore Dictionaries'
        for k, v of Dictionaries
            console.log 'Dictionary:', k
            console.log '  erasing...'
            v.coll.remove {}
            v.coll._ensureIndex 'Nmb', { unique: 1, sparse: 1 }
            v.coll._ensureIndex 'Name', { sparse: 1 }
            console.log '  downloading...'
            list = dictMethodCallSync v.method
            console.log '  storing...'
            _.each list, (elem) ->
                v.coll.insert elem
        console.log 'Done'

    # Absolutely non-multiuser safe. Use with care!!!
    'recreateDictionary': (d) ->
        console.log 'Recreating Yandex BannerStore Dictionary'
        v = Dictionaries[d]
        if v
            console.log 'Dictionary:', d
            console.log '  erasing...'
            v.coll.remove {}
            v.coll._ensureIndex 'Nmb', { unique: 1, sparse: 1 }
            v.coll._ensureIndex 'Name', { sparse: 1 }
            console.log '  downloading...'
            list = dictMethodCallSync v.method
            console.log '  storing...'
            _.each list, (elem) ->
                v.coll.insert elem
        console.log 'Done'

    'refreshDictionaries': ->
        console.log 'Refreshing Yandex BannerStore Dictionaries'
        for k, v of Dictionaries
            console.log 'Dictionary:', k
            console.log '  downloading...'
            list = dictMethodCallSync v.method
            console.log '  upserting...'
            _.each list, (elem) ->
                v.coll.upsert { Nmb: elem.Nmb }, elem
        console.log 'Done'

Meteor.startup ->
    AccountsEntry.config
        signupCode: 'freshcocoa153'
