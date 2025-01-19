sub init()
    m.top.backgroundURI = "pkg:/images/background-controls.jpg"

    m.save_feed_url = m.top.FindNode("save_feed_url")  'Save url to registry

    m.get_channel_list = m.top.FindNode("get_channel_list") 'get url from registry and parse the feed
    m.get_channel_list.ObserveField("content", "SetContent") 'Is thre content parsed? If so, goto SetContent sub and dsipay list

    m.list_groups = m.top.FindNode("list_groups")
    m.list_groups.ObserveField("itemSelected", "setGroup") 

    m.poster_channels = m.top.FindNode("poster_channels")
    m.poster_channels.ObserveField("itemSelected", "setChannel")

    m.video = m.top.FindNode("Video")
    m.video.ObserveField("state", "checkState")
    m.is_video_fullscreen = false

    m.current_group = m.top.FindNode("current_group")
    m.current_channel_label = m.top.FindNode("current_channel_label")
    m.current_channel_icon = m.top.FindNode("current_channel_icon")

    reg = CreateObject("roRegistrySection", "profile")
    if reg.Exists("primaryfeed") then
        m.get_channel_list.control = "RUN"
        m.top.is_dialog_open = false
    else
        showdialog()  'Force a keyboard dialog.  
    end if

End sub

' **************************************************************

function onKeyEvent(key as String, press as Boolean) as Boolean
    result = false
    
    if(press) '
        if(key = "right")
            m.list_groups.SetFocus(false)
            m.poster_channels.SetFocus(false)
            m.top.SetFocus(true)
            m.top.is_video_fullscreen = true
            m.video.translation = [0, 0]
            m.video.width = 0
            m.video.height = 0
            result = true
        else if(key = "left")
            if m.top.is_video_fullscreen then
                m.top.is_video_fullscreen = false
                setListFocus()
                m.video.translation = [860, 100]
                m.video.width = 960
                m.video.height = 540
            end if
            result = true
        else if(key = "back")
            if m.top.is_video_fullscreen then
                m.top.is_video_fullscreen = false
                setListFocus()
                m.video.translation = [860, 100]
                m.video.width = 960
                m.video.height = 540
            else if m.top.is_group_open then
                m.top.is_group_open = false
                m.current_group.text = "Categorias"
                m.poster_channels.visible = false
                m.list_groups.visible = true
                m.list_groups.SetFocus(true)
            end if
            result = true
        else if(key = "options")
            showdialog()
            result = true
        end if
    end if
    
    return result 
end function


sub checkState()
    state = m.video.state
    if(state = "error")
        m.top.dialog = CreateObject("roSGNode", "Dialog")
        m.top.dialog.title = "Erro: " + str(m.video.errorCode)
        m.top.dialog.message = m.video.errorMsg
    end if
end sub

sub SetContent()    
    m.list_groups.content = m.get_channel_list.content.getChild(0).getChild(0)
    m.list_groups.SetFocus(true)
    print m.get_channel_list.content.getChild(1)
end sub

sub setGroup()

    m.top.is_group_open = true

    m.list_groups.visible = false
    m.poster_channels.content = m.get_channel_list.content.getChild(m.list_groups.itemSelected + 1)
    m.poster_channels.visible = true
    m.poster_channels.SetFocus(true)

    m.current_group.text = m.list_groups.content.getChild(m.list_groups.itemSelected).title

end sub

sub setChannel()
	if m.poster_channels.content.getChild(0).getChild(0) = invalid
		content = m.poster_channels.content.getChild(m.poster_channels.itemSelected)
	else
		itemSelected = m.poster_channels.itemSelected
		for i = 0 to m.poster_channels.currFocusSection - 1
			itemSelected = itemSelected - m.poster_channels.content.getChild(i).getChildCount()
		end for
		content = m.poster_channels.content.getChild(m.poster_channels.currFocusSection).getChild(itemSelected)
	end if

	'Probably would be good to make content = content.clone(true) but for now it works like this
	content.streamFormat = "hls, mp4, mkv, mp3, avi, m4v, ts, mpeg-4, flv, vob, ogg, ogv, webm, mov, wmv, asf, amv, mpg, mp2, mpeg, mpe, mpv, mpeg2, rrc, gifv, mng, qt, yuv, rm, m4p, mxf, nsv"

	if m.video.content <> invalid and m.video.content.url = content.url return

	content.HttpSendClientCertificates = true
	content.HttpCertificatesFile = "common:/certs/ca-bundle.crt"
	m.video.EnableCookies()
	m.video.SetCertificatesFile("common:/certs/ca-bundle.crt")
	m.video.InitClientCertificates()

    m.video.content = content
    m.current_channel_icon.uri   = content.HDGRIDPOSTERURL
    m.current_channel_label.text = content.shortdescriptionline1

	m.top.backgroundURI = "pkg:/images/rsgde_bg_hd.jpg"
	m.video.trickplaybarvisibilityauto = true

	m.video.control = "play"
end sub


sub showdialog()
    PRINT ">>>  ENTERING KEYBOARD <<<"

    keyboarddialog = createObject("roSGNode", "KeyboardDialog")
    keyboarddialog.backgroundUri = "pkg:/images/rsgde_bg_hd.jpg"
    keyboarddialog.title = "Digite a URL da lista de canais"

    keyboarddialog.buttons=["OK","Fechar"]
    keyboarddialog.optionsDialog=true

    m.top.dialog = keyboarddialog
    m.top.dialog.text = m.global.feedurl
    m.top.dialog.keyboard.textEditBox.cursorPosition = len(m.global.feedurl)
    m.top.dialog.keyboard.textEditBox.maxTextLength = 300
    m.top.dialog.focusButton = 0

    m.top.is_dialog_open = true

    KeyboardDialog.observeFieldScoped("buttonSelected","onKeyPress")  'we observe button ok/cancel, if so goto to onKeyPress sub
end sub


sub onKeyPress()
    if m.top.dialog.buttonSelected = 0 ' OK
        m.global.feedurl = m.top.dialog.text
        m.save_feed_url.control = "RUN"
        m.get_channel_list.control = "RUN"
        m.top.dialog.close = true
    else if m.top.dialog.buttonSelected = 1 ' Fechar
        m.top.dialog.close = true
    end if
end sub

sub setListFocus()
    if m.top.is_group_open then
        m.poster_channels.SetFocus(true)
    else
        m.list_groups.SetFocus(true)
    end if
end sub