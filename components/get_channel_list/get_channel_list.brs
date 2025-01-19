sub init()
	m.top.functionName = "getContent"
end sub

' **********************************************

sub getContent()
	feedurl = m.global.feedurl

	m.port = CreateObject ("roMessagePort")
	searchRequest = CreateObject("roUrlTransfer")
	searchRequest.setURL(feedurl)
	searchRequest.EnableEncodings(true)
	httpsReg = CreateObject("roRegex", "^https:", "")
	if httpsReg.isMatch(feedurl)
		searchRequest.SetCertificatesFile ("common:/certs/ca-bundle.crt")
		searchRequest.InitClientCertificates ()
	end if

	text = searchRequest.getToString()

	reHasGroups = CreateObject("roRegex", "group-title\=" + chr(34) + "?([^" + chr(34) + "]*)"+chr(34)+"?,","")
	reLineSplit = CreateObject("roRegex", "(?>\r\n|[\r\n])", "")
	reExtinf = CreateObject("roRegex", "(?i)^#EXTINF:\s*(\d+|-1|-0).*,\s*(.*)$", "")
	reLogo = CreateObject("roRegex", "tvg-logo=" + chr(34) + "(\w+:(\/?\/?)[^\s]+)" + chr(34), "")
	rePath = CreateObject ("roRegex", "^([^#].*)$", "")

	hasGroups = reHasGroups.isMatch(text)
	inExtinf = false
	icon = ""
	
	con = CreateObject("roSGNode", "ContentNode")

	list = con.CreateChild("ContentNode")
	list.id = "list"
	list_content = list.CreateChild("ContentNode")

	if not hasGroups
		group = list
	end if

	REM #EXTINF:-1 tvg-logo="" group-title="uk",BBC ONE HD
	for each line in reLineSplit.Split (text)

		if inExtinf
			maPath = rePath.Match (line)
			if maPath.Count () = 2
				item = group.CreateChild("ContentNode")
				item.url = maPath [1]
				item.shortdescriptionline1 = title

				item.HDGRIDPOSTERURL = icon

				inExtinf = False
			end if
		end if

		maExtinf = reExtinf.Match (line)

		if maExtinf.Count () = 3
			if hasGroups
				groupName = reHasGroups.Match(line)[1]
				group = invalid
				REM Don't know why, but FindNode refused to work here
				
				'percorre os children do contentnode para verificar se o grupo já existe
				for x = 0 to con.getChildCount()-1 
					node = con.getChild(x)
					if node.id = "group_" + groupName
						group = node
						exit for
					end if
				end for

				'caso o grupo seja inválido, cria um novo
				if group = invalid
					group_item = list_content.CreateChild("ContentNode")
					group_item.title = groupName

					group = con.CreateChild("ContentNode")
					group.id = "group_" + groupName
				end if

			end if

			length = maExtinf[1].ToInt ()
			if length < 0 then length = 0
			title = maExtinf[2]
			inExtinf = True
			if reLogo.isMatch(line)
				icon = reLogo.Match(line)[1]
			end if
		end if
	end for

	m.top.content = con
end sub
