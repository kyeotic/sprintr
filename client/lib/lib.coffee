

window.app = window.app || {}
lib = {}

lib.okCancelEvents = (selector, callbacks) ->
    ok = callbacks.ok || ->
    cancel = callbacks.cancel || ->
    
    events = {}
    events["keyup #{selector}, keydown #{selector}, focusout #{selector}"] = (evt, tmpl) ->
        if (evt.type == "keydown" && evt.which == 27)
            cancel.call(this,  evt, tmpl)
        else if (evt.type == "keyup" && evt.which == 13 || evt.type == "focusout")
            value = String(evt.target.value || "")
            if value
                ok.call(this, value, evt, tmpl)
            else
                cancel.call(this, evt, tmpl)
    return events

lib.activateInput = (input) ->
    input.focus()
    input.select()
    
Array.prototype.moveUp = (item) -> 
    index = this.indexOf(item)
    if (index == -1 || index == 0) #Isn't in array or is already first
    	return		
    this.remove(item);
    this.splice(index - 1, 0, item)
    return

Array.prototype.moveDown = (item) ->
    index = this.indexOf(item)
    if (index == -1 || index + 1 == this.length) #Isn't in array or is already last
    	return		
    this.remove(item);
    this.splice(index + 1, 0, item)
    return

window.app.lib = lib