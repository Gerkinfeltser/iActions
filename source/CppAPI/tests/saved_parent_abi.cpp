#include <RE/T/TESObjectREFR.h>
#include <REL/Relocation.h>

#include <array>
#include <cstdint>
#include <cstdio>
#include <cstring>

namespace
{
	struct Reference
	{
		std::uintptr_t* vtable;
		RE::TESObjectCELL* parent;
		unsigned setters;
	};

	RE::TESObjectCELL* Getter(const RE::TESObjectREFR* a_self)
	{
		return reinterpret_cast<const Reference*>(a_self)->parent;
	}

	// Keep a getter-shaped trap so a wrong slot never calls a setter with a missing argument.
	RE::TESObjectCELL* SetterTrap(const RE::TESObjectREFR* a_self)
	{
		auto* ref = const_cast<Reference*>(reinterpret_cast<const Reference*>(a_self));
		++ref->setters;
		ref->parent = nullptr;
		return nullptr;
	}
}

int main(int argc, char** argv)
{
	static_assert(sizeof(void*) == 8, "This fixture models the Skyrim x64 engine ABI");

	const bool wrongSlot = argc == 2 && std::strcmp(argv[1], "--wrong-slot") == 0;
	struct RuntimeVersion
	{
		const char* text;
		REL::Version version;
	};
	const std::array versions{
		RuntimeVersion{ "1.5.97.0", REL::Version{ 1, 5, 97, 0 } },
		RuntimeVersion{ "1.6.640.0", REL::Version{ 1, 6, 640, 0 } },
		RuntimeVersion{ "1.6.1170.0", REL::Version{ 1, 6, 1170, 0 } },
		RuntimeVersion{ "1.7.104.0", REL::Version{ 1, 7, 104, 0 } },
		RuntimeVersion{ "1.4.15.0", REL::Version{ 1, 4, 15, 0 } }
	};

	for (const auto& runtime : versions) {
		const auto& version = runtime.version;
		if (!REL::Module::mock(version)) {
			std::printf("FAIL %s mock failed\n", runtime.text);
			return 2;
		}

		const bool vr = REL::Module::IsVR();
		const std::size_t getterSlot = (vr ? 0x98 : 0x97) + (wrongSlot ? 1 : 0);
		std::array<std::uintptr_t, 0x9B> table{};
		table.fill(reinterpret_cast<std::uintptr_t>(&SetterTrap));
		table[getterSlot] = reinterpret_cast<std::uintptr_t>(&Getter);

		std::uintptr_t cellStorage = 0;
		auto* expectedCell = reinterpret_cast<RE::TESObjectCELL*>(&cellStorage);
		Reference ref{ table.data(), expectedCell, 0 };
		const auto* engineRef = reinterpret_cast<const RE::TESObjectREFR*>(&ref);
		const auto* result = engineRef->GetSaveParentCell();
		const bool passed = result == expectedCell && ref.parent == expectedCell && ref.setters == 0;
		std::printf("%s %s getter slot 0x%zX: %s result=%p expected=%p setters=%u parent_unchanged=%d\n",
			passed ? "PASS" : "FAIL", runtime.text, getterSlot,
			passed ? "expected cell, no setter" : "dispatch mismatch", result, expectedCell, ref.setters,
			ref.parent == expectedCell);
		if (!passed) {
			return 1;
		}
	}

}
