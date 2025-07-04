local EventListener = require("ui/widget/eventlistener")
local Event = require("ui/event")
local ReaderZooming = require("apps/reader/modules/readerzooming")
local UIManager = require("ui/uimanager")

local ReaderKoptListener = EventListener:extend{}

function ReaderKoptListener:setZoomMode(zoom_mode)
    if self.document.configurable.text_wrap == 1 then
        -- in reflow mode only "page" zoom mode is valid so override any other zoom mode
        self.ui:handleEvent(Event:new("SetZoomMode", "page", "koptlistener"))
    else
        self.ui:handleEvent(Event:new("SetZoomMode", zoom_mode, "koptlistener"))
    end
end

function ReaderKoptListener:onReadSettings(config)
    -- normal zoom mode is zoom mode used in non-reflow mode.
    local normal_zoom_mode = config:readSetting("normal_zoom_mode")
                          or ReaderZooming:combo_to_mode(G_reader_settings:readSetting("kopt_zoom_mode_genus"), G_reader_settings:readSetting("kopt_zoom_mode_type"))
    normal_zoom_mode = ReaderZooming.zoom_mode_label[normal_zoom_mode] and normal_zoom_mode or ReaderZooming.DEFAULT_ZOOM_MODE
    self.normal_zoom_mode = normal_zoom_mode
    self:setZoomMode(normal_zoom_mode)
    self.ui:handleEvent(Event:new("GammaUpdate", self.document.configurable.contrast, true)) -- no notification
    self.ui:handleEvent(Event:new("WhiteThresholdUpdate", self.document.configurable.white_threshold, true)) -- no notification
    -- since K2pdfopt v2.21 negative value of word spacing is also used, for config
    -- compatibility we should manually change previous -1 to a more reasonable -0.2
    if self.document.configurable.word_spacing == -1 then
        self.document.configurable.word_spacing = -0.2
    end
    self.ui:handleEvent(Event:new("DitheringUpdate"))
end

function ReaderKoptListener:onSaveSettings()
    self.ui.doc_settings:saveSetting("normal_zoom_mode", self.normal_zoom_mode)
end

function ReaderKoptListener:onRestoreZoomMode()
    -- "RestoreZoomMode" event is sent when reflow mode on/off is toggled
    self:setZoomMode(self.normal_zoom_mode)
    return true
end

function ReaderKoptListener:onSetZoomMode(zoom_mode, orig)
    if orig == "koptlistener" then return end
    -- capture zoom mode set outside of koptlistener which should always be normal zoom mode
    self.normal_zoom_mode = zoom_mode
    self:setZoomMode(self.normal_zoom_mode)
end

function ReaderKoptListener:onFineTuningFontSize(delta)
    self.document.configurable.font_size = self.document.configurable.font_size + delta
end

function ReaderKoptListener:onZoomUpdate(zoom)
    -- an exceptional case is reflow mode
    if self.document.configurable.text_wrap == 1 then
        self.view.state.zoom = 1.0
    end
end

-- misc koptoption handler
function ReaderKoptListener:onDocLangUpdate(lang)
    if lang == "chi_sim" or lang == "chi_tra" or
        lang == "jpn" or lang == "kor" then
        self.document.configurable.word_spacing = G_defaults:readSetting("DKOPTREADER_CONFIG_WORD_SPACINGS")[1]
    else
        self.document.configurable.word_spacing = G_defaults:readSetting("DKOPTREADER_CONFIG_WORD_SPACINGS")[3]
    end
end

function ReaderKoptListener:onConfigChange(option_name, option_value)
    -- font_size and line_spacing are historically and sadly shared by both mupdf and cre reader modules,
    -- but fortunately they can be distinguished by their different ranges
    if (option_name == "font_size" or option_name == "line_spacing") and option_value > 5 then return end
    self.document.configurable[option_name] = option_value
    self.ui:handleEvent(Event:new("StartActivityIndicator"))
    UIManager:setDirty("all", "partial")
    return true
end

return ReaderKoptListener
