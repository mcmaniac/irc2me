#pragma once

#include <QMainWindow>

#include "irc2me.h"

namespace Ui {
class ProtobufTest;
}

class ProtobufTest : public QMainWindow
{
    Q_OBJECT

private:

    Ui::ProtobufTest *ui;
    Irc2me &irc2me;

    void log(QString msg);
    void lockServerInput(bool read_only);

public:

    explicit ProtobufTest(Irc2me &irc, QWidget *parent = 0);
    ~ProtobufTest();

private slots:

    void irc2me_connected();
    void irc2me_disconnected();
    void irc2me_error(QAbstractSocket::SocketError, QString msg);

    void irc2me_authorized();
    void irc2me_notAuthorized();

    void on_pushButton_connect_clicked();

};
