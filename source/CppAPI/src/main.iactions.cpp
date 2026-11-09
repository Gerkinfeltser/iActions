#include "PublicAPI.h"
#include <spdlog/spdlog.h>
#include <spdlog/sinks/basic_file_sink.h>
#include <unordered_set>
#include <set>

static std::shared_ptr<spdlog::logger> g_iaLog;

static void IA_log_init()
{
    if (g_iaLog) return;
    auto logDir = SKSE::log::log_directory();
    if (!logDir) return;
    auto path = logDir->string() + "\\iActions.log";
    g_iaLog = spdlog::basic_logger_mt("iActions", path);
    g_iaLog->set_level(spdlog::level::debug);
    g_iaLog->flush_on(spdlog::level::debug);
    g_iaLog->info("[iActions] log initialized");
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

    if (g_iaLog) g_iaLog->info("[iActions] BuildNpcAlcoholJson: checking '{}' for alcohol, pool has {} entries",
        actor->GetName(), alcoholIDs.size());

    auto invCounts = actor->GetInventoryCounts();
    std::set<std::string> foundNames;

    if (g_iaLog) g_iaLog->info("[iActions] BuildNpcAlcoholJson: actor has {} inventory entries", invCounts.size());

    for (auto& [obj, count] : invCounts) {
        if (!obj || count <= 0) continue;
        uint32_t fid = obj->GetFormID();
        bool match = alcoholIDs.count(fid);
        if (match) {
            const char* rawName = obj->GetName();
            if (rawName && rawName[0] != '\0') {
                foundNames.insert(std::string(rawName));
                if (g_iaLog) g_iaLog->info("[iActions]   MATCH: '{}' (0x{:X}) x{}", rawName, fid, count);
            }
        }
    }

    if (foundNames.empty()) {
        if (g_iaLog) g_iaLog->info("[iActions] BuildNpcAlcoholJson: no alcohol found in '{}' inventory", actor->GetName());
    }

    std::string result = "{\"has\":";
    result += foundNames.empty() ? "false" : "true";
    result += ",\"items\":[";

    bool first = true;
    for (auto& name : foundNames) {
        if (!first) result += ",";
        first = false;
        result += "\"";
        for (char c : name) {
            if (c == '"' || c == '\\') result += '\\';
            result += c;
        }
        result += "\"";
    }

    result += "]}";
    if (g_iaLog) g_iaLog->info("[iActions] BuildNpcAlcoholJson result: {}", result);
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

    if (g_iaLog) g_iaLog->info("[iActions] FormList has {} native + {} script entries",
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
    if (g_iaLog) g_iaLog->info("[iActions] Returning: {}", result);
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
            }
        });
    return true;
}
