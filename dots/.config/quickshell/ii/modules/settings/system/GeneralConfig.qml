import QtQuick
import Quickshell
import Quickshell.Io
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    Process {
        id: translationProc
        property string locale: ""
        command: [Directories.aiTranslationScriptPath, translationProc.locale]
    }

    ContentSection {
        icon: "language"
        title: Translation.tr("Language")

        ContentSubsection {
            title: Translation.tr("Interface Language")
            tooltip: Translation.tr("Select the language for the user interface.\n\"Auto\" will use your system's locale.")

            StyledComboBox {
                id: languageSelector
                buttonIcon: "language"
                textRole: "displayName"

                model: [
                    {
                        displayName: Translation.tr("Auto (System)"),
                        value: "auto"
                    },
                    ...Translation.allAvailableLanguages.map(lang => {
                        return {
                            displayName: lang,
                            value: lang
                        };
                    })]

                currentIndex: {
                    const index = model.findIndex(item => item.value === Config.options.language.ui);
                    return index !== -1 ? index : 0;
                }

                onActivated: index => {
                    Config.options.language.ui = model[index].value;
                }
            }
        }
        ContentSubsection {
            title: Translation.tr("Generate translation with Gemini")
            tooltip: Translation.tr("You'll need to enter your Gemini API key first.\nType /key on the sidebar for instructions.")

            ConfigRow {
                MaterialTextArea {
                    id: localeInput
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Locale code, e.g. fr_FR, de_DE, zh_CN...")
                    text: Config.options.language.ui === "auto" ? Qt.locale().name : Config.options.language.ui
                }
                RippleButtonWithIcon {
                    id: generateTranslationBtn
                    Layout.fillHeight: true
                    nerdIcon: ""
                    enabled: !translationProc.running || (translationProc.locale !== localeInput.text.trim())
                    mainText: enabled ? Translation.tr("Generate\nTypically takes 2 minutes") : Translation.tr("Generating...\nDon't close this window!")
                    onClicked: {
                        translationProc.locale = localeInput.text.trim();
                        translationProc.running = false;
                        translationProc.running = true;
                    }
                }
            }
        }
    }

    ContentSection {
        icon: "nest_clock_farsight_analog"
        title: Translation.tr("Time")

        ConfigSwitch {
            buttonIcon: "pace"
            text: Translation.tr("Second precision")
            checked: Config.options.time.secondPrecision
            onCheckedChanged: {
                Config.options.time.secondPrecision = checked;
            }
            StyledToolTip {
                text: Translation.tr("Enable if you want clocks to show seconds accurately")
            }
        }

        ContentSubsection {
            title: Translation.tr("Format")
            tooltip: ""

            ConfigSelectionArray {
                currentValue: Config.options.time.format
                onSelected: newValue => {
                    if (newValue === "hh:mm") {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME12\\b/TIME/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    } else {
                        Quickshell.execDetached(["bash", "-c", `sed -i 's/\\TIME\\b/TIME12/' '${FileUtils.trimFileProtocol(Directories.config)}/hypr/hyprlock.conf'`]);
                    }

                    Config.options.time.format = newValue;
                }
                options: [
                    {
                        displayName: Translation.tr("24h"),
                        value: "hh:mm"
                    },
                    {
                        displayName: Translation.tr("12h am/pm"),
                        value: "h:mm ap"
                    },
                    {
                        displayName: Translation.tr("12h AM/PM"),
                        value: "h:mm AP"
                    },
                ]
            }
        }

        ContentSubsection {
            title: Translation.tr("Date formats")
            tooltip: Translation.tr("Uses Qt date format, e.g. ddd, dd/MM")
            ConfigRow {
                uniform: true
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Date")
                    text: Config.options.time.dateFormat
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.time.dateFormat = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Short date")
                    text: Config.options.time.shortDateFormat
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.time.shortDateFormat = text;
                    }
                }
                MaterialTextArea {
                    Layout.fillWidth: true
                    placeholderText: Translation.tr("Date with year")
                    text: Config.options.time.dateWithYearFormat
                    wrapMode: TextEdit.NoWrap
                    onTextChanged: {
                        Config.options.time.dateWithYearFormat = text;
                    }
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Calendar locale (e.g. en-GB)")
                text: Config.options.calendar.locale
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.calendar.locale = text;
                }
            }
        }
    }

    ContentSection {
        icon: "av_timer"
        title: Translation.tr("Pomodoro")

        ConfigSpinBox {
            icon: "target"
            text: Translation.tr("Focus (min)")
            value: Config.options.time.pomodoro.focus / 60
            from: 1
            to: 180
            stepSize: 5
            onValueChanged: {
                Config.options.time.pomodoro.focus = value * 60;
            }
        }
        ConfigSpinBox {
            icon: "coffee"
            text: Translation.tr("Break (min)")
            value: Config.options.time.pomodoro.breakTime / 60
            from: 1
            to: 60
            stepSize: 1
            onValueChanged: {
                Config.options.time.pomodoro.breakTime = value * 60;
            }
        }
        ConfigSpinBox {
            icon: "weekend"
            text: Translation.tr("Long break (min)")
            value: Config.options.time.pomodoro.longBreak / 60
            from: 1
            to: 120
            stepSize: 5
            onValueChanged: {
                Config.options.time.pomodoro.longBreak = value * 60;
            }
        }
        ConfigSpinBox {
            icon: "repeat"
            text: Translation.tr("Cycles before long break")
            value: Config.options.time.pomodoro.cyclesBeforeLongBreak
            from: 1
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.time.pomodoro.cyclesBeforeLongBreak = value;
            }
        }
    }
}
