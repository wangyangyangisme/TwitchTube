/*
 * Copyright © 2015 Andrew Penkrat
 *
 * This file is part of TwitchTube.
 *
 * TwitchTube is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * TwitchTube is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with TwitchTube.  If not, see <http://www.gnu.org/licenses/>.
 */

import QtQuick 2.0
import Sailfish.Silica 1.0
import QtMultimedia 5.0
import harbour.twitchtube.ircchat 1.0
import "scripts/httphelper.js" as HTTP
import "scripts/chathelper.js" as CH

Page {
	id: page
	allowedOrientations: Orientation.All

	property var url
	property string channel
	property string username
	property bool followed
	property bool showStream: true
	property bool active: Qt.application.active

	property string authToken: qmlSettings.value("User/OAuth2Token", "", qmlSettings.change)
	property string streamQuality: qmlSettings.value("Video/StreamQuality", "medium", qmlSettings.change)
	property bool chatFlowTtB: parseInt(qmlSettings.value("Interface/ChatFlowTopToBottom", 0, qmlSettings.change))

	states: State {
		name: "fullscreen"
		PropertyChanges {
			target: main
			contentHeight: page.height
		}

		PropertyChanges {
			target: streamMenu
			visible: false
			active: false
		}

		PropertyChanges {
			target: page
			showNavigationIndicator: false; backNavigation: false
			allowedOrientations: Orientation.Landscape | Orientation.LandscapeInverted
		}
	}

	onActiveChanged: {
		if(page.status === PageStatus.Active) {
			console.log("app activeness changed")
			if(active) {
				video.play()
				if(!twitchChat.connected) {
					twitchChat.reopenSocket()
					twitchChat.join(channel)
				}
			}
			else {
				video.pause()
				if(twitchChat.connected)
					twitchChat.disconnect()
			}
		}
	}

	SilicaFlickable {
		id: main
		anchors.fill: parent
		contentHeight: isPortrait ? height : height + Screen.width

		PullDownMenu {
			id: streamMenu
			MenuItem {
				text: qsTr("Follow")
				onClicked: HTTP.putRequest("https://api.twitch.tv/kraken/users/" + username + "/follows/channels/" + channel + "?oauth_token=" + authToken, function(data) {
					if(data)
						followed = true
				})
				visible: authToken && !followed
			}

			MenuItem {
				text: qsTr("Unfollow")
				onClicked: HTTP.deleteRequest("https://api.twitch.tv/kraken/users/" + username + "/follows/channels/" + channel + "?oauth_token=" + authToken, function(data) {
					if(data === 204)
						followed = false
				})
				visible: authToken && followed
			}

			MenuItem {
				text: qsTr("Quality")
				onClicked: {
					var dialog = pageStack.push(Qt.resolvedUrl("QualityChooserPage.qml"), { chatOnly: !showStream })
					dialog.accepted.connect(function() {
						showStream = !dialog.chatOnly
						if(showStream && video.playbackState !== MediaPlayer.PlayingState)
							video.play()
						if(!showStream && video.playbackState !== MediaPlayer.StoppedState)
							video.stop()
					})
				}
			}
		}

		Video {
			id: video
			anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
			height: showStream ? (isPortrait ? screen.width * 9/16 : screen.width) : 0
			source: url[streamQuality]

			onErrorChanged: console.error("video error:", errorString)

			onPlaybackStateChanged: {
				logState()
			}
			onAvailabilityChanged: {
				logAvailability()
			}

			MouseArea {
				anchors.fill: parent
				onClicked: {
					if(page.state == "")
						page.state = "fullscreen"
					else
						page.state = ""

					console.log("video height:", video.height)
					parent.logState()
					parent.logAvailability()
					console.log("video buffer:", video.bufferProgress)
					console.log("video error:", video.errorString)
				}
			}

			function logAvailability() {
				var av
				switch (availability) {
				case MediaPlayer.Available:
					state = "available"
					break
				case MediaPlayer.Busy:
					state = "busy"
					break
				case MediaPlayer.Unavailable:
					state = "unavailable"
					break
				case MediaPlayer.ResourceMissing:
					state = "missing resource"
					break
				}

				console.log("video availability:", av)
			}

			function logState() {
				var state
				switch (playbackState) {
				case MediaPlayer.PlayingState:
					state = "playing"
					break
				case MediaPlayer.PausedState:
					state = "paused"
					break
				case MediaPlayer.StoppedState:
					state = "stopped"
					break
				}

				console.log("video state:", state)
			}
		}

		TextField {
			id: chatMessage
			anchors {	left: parent.left
						right: parent.right
						top: chatFlowTtB ? undefined : video.bottom
						bottom: chatFlowTtB ? parent.bottom : undefined
						margins: Theme.paddingSmall
					}
			placeholderText: qsTr("Chat here")
			label: qsTr("Message to send")
			EnterKey.iconSource: "image://theme/icon-m-enter-accept"
			EnterKey.enabled: text.length > 0 && twitchChat.available
			EnterKey.onClicked: {
				twitchChat.sendMessage(text)
				CH.parseEmoticons(username, text)
				text = ""
			}
		}

		SilicaListView {
			id: chat
			anchors {	left: parent.left
						right: parent.right
						top: chatFlowTtB ? video.bottom : chatMessage.bottom
						bottom: chatFlowTtB ? chatMessage.top : parent.bottom
						margins: Theme.paddingMedium
					}
			clip: true
			verticalLayoutDirection: chatFlowTtB ? ListView.BottomToTop : ListView.TopToBottom
			model: ListModel { id: messages }
			delegate: Item {
				height: lbl.height
				Label {
					id: lbl
					width: chat.width
					text: (nick ? (badges.replace(new RegExp("<img", 'g'), "<img heiht=" + lbl.font.pixelSize + " width=" + lbl.font.pixelSize) +
						  "<font color=" + nick_color + ">" + nick + "</font>: ") : "") +
						  (nick ? "" : ("<font color=" + Theme.highlightColor + ">")) +
						  message.replace(new RegExp("<img", 'g'), "<img heiht=" + lbl.font.pixelSize + " width=" + lbl.font.pixelSize) +
						  (nick ? "" : "</font>")
					textFormat: Text.RichText
					wrapMode: Text.WordWrap

					Component.onCompleted: {
						if(messages.count >= 500) {
							messages.remove(messages.count - 1)
						}
					}
				}
			}

			IrcChat {
				id: twitchChat
				password: 'oauth:' + authToken

				onMessageReceived: {
					CH.parseEmoticons(sndnick, msg)
				}

				onColorReceived: {
					CH.setColor(nick, color)
				}

				onSpecReceived: {
					CH.addSpec(nick, type)
				}

				onSpecRemoved: {
					CH.rmSpec(nick, type)
				}

				onErrorOccured: {
					console.log("Socket error: ", errorDescription)
					reconnect.execute(remorseContainer, qsTr("Chat error, reconnecting"), function() { reopenSocket(); join(channel) })
				}

				Component.onCompleted: {
					if(authToken === "")
						messages.insert(0, { badges: "", nick: "", nick_color: "", message: "You need to login to be able to use chat." })
				}
			}

			Rectangle {
				id: remorseContainer
				anchors.top: parent.top
				width: parent.width
				height: Theme.itemSizeMedium
				color: "transparent"
				RemorseItem { id: reconnect }
			}

			VerticalScrollDecorator { flickable: chat; height: 100 }
		}
	}

	function searchURL(s, q) {
		for (var x in s) {
			if (s[x].substring(0,4) === "http" && s[x].indexOf(q) >= 0)
				return s[x]
		}
	}

	Component.onCompleted: {
		HTTP.getRequest("http://api.twitch.tv/api/channels/" + channel + "/access_token", function (tokendata) {
			if (tokendata) {
				var token = JSON.parse(tokendata)
				HTTP.getRequest(encodeURI("http://usher.twitch.tv/api/channel/hls/" + channel + ".json?allow_source=true&sig=" + token.sig + "&token=" + token.token + "&type=any"), function (data) {
					if (data) {
						var videourls = data.split('\n')
						url = {
							chunked: searchURL(videourls, "chunked"),
							high: searchURL(videourls, "high"),
							medium: searchURL(videourls, "medium"),
							low: searchURL(videourls, "low"),
							mobile: searchURL(videourls, "mobile")
						}
						video.play()
					}
				})
			}
		})

		if(authToken !== "") {
			HTTP.getRequest("https://api.twitch.tv/kraken/user?oauth_token=" + authToken, function(data) {
				var user = JSON.parse(data)
				username = user.name
				twitchChat.name = user.name
				CH.init()

				HTTP.getRequest("https://api.twitch.tv/kraken/users/" + username + "/follows/channels/" + channel, function(data) {
					if(data)
						followed = true
					else
						followed = false
				})
			})
		}
	}
}
