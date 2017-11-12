#pragma once

#include <QTextEdit>
#include <QVector2D>

#include "Model/Api/Definitions.h"
#include "Model/Api/Descriptions.h"
#include "Gui/Definitions.h"

class CellEditTab
	: public QTextEdit
{
    Q_OBJECT
public:
    CellEditTab(QWidget *parent = nullptr);
	virtual ~CellEditTab() = default;

	void init(DataEditModel* model, DataEditController* controller);
    void updateDisplay ();

protected:
    void keyPressEvent (QKeyEvent* e);
    void mousePressEvent(QMouseEvent* e);
    void mouseDoubleClickEvent (QMouseEvent* e);
    void wheelEvent (QWheelEvent* e);

private:
    void updateModelAndNotifyController ();

    qreal generateNumberFromFormattedString (QString s);
    QString generateFormattedRealString (QString s);
    QString generateFormattedRealString (qreal r);
    QString generateFormattedCellFunctionString (Enums::CellFunction::Type type);

	DataEditModel* _model = nullptr;
	DataEditController* _controller = nullptr;
};

