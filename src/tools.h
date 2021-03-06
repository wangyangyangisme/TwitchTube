/*
 * Copyright © 2015-2016 Andrew Penkrat
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

#ifndef TOOLS_H
#define TOOLS_H

#include <QObject>
#include <QTimer>

#ifdef OS_SAILFISH
#include <QDBusConnection>
#include <QDBusInterface>

const int PAUSE_PERIOD = 50000; //ms
#endif

class Tools : public QObject
{
    Q_OBJECT
public:
    Tools(QObject *parent = 0);
    ~Tools();

    Q_INVOKABLE int clearCookies();
#ifdef OS_SAILFISH
    Q_INVOKABLE void setBlankingMode(bool state);
#endif
public slots:
#ifdef OS_SAILFISH
    void refreshPause();
#endif
protected:
#ifdef OS_SAILFISH
    QDBusInterface mceReqInterface;
    QTimer* pauseRefresher;
#endif
};

#endif // TOOLS_H
