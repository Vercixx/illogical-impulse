import QtQuick
import QtQuick.Layouts
import qs.services
import qs.modules.common
import qs.modules.common.widgets

ContentPage {
    forceWidth: true

    ContentSection {
        icon: "neurology"
        title: Translation.tr("AI")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("System prompt")
            text: Config.options.ai.systemPrompt
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Qt.callLater(() => {
                    Config.options.ai.systemPrompt = text;
                });
            }
        }
    }

    ContentSection {
        icon: "weather_mix"
        title: Translation.tr("Weather")
        ConfigRow {
            ConfigSwitch {
                buttonIcon: "assistant_navigation"
                text: Translation.tr("Enable GPS based location")
                checked: Config.options.bar.weather.enableGPS
                onCheckedChanged: {
                    Config.options.bar.weather.enableGPS = checked;
                }
            }
            ConfigSwitch {
                buttonIcon: "thermometer"
                text: Translation.tr("Fahrenheit unit")
                checked: Config.options.bar.weather.useUSCS
                onCheckedChanged: {
                    Config.options.bar.weather.useUSCS = checked;
                }
                StyledToolTip {
                    text: Translation.tr("It may take a few seconds to update")
                }
            }
        }

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("City name")
            text: Config.options.bar.weather.city
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.bar.weather.city = text;
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (m)")
            value: Config.options.bar.weather.fetchInterval
            from: 5
            to: 50
            stepSize: 5
            onValueChanged: {
                Config.options.bar.weather.fetchInterval = value;
            }
        }
    }

    ContentSection {
        icon: "nightlight"
        title: Translation.tr("Night light")

        ConfigSwitch {
            buttonIcon: "schedule"
            text: Translation.tr("Automatic")
            checked: Config.options.light.night.automatic
            onCheckedChanged: {
                Config.options.light.night.automatic = checked;
            }
        }
        ConfigRow {
            uniform: true
            enabled: Config.options.light.night.automatic
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("From (HH:mm)")
                text: Config.options.light.night.from
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.light.night.from = text;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("To (HH:mm)")
                text: Config.options.light.night.to
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.light.night.to = text;
                }
            }
        }
        ConfigSpinBox {
            icon: "thermostat"
            text: Translation.tr("Color temperature (K)")
            value: Config.options.light.night.colorTemperature
            from: 1000
            to: 6500
            stepSize: 100
            onValueChanged: {
                Config.options.light.night.colorTemperature = value;
            }
        }
        ConfigSwitch {
            buttonIcon: "flash_off"
            text: Translation.tr("Anti-flashbang: brightness adjustment")
            checked: Config.options.light.antiFlashbang.enable
            onCheckedChanged: {
                Config.options.light.antiFlashbang.enable = checked;
            }
        }
    }

    ContentSection {
        icon: "translate"
        title: Translation.tr("Translator")

        ConfigRow {
            uniform: true
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Engine")
                text: Config.options.language.translator.engine
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.language.translator.engine = text;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Source language")
                text: Config.options.language.translator.sourceLanguage
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.language.translator.sourceLanguage = text;
                }
            }
            MaterialTextArea {
                Layout.fillWidth: true
                placeholderText: Translation.tr("Target language")
                text: Config.options.language.translator.targetLanguage
                wrapMode: TextEdit.NoWrap
                onTextChanged: {
                    Config.options.language.translator.targetLanguage = text;
                }
            }
        }
    }

    ContentSection {
        icon: "music_note"
        title: Translation.tr("Media")

        ConfigSwitch {
            buttonIcon: "filter_none"
            text: Translation.tr("Hide duplicate players")
            checked: Config.options.media.filterDuplicatePlayers
            onCheckedChanged: {
                Config.options.media.filterDuplicatePlayers = checked;
            }
        }
    }

    ContentSection {
        icon: "music_cast"
        title: Translation.tr("Music Recognition")

        ConfigSpinBox {
            icon: "timer_off"
            text: Translation.tr("Total duration timeout (s)")
            value: Config.options.musicRecognition.timeout
            from: 10
            to: 100
            stepSize: 2
            onValueChanged: {
                Config.options.musicRecognition.timeout = value;
            }
        }
        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (s)")
            value: Config.options.musicRecognition.interval
            from: 2
            to: 10
            stepSize: 1
            onValueChanged: {
                Config.options.musicRecognition.interval = value;
            }
        }
    }

    ContentSection {
        icon: "memory"
        title: Translation.tr("Resources")

        ConfigSpinBox {
            icon: "av_timer"
            text: Translation.tr("Polling interval (ms)")
            value: Config.options.resources.updateInterval
            from: 100
            to: 10000
            stepSize: 100
            onValueChanged: {
                Config.options.resources.updateInterval = value;
            }
        }
        ConfigSpinBox {
            icon: "history"
            text: Translation.tr("History length (points)")
            value: Config.options.resources.historyLength
            from: 10
            to: 600
            stepSize: 10
            onValueChanged: {
                Config.options.resources.historyLength = value;
            }
        }
    }

    ContentSection {
        icon: "cell_tower"
        title: Translation.tr("Networking")

        MaterialTextArea {
            Layout.fillWidth: true
            placeholderText: Translation.tr("User agent (for services that require it)")
            text: Config.options.networking.userAgent
            wrapMode: TextEdit.Wrap
            onTextChanged: {
                Config.options.networking.userAgent = text;
            }
        }
    }
}
