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

#include "tools.h"
#include <QDebug>
#include <QDBusConnection>
#include <QDBusInterface>

/* Return codes:
 * 0 - success
 * 1 - cache doesn't exist
 * -1 - cannot delete cache
 * -2 - failed to find cache directory
 */
int Tools::clearCookies() {
	QStringList dataPaths = QStandardPaths::standardLocations(QStandardPaths::DataLocation);
	if(dataPaths.size()) {
		QDir webData(QDir(dataPaths.at(0)).filePath(".QtWebKit"));
		if(webData.exists()) {
			if(webData.removeRecursively())
				return 0;
			else
				return -1;
		}
		else
			return 1;
	}
	return -2;
}

// true - screen blanks (default)
// false - no blanking
void Tools::setBlankingMode(bool state)
{
    QDBusConnection system = QDBusConnection::connectToBus(QDBusConnection::SystemBus, "system");

    QDBusInterface interface("com.nokia.mce",
							 "/com/nokia/mce/request",
							 "com.nokia.mce.request",
							 system);

	if (state) {
        qDebug() << "Screen blanking turned on";
		interface.call(QLatin1String("req_display_cancel_blanking_pause"));
	} else {
        qDebug() << "Screen blanking turned off";
		interface.call(QLatin1String("req_display_blanking_pause"));
	}
}

Tools::Tools(QObject *parent) :	QObject(parent) { }
Tools::~Tools() { }
