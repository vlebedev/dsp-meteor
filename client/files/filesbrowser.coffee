class @FilesController extends AppController

Template.filesBrowser.files = ->
    Files.find {}, { sort: { FileNmb: -1 } }

Template.filesBrowser.helpers

    show_spinner: ->
        try
            Session.get 'show_spinner'
        catch error
            console.log error

    show_alert_uploaded: ->
        Session.get 'show_alert_files_uploaded'

    show_alert_synced: ->
        try
            Session.get 'show_alert_files_synced'
        catch error
            console.log error

    show_upload:->
        Session.get 'show_upload'

Template.filesBrowser.events

    'click .button-upload-files-js': (e) ->
        Session.set 'show_upload', !Session.get('show_upload')

    'click .button-refresh-files-js': (e) ->
        Session.set 'show_spinner', true
        Session.set 'show_alert_files_uploaded', false
        Session.set 'show_alert_files_synced', false
        Meteor.call 'refreshFiles', (error, result) ->
            Session.set 'show_spinner', false
            Session.set 'show_alert_files_synced', true
            Deps.flush()

    'click .alert-files-uploaded-close-js': (e) ->
        Session.set 'show_alert_files_uploaded', false

    'click .alert-files-synced-close-js': (e) ->
        Session.set 'show_alert_files_synced', false

Template.file.helpers

    MimeType: ->
        switch @MimeTypeNmb
            when 1 then 'image/jpeg'
            when 2 then 'image/gif'
            when 3 then 'image/swf'
            when 4 then 'image/png'
            when 5 then 'video/x-flv'
            when 6 then 'audio/x-mp3'
            else "Unknown (#{@MimeTypeNmb})"

    CdnUrl: ->
        @CdnUrl || "--not approved yet--"

    File: ->
        FilesFS.findOne({ "metadata.FileNmb": @FileNmb })

