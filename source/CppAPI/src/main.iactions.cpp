#include "PublicAPI.h"
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <filesystem>
#include <unordered_set>
#include <set>

static std::shared_ptr<spdlog::logger> g_iaLog;

static void IA_log_init()
{
    if (g_iaLog) return;
    auto logDir = SKSE::log::log_directory();
    if (!logDir) return;
    auto path = logDir->string() + "\\iActions.log";
    // basic_logger_mt throws spdlog_ex when the file cannot be opened or the name is taken. This runs in
    // SKSEPluginLoad, so run without a log instead (every other use checks g_iaLog). Other types propagate.
    try {
        g_iaLog = spdlog::basic_logger_mt("iActions", path);
    } catch (const spdlog::spdlog_ex& e) {
        REX::W32::OutputDebugStringA(("[iActions] log file not opened: "s + e.what() + "\n").c_str());
        return;
    }
    // [Log] Level= in Data/SKSE/Plugins/iActions.ini: trace, debug, info, warn, error or off.
    // Missing file or key -> info. The path is made absolute because GetPrivateProfileString
    // looks up a relative name in the Windows directory, not the game directory.
    std::error_code ec;
    auto ini = std::filesystem::absolute(L"Data/SKSE/Plugins/iActions.ini", ec);
    wchar_t buf[16]{};
    if (!ec) REX::W32::GetPrivateProfileStringW(L"Log", L"Level", L"info", buf, 16, ini.c_str());
    std::string name;
    for (wchar_t c : std::wstring_view(buf)) name += static_cast<char>(c < 128 ? std::tolower(c) : '?');
    if (name.empty()) name = "info";
    auto level = spdlog::level::from_str(name);
    // from_str returns off for anything it does not know.
    bool unknown = level == spdlog::level::off && name != "off";
    if (unknown) level = spdlog::level::info;

    g_iaLog->set_level(level);
    // Someone who asked for debug/trace is reading the file live; otherwise only warnings force a write.
    g_iaLog->flush_on(level < spdlog::level::info ? level : spdlog::level::warn);
    g_iaLog->info("[iActions] log initialized, level {} (set [Log] Level= in Data/SKSE/Plugins/iActions.ini)",
        spdlog::level::to_string_view(level));
    if (unknown) g_iaLog->warn("[iActions] iActions.ini [Log] Level='{}' is not a level; using info", name);
    g_iaLog->flush();
}

static std::unordered_set<uint32_t> GetAlcoholFormIDs() {
    std::unordered_set<uint32_t> ids;
    auto* dataHandler = RE::TESDataHandler::GetSingleton();
    if (!dataHandler) return ids;

    auto* listForm = dataHandler->LookupForm(0x000006, "iActions.esp");
    if (!listForm) return ids;

    auto* alcoholList = listForm->As<RE::BGSListForm>();
    if (!alcoholList) return ids;

    alcoholList->ForEachForm([&](RE::TESForm* entry) {
        if (entry) ids.insert(entry->GetFormID());
        return RE::BSContainer::ForEachResult::kContinue;
    });

    return ids;
}

// Item names are not guaranteed to be UTF-8 (Windows-1252 is common). SkyrimNet passes this decorator's
// result to nlohmann::json::parse, which rejects ill-formed UTF-8, so one such name would lose the whole list.
// ponytail: a name that is not valid UTF-8 is treated as Windows-1252 as a whole; SkyrimNet's own
// ConvertSkyrimTextToUTF8 repairs byte by byte. Switch to that if mixed-encoding names ever show up.
static std::string SkyrimTextToUtf8(const std::string& text) {
    // Own constants: CP_UTF8 and MB_ERR_INVALID_CHARS are macros when <Windows.h> is in the translation unit.
    constexpr std::uint32_t utf8CodePage = 65001;
    constexpr std::uint32_t errInvalidChars = 0x8;
    const auto len = static_cast<std::int32_t>(text.size());
    if (REX::W32::MultiByteToWideChar(utf8CodePage, errInvalidChars, text.data(), len, nullptr, 0) > 0) return text;

    std::wstring wide(text.size(), L' ');  // 1252 is one byte per UTF-16 unit
    const auto wideLen = REX::W32::MultiByteToWideChar(1252, 0, text.data(), len, wide.data(), len);
    if (wideLen <= 0) return {};
    std::string utf8(static_cast<std::size_t>(wideLen) * 3, ' ');
    const auto utf8Len = REX::W32::WideCharToMultiByte(utf8CodePage, 0, wide.data(), wideLen,
        utf8.data(), static_cast<std::int32_t>(utf8.size()), nullptr, nullptr);
    utf8.resize(utf8Len > 0 ? utf8Len : 0);
    return utf8;
}

static std::string BuildNpcAlcoholJson(RE::Actor* actor) {
    if (!actor) {
        if (g_iaLog) g_iaLog->warn("[iActions] BuildNpcAlcoholJson: actor is null");
        return "{\"has\":false,\"items\":[]}";
    }

    auto alcoholIDs = GetAlcoholFormIDs();
    if (alcoholIDs.empty()) {
        if (g_iaLog) g_iaLog->warn("[iActions] BuildNpcAlcoholJson: alcohol FormIDs empty (FormList missing?)");
        return "{\"has\":false,\"items\":[]}";
    }

    if (g_iaLog) g_iaLog->debug("[iActions] BuildNpcAlcoholJson: checking '{}' for alcohol, pool has {} entries",
        actor->GetName(), alcoholIDs.size());

    auto invCounts = actor->GetInventoryCounts();
    std::set<std::string> foundNames;

    if (g_iaLog) g_iaLog->debug("[iActions] BuildNpcAlcoholJson: actor has {} inventory entries", invCounts.size());

    for (auto& [obj, count] : invCounts) {
        if (!obj || count <= 0) continue;
        uint32_t fid = obj->GetFormID();
        bool match = alcoholIDs.count(fid);
        if (!match) {
            // Keyword route (KID): same string as iActions_DrunkCache.psc AlcoholKeywordName.
            if (auto* potion = obj->As<RE::AlchemyItem>()) match = potion->HasKeywordString("iActions_Alcohol");
        }
        if (match) {
            const char* rawName = obj->GetName();
            if (rawName && rawName[0] != '\0') {
                foundNames.insert(std::string(rawName));
                if (g_iaLog) g_iaLog->debug("[iActions]   MATCH: '{}' (0x{:X}) x{}", rawName, fid, count);
            }
        }
    }

    if (foundNames.empty()) {
        if (g_iaLog) g_iaLog->debug("[iActions] BuildNpcAlcoholJson: no alcohol found in '{}' inventory", actor->GetName());
    }

    std::string result = "{\"has\":";
    result += foundNames.empty() ? "false" : "true";
    result += ",\"items\":[";

    bool first = true;
    for (auto& name : foundNames) {
        if (!first) result += ",";
        first = false;
        result += "\"";
        for (unsigned char c : SkyrimTextToUtf8(name)) {
            if (c < 0x20) {  // JSON forbids raw control characters in strings
                char esc[8];
                snprintf(esc, sizeof(esc), "\\u%04x", c);
                result += esc;
                continue;
            }
            if (c == '"' || c == '\\') result += '\\';
            result += static_cast<char>(c);
        }
        result += "\"";
    }

    result += "]}";
    if (g_iaLog) g_iaLog->debug("[iActions] BuildNpcAlcoholJson result: {}", result);
    return result;
}

static std::string BuildAlcoholFormIDsJson() {
    auto* dataHandler = RE::TESDataHandler::GetSingleton();
    if (!dataHandler) {
        if (g_iaLog) g_iaLog->error("[iActions] BuildAlcoholFormIDsJson: dataHandler is null");
        return "{}";
    }

    auto* listForm = dataHandler->LookupForm(0x000006, "iActions.esp");
    if (!listForm) {
        if (g_iaLog) g_iaLog->error("[iActions] BuildAlcoholFormIDsJson: FormList 0x000006 not found");
        return "{}";
    }

    auto* alcoholList = listForm->As<RE::BGSListForm>();
    if (!alcoholList) {
        if (g_iaLog) g_iaLog->error("[iActions] BuildAlcoholFormIDsJson: form is not a BGSListForm");
        return "{}";
    }

    if (g_iaLog) g_iaLog->debug("[iActions] FormList has {} native + {} script entries",
        alcoholList->forms.size(), alcoholList->scriptAddedFormCount);

    std::string result = "{\"formids\": [";
    bool first = true;

    alcoholList->ForEachForm([&](RE::TESForm* entry) {
        if (!entry) return RE::BSContainer::ForEachResult::kContinue;
        if (!first) result += ", ";
        first = false;
        uint32_t fid = entry->GetFormID();
        char buf[20];
        snprintf(buf, sizeof(buf), "\"0x%X\"", fid);
        result += buf;
        return RE::BSContainer::ForEachResult::kContinue;
    });

    result += "]}";
    if (g_iaLog) g_iaLog->debug("[iActions] Returning: {}", result);
    return result;
}

SKSEPluginLoad(const SKSE::LoadInterface* skse) {
    SKSE::Init(skse);
    IA_log_init();

    SKSE::GetMessagingInterface()->RegisterListener(
        [](SKSE::MessagingInterface::Message* msg) {
            if (msg->type == SKSE::MessagingInterface::kDataLoaded) {
                if (!FindFunctions()) {
                    if (g_iaLog) g_iaLog->warn("SkyrimNet not found - iActions decorator not registered");
                    return;
                }
                if (g_iaLog) g_iaLog->info("SkyrimNet API v{}", PublicGetVersion());

                if (!PublicRegisterDecorator) {
                    if (g_iaLog) g_iaLog->error("PublicRegisterDecorator not available (API v5+ required)");
                    return;
                }

                bool ok1 = PublicRegisterDecorator(
                    "iActions_get_alcohol_formids",
                    "Returns base FormIDs of all alcohol items in iActions FormList",
                    [](RE::Actor*) -> std::string {
                        return BuildAlcoholFormIDsJson();
                    });

                if (ok1) {
                    if (g_iaLog) g_iaLog->info("Registered iActions_get_alcohol_formids decorator");
                } else {
                    if (g_iaLog) g_iaLog->error("Failed to register iActions_get_alcohol_formids decorator");
                }

                bool ok2 = PublicRegisterDecorator(
                    "iActions_get_npc_alcohol",
                    "Returns JSON with has:bool and items:[names] of alcohol in NPC inventory",
                    [](RE::Actor* actor) -> std::string {
                        return BuildNpcAlcoholJson(actor);
                    });

                if (ok2) {
                    if (g_iaLog) g_iaLog->info("Registered iActions_get_npc_alcohol decorator");
                } else {
                    if (g_iaLog) g_iaLog->error("Failed to register iActions_get_npc_alcohol decorator");
                }
                if (g_iaLog) g_iaLog->flush();
            }
        });
    return true;
}
