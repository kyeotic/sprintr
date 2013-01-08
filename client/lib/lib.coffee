

window.app = window.app || {}
lib = {}

lib.okCancelEvents = (selector, callbacks) ->
    ok = callbacks.ok || ->
    cancel = callbacks.cancel || ->
    
    events = {}
    events["keyup #{selector}, keydown #{selector}, focusout #{selector}"] = (evt) ->
        if (evt.type == "keydown" && evt.which == 27)
            cancel.call(this,  evt)
        else if (evt.type == "keyup" && evt.which == 13 || evt.type == "focusout")
            value = String(evt.target.value || "")
            if value
                ok.call(this, value, evt)
            else
                cancel.call(this, evt)
    return events

lib.activateInput = (input) ->
    input.focus()
    input.select()

window.app.lib = lib