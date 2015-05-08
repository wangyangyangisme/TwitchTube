import QtQuick 2.0
import Sailfish.Silica 1.0
import QtGraphicalEffects 1.0
import org.nemomobile.configuration 1.0
import "elements"
import "scripts/httphelper.js" as HTTP

Page {
	id: page

	property string game
	property string username
	property bool followed
	property bool fromFollowings: false

	ConfigurationValue {
		id: authToken
		key: "/apps/twitch/settings/oauthtoken"
		defaultValue: ""
	}

	ChannelsGrid {
		id: gridChannels

		function loadChannels() {
			var url = "https://api.twitch.tv/kraken/streams?limit=" + countOnPage + "&offset=" + offset + encodeURI("&game=" + game)
			HTTP.getRequest(url,function(data) {
				if (data) {
					offset += countOnPage
					var result = JSON.parse(data)
					totalCount = result._total
					for (var i in result.streams)
						model.append(result.streams[i])
				}
			})
		}

		Categories {
			games: fromFollowings
			following: !fromFollowings && authToken.value !== ""
		}

		header: PageHeader {
			id: header
			title: ((authToken.value !== "") ? "\t\t" : "") + game
			BackgroundItem {
				id: follow
				parent: header.extraContent
				visible: authToken.value !== ""
				anchors.verticalCenter: parent.verticalCenter
				anchors.left: parent.left
				anchors.leftMargin: Theme.paddingLarge
				height: Theme.itemSizeSmall
				width: height

				Image {
					id: heart
					anchors.fill: parent
					source: "../images/heart.png"
					visible: false
				}
				ColorOverlay {
					id: heartEffect1
					anchors.fill: heart
					source: heart
					visible: false
					color: follow.highlighted ? Theme.highlightColor : Theme.primaryColor
				}
				DropShadow {
					id: heartEffect2
					anchors.fill: heartEffect1
					source: heartEffect1
					horizontalOffset: 3
					verticalOffset: 3
					radius: 8.0
					samples: 16
					color: "#80000000"
				}

				Image {
					id: cross
					anchors.fill: parent
					source: "../images/cross.png"
					visible: false
				}
				ColorOverlay {
					id: crossEffect1
					anchors.fill: cross
					source: cross
					visible: false
					color: follow.highlighted ? Theme.highlightColor : Theme.primaryColor
					z: 1
				}
				DropShadow {
					id: crossEffect2
					anchors.fill: crossEffect1
					source: crossEffect1
					horizontalOffset: 3
					verticalOffset: 3
					radius: 8.0
					samples: 16
					color: "#80000000"
					visible: followed
				}

				onClicked: {
					if(!followed)
						HTTP.putRequest("https://api.twitch.tv/api/users/" + username + "/follows/games/" + game + "?oauth_token=" + authToken.value, function(data) {
							if(data)
								followed = true
						})
					else
						HTTP.deleteRequest("https://api.twitch.tv/api/users/" + username + "/follows/games/" + game + "?oauth_token=" + authToken.value, function(data) {
							if(data === 204)
								followed = false
						})
				}
			}
		}
	}

	Component.onCompleted: {
		if(authToken.value !== "") {
			HTTP.getRequest("https://api.twitch.tv/kraken/user?oauth_token=" + authToken.value, function(data) {
				var user = JSON.parse(data)
				username = user.name
				HTTP.getRequest("https://api.twitch.tv/api/users/" + username + "/follows/games/" + game, function(data) {
					if(data)
						followed = true
					else
						followed = false
				})
			})
		}
	}
}
