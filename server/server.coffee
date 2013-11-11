fs = Meteor.require 'fs'
path = Meteor.require 'path'
constants = Meteor.require 'constants'
Buffer = Meteor.require('buffer').Buffer

Store = new BannerStore
    host: process.env.YANDEX_BANNERSTORE_HOST
    port: process.env.YANDEX_BANNERSTORE_PORT
    login: process.env.YANDEX_BANNERSTORE_LOGIN
    password: process.env.YANDEX_BANNERSTORE_PASSWORD

Geo = new Meteor.Collection 'geo'
Site = new Meteor.Collection 'site'
Advertiser = new Meteor.Collection 'tnsadvertiser'
TNSArticle = new Meteor.Collection 'tnsarticle'
TNSBrand = new Meteor.Collection 'tnsbrand'

DictColls =
    "geo": Geo
    "site": Site
    "advertiser": Advertiser
    "tnsarticle": TNSArticle
    "tnsbrand": TNSBrand
    "template": RTBTemplate
    "macros": Macros

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

Meteor.publish 'template', ->
    return RTBTemplate.find {}

Meteor.publish 'creatives', ->
    return Creatives.find {}


## Helper functions, wrapped in Fibers
######################################

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

# Get FileInfo object from Yandex BannerStore
getFileFromBS = Meteor._wrapAsync (nmb, cb) ->
    Store.methodCall 'GetFileByNmb', nmb, cb


## Meteor methods

Meteor.methods

    'dictSearch': (dict, query) ->
        num = new RegExp "^\\d+$"

        return [] unless !!DictColls[dict]

        if num.test(query)
            res = DictColls[dict].findOne({ nmb: parseInt(query) })
            if res
                return ["#{res.name} (#{res.nmb})"]
            else
                return []
        else
            total_found = DictColls[dict].find({ name: { $regex: ".*#{query}.*", $options: 'ui' } }).count()
            if !!total_found
                res = DictColls[dict].find({ name: { $regex: ".*#{query}.*", $options: 'ui' } }, { limit: 7 })?.fetch()
                if res
                    res = _.map(res, (x) -> "#{x.name} (#{x.nmb})")
                    if total_found > 7
                        res.push "<i>...и еще <strong>#{total_found-7}</strong> результатов</i>", ""
                    return res
            return []

    'getAdvertiserName': (nmb) ->
        Advertiser.findOne({ nmb: nmb })?.name

    # Form support methods

    'newCreative': (n) ->
        c = Creatives.findOne { CreativeNmb: n }
        nmb = 0

        if c
            delete c.CreativeNmb
            nmb = createCreative c
            nc = getCreative nmb
            Creatives._collection.update { CreativeNmb: n }, { $set: nc }

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
        fileNmbs = _.map FilesFS.find({}, { fields: { "metadata.BannerStoreNmb": 1 } }).fetch(), (f) ->
            if f.metadata?.BannerStoreNmb then f.metadata.BannerStoreNmb else null
        fileNmbs = _.filter fileNmbs, (n) -> !!n

        # Retrieve FileInfo object for each file number and store it into Files collection
        _.each fileNmbs, (n) ->
            file = getFileFromBS n
            Files._collection.upsert { FileNmb: file.FileNmb }, file

        return

    'getCreativeMacros': (nmb) ->
        m = getCreativeMacros nmb
        console.log m
        return m


