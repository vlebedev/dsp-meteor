Template.queueControl.events
    'change .fileUploader': (e) ->
        console.log e.target.files
        flist = []
        Session.set 'show_upload', false
        Session.set 'show_spinner', true
        _.each e.target.files, (f) ->
            id = FilesFS.storeFile f, tag: $('.file-tag-js').val()
            Meteor.call 'uploadToBSAndRefreshFile', id
        Session.set 'show_alert_files_uploaded', true
        Session.set 'show_spinner', false
        return
